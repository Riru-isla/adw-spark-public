module Spark
  module Actors
    class ParseMessage < Actor
      include Spark::Actors::PipelineInputs

      input :raw_message, type: String
      output :idea_message
      output :project_slug
      output :mode

      def call
        log_actor("Parsing incoming message")
        update_phase("parsing")

        request = Spark::AgentRequest.new(
          agent_name: "message_parser",
          slash_command: "/spark:parse_message",
          args: [raw_message],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_PLANNER_MODEL", "sonnet")
        )

        response = Spark::Agent.execute_template(request)

        fail!(error: "Failed to parse message: #{response.output}") unless response.success

        parsed = JSON.parse(response.output, symbolize_names: true)

        self.idea_message = Spark::IdeaMessage.new(
          raw_text: raw_message,
          stack_override: parsed[:stack_override],
          mode_override: parsed[:mode_override],
          skip_questions: parsed[:skip_questions] || false
        )

        self.mode = parsed[:mode_override] || Spark.default_mode
        self.project_slug = parsed[:slug] || Spark::Utils.slugify(parsed[:name] || "unnamed")
      end
    end
  end
end
