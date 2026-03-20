# Mode: ship — Full cycle including deploy
module Spark
  module Workflows
    class Ship < Actor
      input :raw_message, type: String
      input :project_slug, type: String, default: -> { "pending" }
      input :run_id, type: String
      input :logger
      input :mode, default: -> { "ship" }

      def call
        # Run build first
        build = Spark::Workflows::Build.result(
          raw_message: raw_message,
          project_slug: project_slug,
          run_id: run_id,
          logger: logger,
          mode: mode
        )
        return fail!(error: build.error) unless build.success?

        slug = resolve_slug
        tracker = Spark::Tracker::Project.load(slug)
        spec = load_spec(tracker[:spec_path])

        # Deploy
        deploy = Spark::Actors::Deploy.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: mode,
          app_spec: spec,
          project_dir: tracker[:project_dir]
        )

        if deploy.success? && deploy.deploy_url
          logger.info("Application shipped and available at: #{deploy.deploy_url}")
        else
          logger.warn("Deploy phase completed with issues — app may need manual deployment")
        end

        Spark::Tracker.update_status(slug, run_id, "shipped", logger)
        logger.info("Ship complete for '#{spec.name}'")
      end

      private

      def resolve_slug
        match = Dir.glob(File.join(Spark.projects_dir, "*", "runs", "#{run_id}.yaml")).first
        match ? match.split("/")[-3] : project_slug
      end

      def load_spec(path)
        data = YAML.safe_load(File.read(path), symbolize_names: true)
        Spark::AppSpec.new(data)
      end
    end
  end
end
