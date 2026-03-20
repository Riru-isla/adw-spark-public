require "open3"

module Spark
  module Actors
    class RunTests < Actor
      include Spark::Actors::PipelineInputs

      def call
        log_actor("Running full test suite")
        update_phase("testing")

        dir = project_dir || File.join(Spark.projects_dir, project_slug)
        results = []

        # Detect and run backend tests
        if File.exist?(File.join(dir, "backend", "Gemfile"))
          results << run_backend_tests(dir)
        elsif File.exist?(File.join(dir, "Gemfile"))
          results << run_backend_tests(dir, subdir: false)
        end

        # Detect and run frontend tests
        frontend_dir = File.join(dir, "frontend")
        results << run_frontend_tests(frontend_dir) if File.exist?(File.join(frontend_dir, "package.json"))

        failures = results.reject { |r| r[:passed] }

        if failures.empty?
          log_actor("All test suites passed (#{results.map { |r| r[:summary] }.join(', ')})")
        else
          failure_details = failures.map { |r| "#{r[:suite]}: #{r[:error]}" }.join("\n")
          log_actor("Test failures detected:\n#{failure_details}")

          # Invoke the AI tester/resolver to fix failures
          resolve_failures(failure_details)
        end
      end

      private

      def run_backend_tests(dir, subdir: true)
        backend_dir = subdir ? File.join(dir, "backend") : dir
        env = { "BUNDLE_GEMFILE" => File.join(backend_dir, "Gemfile") }
        cmd = ["bundle", "exec", "rspec", "--format", "progress"]

        log_actor("Running: bundle exec rspec (backend)")
        stdout, stderr, status = Open3.capture3(env, *cmd, chdir: backend_dir)

        # Extract summary line (e.g., "60 examples, 0 failures")
        summary = stdout.lines.last&.strip || stderr.lines.last&.strip || "unknown"

        {
          suite: "rspec",
          passed: status.success?,
          summary: summary,
          error: status.success? ? nil : "#{summary}\n#{stderr.lines.last(5).join}"
        }
      end

      def run_frontend_tests(frontend_dir)
        # Try npm run test first, fall back to npx vitest run
        cmd = if system("grep -q '\"test\"' #{File.join(frontend_dir, 'package.json')}")
                ["npm", "run", "test", "--", "--run"]
              else
                ["npx", "vitest", "run"]
              end

        log_actor("Running: #{cmd.join(' ')} (frontend)")
        stdout, stderr, status = Open3.capture3(*cmd, chdir: frontend_dir)

        summary = (stdout + stderr).lines.select { |l| l.match?(/Tests?\s|passed|failed/i) }.last&.strip || "unknown"

        {
          suite: "vitest",
          passed: status.success?,
          summary: summary,
          error: status.success? ? nil : "#{summary}\n#{(stdout + stderr).lines.last(10).join}"
        }
      end

      def resolve_failures(failure_details)
        log_actor("Attempting to resolve test failures")

        request = Spark::AgentRequest.new(
          agent_name: "test_resolver",
          slash_command: "/spark:resolve_test",
          args: [failure_details],
          project_slug: project_slug,
          run_id: run_id,
          model: ENV.fetch("SPARK_WORKER_MODEL", "sonnet"),
          cwd: project_dir,
          dangerously_skip_permissions: true
        )

        response = Spark::Agent.execute_template(request)

        if response.success
          log_actor("Test resolver completed, re-running tests")
          # Re-run to verify the fix (one retry only)
          rerun_results = []
          dir = project_dir || File.join(Spark.projects_dir, project_slug)

          rerun_results << run_backend_tests(dir) if File.exist?(File.join(dir, "backend", "Gemfile"))
          frontend_dir = File.join(dir, "frontend")
          rerun_results << run_frontend_tests(frontend_dir) if File.exist?(File.join(frontend_dir, "package.json"))

          still_failing = rerun_results.reject { |r| r[:passed] }
          if still_failing.empty?
            log_actor("All tests pass after resolution")
          else
            log_actor("Warning: some tests still failing after resolution, continuing")
          end
        else
          log_actor("Warning: test resolver failed, continuing with failing tests")
        end
      end
    end
  end
end
