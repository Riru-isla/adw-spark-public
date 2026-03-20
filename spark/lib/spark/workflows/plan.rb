# Mode: plan — Spec + stories + repo + GitHub issues (ready to build)
module Spark
  module Workflows
    class Plan < Actor
      input :raw_message, type: String
      input :project_slug, type: String, default: -> { "pending" }
      input :run_id, type: String
      input :logger
      input :mode, default: -> { "plan" }

      def call
        # Run sketch first
        sketch = Spark::Workflows::Sketch.result(
          raw_message: raw_message,
          project_slug: project_slug,
          run_id: run_id,
          logger: logger,
          mode: mode
        )
        return fail!(error: sketch.error) unless sketch.success?

        # Load what sketch produced
        slug = resolve_slug
        tracker = Spark::Tracker::Project.load(slug)
        spec = load_spec(tracker[:spec_path])
        stories = load_stories(tracker[:stories_path])

        # Create GitHub repo
        repo = Spark::Actors::CreateGithubRepo.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          app_spec: spec
        )
        return fail!(error: repo.error) unless repo.success?

        # Bootstrap the project scaffold
        bootstrap = Spark::Actors::BootstrapRepo.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          app_spec: spec,
          stories: stories
        )
        return fail!(error: bootstrap.error) unless bootstrap.success?

        # Create GitHub issues
        issues = Spark::Actors::CreateGithubIssues.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          stories: stories,
          repo_name: repo.repo_name
        )
        return fail!(error: issues.error) unless issues.success?

        Spark::Tracker.update_status(slug, run_id, "plan_complete", logger)
        logger.info("Plan complete: repo created, #{issues.issue_numbers.length} issues filed")
      end

      private

      def resolve_slug
        # Find the project that was created by this run (skip "pending")
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
    end
  end
end
