# Mode: sketch — Spec + stories only (quick capture)
module Spark
  module Workflows
    class Sketch < Actor
      input :raw_message, type: String
      input :project_slug, type: String, default: -> { "pending" }
      input :run_id, type: String
      input :logger
      input :mode, default: -> { "sketch" }

      def call
        # Phase 1: Parse the message
        parsed = Spark::Actors::ParseMessage.result(
          raw_message: raw_message,
          project_slug: project_slug,
          run_id: run_id,
          logger: logger,
          mode: mode
        )
        return fail!(error: parsed.error) unless parsed.success?

        slug = parsed.project_slug
        resolved_mode = parsed.mode

        # Initialize project tracking
        init = Spark::Actors::InitializeProject.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: resolved_mode,
          raw_message: raw_message
        )
        return fail!(error: init.error) unless init.success?

        # Phase 2: Generate spec
        spec = Spark::Actors::GenerateSpec.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: resolved_mode,
          idea_message: parsed.idea_message
        )
        return fail!(error: spec.error) unless spec.success?

        # Phase 3: Gate check on spec
        gate = Spark::Actors::GateCheck.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: resolved_mode,
          gate_name: "spec_review",
          gate_context: JSON.generate(spec.app_spec.to_h),
          idea_message: parsed.idea_message
        )
        return fail!(error: gate.error) unless gate.success?

        # Phase 4: Generate stories
        stories = Spark::Actors::GenerateStories.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: resolved_mode,
          app_spec: spec.app_spec
        )
        return fail!(error: stories.error) unless stories.success?

        # Phase 5: Gate check on stories
        gate = Spark::Actors::GateCheck.result(
          project_slug: slug,
          run_id: run_id,
          logger: logger,
          mode: resolved_mode,
          gate_name: "stories_review",
          gate_context: JSON.generate(stories.stories.map(&:to_h)),
          idea_message: parsed.idea_message
        )
        return fail!(error: gate.error) unless gate.success?

        Spark::Tracker.update_status(slug, run_id, "sketch_complete", logger)
        logger.info("Sketch complete: #{stories.stories.length} stories for '#{spec.app_spec.name}'")
      end
    end
  end
end
