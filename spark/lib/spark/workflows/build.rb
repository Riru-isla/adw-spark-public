# Mode: build — Full implementation (plan + implement all stories + test + review)
require "open3"

module Spark
  module Workflows
    class Build < Actor
      input :raw_message, type: String
      input :project_slug, type: String, default: -> { "pending" }
      input :run_id, type: String
      input :logger
      input :mode, default: -> { "build" }

      def call
        # Run plan first
        plan = Spark::Workflows::Plan.result(
          raw_message: raw_message,
          project_slug: project_slug,
          run_id: run_id,
          logger: logger,
          mode: mode
        )
        return fail!(error: plan.error) unless plan.success?

        slug = resolve_slug
        tracker = Spark::Tracker::Project.load(slug)
        spec = load_spec(tracker[:spec_path])
        stories = load_stories(tracker[:stories_path])
        project_dir = tracker[:project_dir]

        # Build all stories in dependency order
        build = Spark::Actors::BuildLoop.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          stories: stories,
          project_dir: project_dir
        )

        unless build.success?
          logger.warn("Build loop had failures: #{build.error}")
          # Continue — partial builds are still useful
        end

        # Safety net: if per-story commits failed, do a bulk commit now
        ensure_committed(project_dir, slug)

        # Run full test suite after all stories are implemented
        Spark::Actors::RunTests.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          project_dir: project_dir
        )

        # Condense all per-story context files into a unified project context
        Spark::Actors::CondenseContext.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          project_dir: project_dir
        )

        # Smoke test the assembled app
        Spark::Actors::SmokeTest.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          app_spec: spec,
          project_dir: project_dir
        )

        Spark::Tracker.update_status(slug, run_id, "build_complete", logger)
        logger.info("Build complete for '#{spec.name}'")
      end

      private

      def resolve_slug
        match = Dir.glob(File.join(Spark.projects_dir, "*", "runs", "#{run_id}.yaml"))
                   .map { |path| path.split("/")[-3] }
                   .find { |slug| slug != "pending" }
        match || project_slug
      end

      def load_spec(path)
        data = YAML.safe_load(File.read(path), symbolize_names: true)
        Spark::AppSpec.new(data)
      end

      def load_stories(path)
        data = YAML.safe_load(File.read(path), symbolize_names: true)
        data.map { |s| Spark::Story.new(s) }
      end

      def ensure_committed(project_dir, slug)
        return unless project_dir && Dir.exist?(project_dir)

        env = { "GIT_CEILING_DIRECTORIES" => File.dirname(project_dir) }

        # Check if there are uncommitted changes
        Open3.capture3(env, "git", "status", "--porcelain", chdir: project_dir)
        stdout, = Open3.capture3(env, "git", "status", "--porcelain", chdir: project_dir)
        return if stdout.strip.empty?

        logger.info("[Build] Uncommitted changes detected — running fallback commit")

        # Remove any nested .git dirs that might block
        Dir.glob(File.join(project_dir, "**", ".git")).each do |nested|
          next if nested == File.join(project_dir, ".git")

          FileUtils.rm_rf(nested)
          logger.info("[Build] Removed nested .git: #{nested}")
        end

        # Ensure git repo exists
        Open3.capture3(env, "git", "init", chdir: project_dir) unless Dir.exist?(File.join(project_dir, ".git"))

        Open3.capture3(env, "git", "add", "-A", chdir: project_dir)
        _, stderr, status = Open3.capture3(env, "git", "commit", "-m", "feat: implement all stories", chdir: project_dir)
        if status.success?
          logger.info("[Build] Fallback commit succeeded")
          # Try to push
          tracker = Spark::Tracker::Project.load(slug) || {}
          if tracker[:repo_url]
            ssh_url = tracker[:repo_url]
                      .sub("https://github.com/", "git@github.com:")
                      .then { |u| u.end_with?(".git") ? u : "#{u}.git" }
            begin
              Open3.capture3(env, "git", "remote", "add", "origin", ssh_url, chdir: project_dir)
            rescue StandardError
              nil
            end
            _, _, push_status = Open3.capture3(env, "git", "push", "-u", "origin", "main", chdir: project_dir)
            logger.info("[Build] Fallback push #{push_status.success? ? 'succeeded' : 'failed'}")
          end
        else
          logger.warn("[Build] Fallback commit failed: #{stderr}")
        end
      end
    end
  end
end
