module Spark
  module Actors
    class GenerateSpec < Actor
      include Spark::Actors::PipelineInputs

      input :idea_message
      output :app_spec
      output :project_tracker

      def call
        log_actor("Generating application spec")
        update_phase("specifying")

        stack = idea_message.stack_override || Spark.default_stack

        request = Spark::AgentRequest.new(
          agent_name: "spec_generator",
          slash_command: "/spark:generate_spec",
          args: [idea_message.raw_text, stack, mode],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_PLANNER_MODEL", "opus")
        )

        response = Spark::Agent.execute_template(request)

        fail!(error: "Failed to generate spec: #{response.output}") unless response.success

        parsed = JSON.parse(response.output, symbolize_names: true)
        self.app_spec = Spark::AppSpec.new(parsed.merge(stack: stack, mode: mode))

        # Save spec to project
        spec_path = File.join(Spark::Utils.project_dir(project_slug), "spec.yaml")
        FileUtils.mkdir_p(File.dirname(spec_path))
        File.write(spec_path, YAML.dump(parsed.transform_keys(&:to_s)))

        # Update project tracker
        tracker = Spark::Tracker::Project.load(project_slug) || {}
        tracker[:spec_path] = spec_path
        tracker[:status] = "specified"
        Spark::Tracker::Project.save(project_slug, tracker)
        self.project_tracker = tracker
      end
    end
  end
end
