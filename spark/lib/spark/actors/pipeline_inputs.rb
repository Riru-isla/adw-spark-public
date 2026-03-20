module Spark
  module Actors
    module PipelineInputs
      def self.included(base)
        base.input :project_slug, type: String
        base.input :run_id, type: String
        base.input :logger
        base.input :mode, default: -> { Spark.default_mode }
        base.input :project_tracker, default: -> { nil }
        base.input :run_tracker, default: -> { nil }
        base.input :project_dir, default: -> { nil }
      end

      def log_actor(msg)
        logger.info("[#{self.class.name.split('::').last}] #{msg}")
      end

      def update_phase(phase)
        Spark::Tracker.update_phase(project_slug, run_id, phase, logger)
      end

      def update_status(status)
        Spark::Tracker.update_status(project_slug, run_id, status, logger)
      end
    end
  end
end
