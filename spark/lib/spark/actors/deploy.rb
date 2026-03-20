module Spark
  module Actors
    class Deploy < Actor
      include Spark::Actors::PipelineInputs

      input :app_spec
      output :deploy_url
      output :project_tracker

      def call
        log_actor("Deploying application")
        update_phase("deploying")

        request = Spark::AgentRequest.new(
          agent_name: "deployer",
          slash_command: "/spark:deploy",
          args: [JSON.generate(app_spec.to_h)],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir
        )

        response = Spark::Agent.execute_template(request)

        unless response.success
          log_actor("Deploy failed (non-blocking): #{response.output}")
          self.deploy_url = nil
          return
        end

        self.deploy_url = response.output.strip

        tracker = Spark::Tracker::Project.load(project_slug) || {}
        tracker[:deploy_url] = deploy_url
        tracker[:status] = "deployed"
        Spark::Tracker::Project.save(project_slug, tracker)
        self.project_tracker = tracker

        log_actor("Deployed at: #{deploy_url}")
      end
    end
  end
end
