module Spark
  module Actors
    class InitializeProject < Actor
      include Spark::Actors::PipelineInputs

      input :raw_message, type: String, default: -> { nil }
      output :project_tracker
      output :run_tracker

      def call
        log_actor("Initializing project: #{project_slug}")

        # Create or load project tracker
        self.project_tracker = Spark::Tracker::Project.load(project_slug)

        unless project_tracker
          self.project_tracker = Spark::Tracker::Project.create(
            project_slug: project_slug,
            raw_message: raw_message || "",
            stack: Spark.default_stack,
            mode: mode
          )
        end

        # Create run tracker
        self.run_tracker = Spark::Tracker::Run.create(
          run_id: run_id,
          mode: mode,
          trigger: "message"
        )
        Spark::Tracker::Run.save(project_slug, run_id, run_tracker)

        # Register run in project tracker
        project_tracker[:runs] ||= []
        project_tracker[:runs] << { run_id: run_id, mode: mode, started_at: Time.now.iso8601 }
        Spark::Tracker::Project.save(project_slug, project_tracker)

        log_actor("Run #{run_id} initialized (mode: #{mode})")
      end
    end
  end
end
