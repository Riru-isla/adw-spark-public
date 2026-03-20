module Spark
  module Actors
    class GenerateStories < Actor
      include Spark::Actors::PipelineInputs

      input :app_spec
      output :stories
      output :project_tracker

      def call
        log_actor("Generating stories from spec")
        update_phase("story_generation")

        request = Spark::AgentRequest.new(
          agent_name: "story_generator",
          slash_command: "/spark:generate_stories",
          args: [JSON.generate(app_spec.to_h)],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_PLANNER_MODEL", "opus")
        )

        response = Spark::Agent.execute_template(request)

        fail!(error: "Failed to generate stories: #{response.output}") unless response.success

        parsed = JSON.parse(response.output, symbolize_names: true)
        self.stories = parsed[:stories].map { |s| Spark::Story.new(s) }

        # Save stories
        stories_path = File.join(Spark::Utils.project_dir(project_slug), "stories.yaml")
        File.write(stories_path, YAML.dump(parsed[:stories].map { |s| s.transform_keys(&:to_s) }))

        tracker = Spark::Tracker::Project.load(project_slug) || {}
        tracker[:stories_path] = stories_path
        tracker[:story_count] = stories.length
        tracker[:status] = "stories_generated"
        Spark::Tracker::Project.save(project_slug, tracker)
        self.project_tracker = tracker

        log_actor("Generated #{stories.length} stories")
      end
    end
  end
end
