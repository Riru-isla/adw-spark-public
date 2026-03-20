require "open3"

module Spark
  module Actors
    class BootstrapRepo < Actor
      include Spark::Actors::PipelineInputs

      input :app_spec
      input :stories
      output :project_dir
      output :project_tracker

      def call
        log_actor("Bootstrapping repository")
        update_phase("bootstrapping")

        target_dir = File.join(Spark.projects_dir, project_slug)

        tracker_files = %w[logs runs project.yaml spec.yaml stories.yaml plans]
        if Dir.exist?(target_dir) && Dir.children(target_dir).any? { |f| !tracker_files.include?(f) }
          log_actor("Project directory already exists, skipping scaffold")
          self.project_dir = target_dir
          return
        end

        FileUtils.mkdir_p(target_dir)

        request = Spark::AgentRequest.new(
          agent_name: "bootstrapper",
          slash_command: "/spark:bootstrap",
          args: [JSON.generate(app_spec.to_h)],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: target_dir,
          dangerously_skip_permissions: true
        )

        response = Spark::Agent.execute_template(request)

        fail!(error: "Failed to bootstrap repo: #{response.output}") unless response.success

        self.project_dir = target_dir

        # Remove nested .git dirs created by scaffolders (rails new, vue create)
        # so the project root is the single git repo
        Dir.glob(File.join(target_dir, "**", ".git")).each do |nested_git|
          next if nested_git == File.join(target_dir, ".git")

          FileUtils.rm_rf(nested_git)
          log_actor("Removed nested .git: #{nested_git}")
        end

        # Git operations: init, commit, set remote, push
        git_init(target_dir)
        git_commit(target_dir, "chore: initial project scaffold")
        push_to_remote(target_dir)

        tracker = Spark::Tracker::Project.load(project_slug) || {}
        tracker[:status] = "bootstrapped"
        tracker[:project_dir] = target_dir
        Spark::Tracker::Project.save(project_slug, tracker)
        self.project_tracker = tracker

        log_actor("Repository bootstrapped at #{target_dir}")
      end

      private

      # Prevent git from inheriting the parent adw-spark repo
      def git_env(dir)
        { "GIT_CEILING_DIRECTORIES" => File.dirname(dir) }
      end

      def git_init(dir)
        _, stderr, status = Open3.capture3(git_env(dir), "git", "init", chdir: dir)
        if status.success?
          log_actor("Git repo initialized")
        else
          log_actor("Warning: git init failed: #{stderr}")
        end
      end

      def git_commit(dir, message)
        env = git_env(dir)
        Open3.capture3(env, "git", "add", "-A", chdir: dir)
        _, _, check = Open3.capture3(env, "git", "diff", "--cached", "--quiet", chdir: dir)
        if check.success?
          log_actor("No changes to commit")
          return
        end
        _, stderr, status = Open3.capture3(env, "git", "commit", "-m", message, chdir: dir)
        if status.success?
          log_actor("Committed: #{message}")
        else
          log_actor("Warning: git commit failed: #{stderr}")
        end
      end

      def push_to_remote(dir)
        tracker = Spark::Tracker::Project.load(project_slug) || {}
        repo_url = tracker[:repo_url]
        return unless repo_url

        env = git_env(dir)

        # Add remote if not present (use SSH format for auth)
        _, _, status = Open3.capture3(env, "git", "remote", "get-url", "origin", chdir: dir)
        unless status.success?
          ssh_url = repo_url
                    .sub("https://github.com/", "git@github.com:")
                    .then { |u| u.end_with?(".git") ? u : "#{u}.git" }
          Open3.capture3(env, "git", "remote", "add", "origin", ssh_url, chdir: dir)
          log_actor("Remote set to #{ssh_url}")
        end

        # Push
        _, stderr, status = Open3.capture3(env, "git", "push", "-u", "origin", "main", chdir: dir)
        if status.success?
          log_actor("Pushed bootstrap to remote")
        else
          # Try with master branch name
          _, stderr, status = Open3.capture3(env, "git", "push", "-u", "origin", "master", chdir: dir)
          if status.success?
            log_actor("Pushed bootstrap to remote (master)")
          else
            log_actor("Warning: push failed: #{stderr}")
          end
        end
      end
    end
  end
end
