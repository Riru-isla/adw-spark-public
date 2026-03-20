module Spark
  module Actors
    class SmokeTest < Actor
      include Spark::Actors::PipelineInputs

      input :app_spec

      def call
        log_actor("Running smoke test on assembled app")
        update_phase("smoke_testing")

        request = Spark::AgentRequest.new(
          agent_name: "smoke_tester",
          slash_command: "/spark:smoke_test",
          args: [JSON.generate(app_spec.to_h)],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir
        )

        response = Spark::Agent.execute_template(request)

        unless response.success
          log_actor("Smoke test failed (non-blocking): #{response.output}")
          return
        end

        log_actor("Smoke test passed")
      end
    end
  end
end
