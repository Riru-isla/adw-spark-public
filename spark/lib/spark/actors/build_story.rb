require "open3"

module Spark
  module Actors
    class BuildStory < Actor
      include Spark::Actors::PipelineInputs

      input :story
      input :story_index, type: Integer
      input :total_stories, type: Integer
      output :run_tracker

      def call
        log_actor("Building story #{story_index + 1}/#{total_stories}: #{story.title}")
        update_phase("building_story_#{story_index + 1}")

        # Plan — agent reads the codebase directly via cwd
        plan_path = plan_story
        return if plan_path.nil?

        # Implement — agent reads the codebase directly via cwd
        # (the implementer runs story-scoped tests as part of its workflow)
        implement_story(plan_path)

        # Generate context for this story
        generate_story_context

        # Commit all changes for this story
        commit_story

        # Mark complete
        run = Spark::Tracker::Run.load(project_slug, run_id) || {}
        run[:completed_stories] ||= []
        run[:completed_stories] << story.number
        Spark::Tracker::Run.save(project_slug, run_id, run)
        self.run_tracker = run

        log_actor("Story #{story.number} complete")
      end

      private

      def plan_story
        args = [JSON.generate(story.to_h)]

        request = Spark::AgentRequest.new(
          agent_name: "planner_story_#{story.number}",
          slash_command: "/spark:plan_story",
          args: args,
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_PLANNER_MODEL", "sonnet"),
          cwd: project_dir
        )

        response = Spark::Agent.execute_template(request)

        fail!(error: "Failed to plan story #{story.number}: #{response.output}") unless response.success

        # Save plan to a file and return the path
        plan_dir = File.join(project_dir || File.join(Spark.projects_dir, project_slug), "plans")
        FileUtils.mkdir_p(plan_dir)
        plan_file = File.join(plan_dir, "story-#{story.number}.md")
        File.write(plan_file, response.output.strip)
        plan_file
      end

      def implement_story(plan_path)
        plan_content = File.read(plan_path)

        request = Spark::AgentRequest.new(
          agent_name: "implementer_story_#{story.number}",
          slash_command: "/spark:implement",
          args: [plan_content],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir,
          dangerously_skip_permissions: true
        )

        response = Spark::Agent.execute_template(request)

        return if response.success

        fail!(error: "Failed to implement story #{story.number}: #{response.output}")
      end

      def test_story
        request = Spark::AgentRequest.new(
          agent_name: "tester_story_#{story.number}",
          slash_command: "/spark:test",
          args: [],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir,
          dangerously_skip_permissions: true
        )

        response = Spark::Agent.execute_template(request)

        return if response.success

        log_actor("Tests failed for story #{story.number}, attempting resolution")
        resolve_tests(response.output)
      end

      def resolve_tests(test_output)
        request = Spark::AgentRequest.new(
          agent_name: "resolver_story_#{story.number}",
          slash_command: "/spark:resolve_test",
          args: [test_output],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir
        )

        Spark::Agent.execute_template(request)
      end

      # Prevent git from inheriting the parent adw-spark repo
      def git_env(dir)
        { "GIT_CEILING_DIRECTORIES" => File.dirname(dir) }
      end

      def commit_story
        dir = project_dir || File.join(Spark.projects_dir, project_slug)
        env = git_env(dir)

        # Stage all changes
        _, stderr, status = Open3.capture3(env, "git", "add", "-A", chdir: dir)
        unless status.success?
          # Likely nested .git dirs — remove them and retry
          if stderr.include?("does not have a commit checked out")
            log_actor("Detected nested .git dirs, removing and retrying")
            Dir.glob(File.join(dir, "**", ".git")).each do |nested|
              next if nested == File.join(dir, ".git")

              FileUtils.rm_rf(nested)
            end
            _, stderr, status = Open3.capture3(env, "git", "add", "-A", chdir: dir)
            unless status.success?
              log_actor("Warning: git add still failed after cleanup: #{stderr}")
              return
            end
          else
            log_actor("Warning: git add failed: #{stderr}")
            return
          end
        end

        # Check if there's anything to commit
        _, _, check = Open3.capture3(env, "git", "diff", "--cached", "--quiet", chdir: dir)
        if check.success?
          log_actor("No changes to commit for story #{story.number}")
          return
        end

        # Determine commit type from story type
        type = case story.type
               when "feature" then "feat"
               when "chore" then "chore"
               when "bug" then "fix"
               else "feat"
               end

        message = "#{type}(story-#{story.number}): #{story.title}"

        _, stderr, status = Open3.capture3(env, "git", "commit", "-m", message, chdir: dir)
        if status.success?
          log_actor("Committed: #{message}")
          push_to_remote(dir)
        else
          log_actor("Warning: git commit failed: #{stderr}")
        end
      end

      def push_to_remote(dir)
        _, stderr, status = Open3.capture3(git_env(dir), "git", "push", chdir: dir)
        if status.success?
          log_actor("Pushed story #{story.number} to remote")
        else
          log_actor("Warning: push failed: #{stderr}")
        end
      end

      def generate_story_context
        log_actor("Generating context for story #{story.number}")

        context_dir = File.join(project_dir || File.join(Spark.projects_dir, project_slug), ".claude", "context")
        FileUtils.mkdir_p(context_dir)

        input = JSON.generate(story.to_h)

        request = Spark::AgentRequest.new(
          agent_name: "context_story_#{story.number}",
          slash_command: "/spark:generate_context",
          args: [input],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir
        )

        response = Spark::Agent.execute_template(request)

        if response.success
          context_file = File.join(context_dir, "story-#{story.number}.md")
          File.write(context_file, response.output.strip)
          log_actor("Context saved to #{context_file}")
        else
          log_actor("Warning: Failed to generate context for story #{story.number}, continuing")
        end
      end
    end
  end
end
