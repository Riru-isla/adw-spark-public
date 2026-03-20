require "open3"

module Spark
  module Actors
    class CondenseContext < Actor
      include Spark::Actors::PipelineInputs

      output :context_path

      def call
        log_actor("Condensing project context")

        dir = project_dir || File.join(Spark.projects_dir, project_slug)
        context_dir = File.join(dir, ".claude", "context")

        unless Dir.exist?(context_dir) && Dir.glob(File.join(context_dir, "story-*.md")).any?
          log_actor("No story context files found, skipping condense")
          return
        end

        request = Spark::AgentRequest.new(
          agent_name: "context_condenser",
          slash_command: "/spark:condense_context",
          args: [context_dir],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: dir
        )

        response = Spark::Agent.execute_template(request)

        if response.success
          output_file = File.join(context_dir, "project.md")
          File.write(output_file, response.output.strip)
          self.context_path = output_file
          log_actor("Condensed context saved to #{output_file}")

          # Commit and push the condensed context
          commit_and_push(dir)
        else
          log_actor("Warning: Failed to condense context, individual story contexts remain available")
        end
      end

      private

      # Prevent git from inheriting the parent adw-spark repo
      def git_env(dir)
        { "GIT_CEILING_DIRECTORIES" => File.dirname(dir) }
      end

      def commit_and_push(dir)
        env = git_env(dir)
        Open3.capture3(env, "git", "add", "-A", chdir: dir)

        _, _, check = Open3.capture3(env, "git", "diff", "--cached", "--quiet", chdir: dir)
        return if check.success?

        _, stderr, status = Open3.capture3(env, "git", "commit", "-m", "chore: condense project context", chdir: dir)
        if status.success?
          log_actor("Committed condensed context")
          _, stderr, status = Open3.capture3(env, "git", "push", chdir: dir)
          if status.success?
            log_actor("Pushed condensed context to remote")
          else
            log_actor("Warning: push failed: #{stderr}")
          end
        else
          log_actor("Warning: commit failed: #{stderr}")
        end
      end
    end
  end
end
