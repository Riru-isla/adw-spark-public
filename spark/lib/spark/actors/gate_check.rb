module Spark
  module Actors
    class GateCheck < Actor
      include Spark::Actors::PipelineInputs

      input :gate_name, type: String
      input :gate_context, type: String # JSON payload to evaluate
      input :idea_message, default: -> { nil }
      output :gate_decision

      def call
        log_actor("Gate check: #{gate_name}")

        skip_questions = idea_message&.skip_questions || false

        request = Spark::AgentRequest.new(
          agent_name: "gate_#{gate_name}",
          slash_command: "/spark:gate",
          args: [gate_name, gate_context, skip_questions.to_s],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_GATE_MODEL", "sonnet")
        )

        response = Spark::Agent.execute_template(request)

        fail!(error: "Gate check '#{gate_name}' failed: #{response.output}") unless response.success

        parsed = JSON.parse(response.output, symbolize_names: true)
        self.gate_decision = Spark::GateDecision.new(parsed)

        case gate_decision.action
        when "abort"
          fail!(error: "Gate '#{gate_name}' aborted: #{gate_decision.reason}")
        when "ask_back"
          log_actor("Gate '#{gate_name}' needs clarification: #{gate_decision.questions.join(', ')}")
          save_questions(gate_decision.questions)
          update_status("waiting_for_input")
          fail!(error: "awaiting_clarification")
        when "refine"
          log_actor("Gate '#{gate_name}' suggests refinement: #{gate_decision.reason}")
          # Pipeline continues — the next actor should handle refinement
        when "proceed"
          log_actor("Gate '#{gate_name}' approved")
        end
      end

      private

      def save_questions(questions)
        questions_path = File.join(Spark::Utils.project_dir(project_slug), "pending_questions.yaml")
        FileUtils.mkdir_p(File.dirname(questions_path))
        File.write(questions_path, YAML.dump({
                                               "gate" => gate_name,
                                               "run_id" => run_id,
                                               "questions" => questions,
                                               "asked_at" => Time.now.iso8601
                                             }))
      end
    end
  end
end
