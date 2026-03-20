require "open3"
require "fileutils"
require "timeout"

module Spark
  module Agent
    # Default timeout: 15 minutes. Override via SPARK_AGENT_TIMEOUT_SECS env var.
    DEFAULT_TIMEOUT = (ENV["SPARK_AGENT_TIMEOUT_SECS"] || 900).to_i
    HEARTBEAT_INTERVAL = 30 # seconds between "still alive" messages

    def self.execute_template(request, timeout: DEFAULT_TIMEOUT)
      prompt_dir = File.join(
        Spark.root, ".projects", request.project_slug,
        "logs", request.run_id, request.agent_name, "prompts"
      )
      FileUtils.mkdir_p(prompt_dir)

      # Build the command args
      prompt_text = build_prompt(request)
      File.write(File.join(prompt_dir, "#{sanitize(request.slash_command)}.txt"), prompt_text)

      cmd = build_command(request, prompt_text)

      env = {}
      env["CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR"] = "false" if request.cwd

      # Save full command for manual debugging
      debug_file = File.join(prompt_dir, "debug_command.sh")
      escaped_prompt = prompt_text.gsub("'", "'\\\\''")
      File.write(debug_file, "claude -p '#{escaped_prompt}' --output-format json --model #{request.model}\n")
      agent_id = "#{request.agent_name}@#{request.run_id[0..7]}"
      warn "[Agent:#{agent_id}] Prompt length: #{prompt_text.length} chars (~#{prompt_text.length / 4} tokens est.)"
      warn "[Agent:#{agent_id}] Command: #{request.slash_command}"
      warn "[Agent:#{agent_id}] Debug saved to: #{debug_file}"
      warn "[Agent:#{agent_id}] Timeout: #{timeout}s"

      stdout, stderr_output, exit_status = run_with_streaming(env, cmd, request.cwd, agent_id, timeout)

      warn "[Agent:#{agent_id}] Exit status: #{exit_status}"

      output, usage = parse_stdout(stdout)
      warn "[Agent:#{agent_id}] Parsed output: #{output.slice(0, 300)}" unless output.empty?
      if usage
        cost_str = usage[:cost_usd] ? " cost: $#{'%.2f' % usage[:cost_usd]}" : ""
        turns_str = usage[:num_turns] ? " turns: #{usage[:num_turns]}" : ""
        warn "[Agent:#{agent_id}] Tokens — in: #{usage[:input]} out: #{usage[:output]}#{turns_str}#{cost_str}"
      end

      # Save raw output for debugging
      output_file = File.join(prompt_dir, "raw_output.txt")
      File.write(output_file, stdout)

      # Accumulate token usage in the run tracker
      track_usage(request.project_slug, request.run_id, request.agent_name, usage) if usage

      AgentResponse.new(
        output: output,
        success: exit_status.zero?,
        session_id: extract_session_id(stderr_output),
        usage: usage
      )
    rescue Timeout::Error
      warn "[Agent:#{agent_id}] TIMED OUT after #{timeout}s"
      error_msg = "Agent timed out after #{timeout}s"
      File.write(File.join(prompt_dir, "raw_output.txt"), "TIMEOUT: #{error_msg}\nPartial stdout: #{begin
        stdout_buf
      rescue StandardError
        ''
      end}")
      AgentResponse.new(
        output: error_msg,
        success: false
      )
    rescue StandardError => e
      error_msg = "Agent execution error: #{e.message}"
      begin
        File.write(File.join(prompt_dir, "raw_output.txt"), "ERROR: #{error_msg}\n#{e.backtrace&.first(5)&.join("\n")}")
      rescue StandardError
        nil
      end
      AgentResponse.new(
        output: error_msg,
        success: false
      )
    end

    # Run the subprocess with popen3, streaming stderr in real-time
    # and enforcing a timeout.
    def self.run_with_streaming(env, cmd, cwd, agent_id, timeout)
      stdout_buf = +""
      stderr_buf = +""
      exit_status = nil
      Time.now

      Open3.popen3(env, *cmd, chdir: cwd || Spark.root) do |stdin, stdout, stderr, wait_thread|
        stdin.close
        pid = wait_thread.pid

        # Read stdout and stderr concurrently using threads
        stdout_reader = Thread.new do
          stdout.each_line { |line| stdout_buf << line }
        rescue IOError
          # stream closed
        end

        stderr_reader = Thread.new do
          stderr.each_line do |line|
            stderr_buf << line
            warn "[Agent:#{agent_id}] #{line.chomp}"
          end
        rescue IOError
          # stream closed
        end

        # Wait for process with timeout + heartbeat
        # Track active time (excludes laptop sleep gaps)
        active_time = 0
        last_check = Time.now

        loop do
          # Check if process has finished (non-blocking)
          break if wait_thread.join(HEARTBEAT_INTERVAL)

          now = Time.now
          delta = (now - last_check).to_i

          # If delta >> HEARTBEAT_INTERVAL, the system likely slept.
          # Only count up to 2x the heartbeat interval as active time.
          active_time += [delta, HEARTBEAT_INTERVAL * 2].min
          last_check = now

          if delta > HEARTBEAT_INTERVAL * 2
            warn "[Agent:#{agent_id}] Sleep detected (#{delta}s gap), active time: #{active_time}s"
          else
            warn "[Agent:#{agent_id}] Still running... (#{active_time}s active)"
          end

          next unless active_time > timeout

          begin
            Process.kill("TERM", pid)
          rescue StandardError
            nil
          end
          sleep 2
          begin
            Process.kill("KILL", pid)
          rescue StandardError
            nil
          end
          raise Timeout::Error, "Agent process exceeded #{timeout}s active time"
        end

        # Wait for reader threads to finish draining
        stdout_reader.join(5)
        stderr_reader.join(5)

        exit_status = wait_thread.value.exitstatus
      end

      [stdout_buf, stderr_buf, exit_status]
    end

    def self.build_prompt(request)
      # Resolve slash command to its markdown file content
      # e.g. "/spark:parse_message" -> ".claude/commands/spark/parse_message.md"
      command_path = resolve_command_path(request.slash_command)
      if command_path && File.exist?(command_path)
        template = File.read(command_path)
        # Replace $ARGUMENTS with the actual args
        template.gsub("$ARGUMENTS", request.args.join(" "))
      else
        # Fallback: use slash command as plain text
        parts = [request.slash_command]
        parts.concat(request.args) if request.args.any?
        parts.join(" ")
      end
    end

    def self.resolve_command_path(slash_command)
      # "/spark:parse_message" -> "spark/parse_message"
      name = slash_command.sub(%r{^/}, "").gsub(":", "/")
      File.join(Spark.root, ".claude", "commands", "#{name}.md")
    end

    def self.build_command(request, prompt_text)
      cmd = ["claude", "-p", prompt_text, "--output-format", "json"]
      cmd += ["--model", request.model] if request.model
      cmd += ["--dangerously-skip-permissions"] if request.dangerously_skip_permissions
      cmd
    end

    def self.parse_stdout(stdout)
      return ["", nil] if stdout.strip.empty?

      data = JSON.parse(stdout)
      result = data["result"] || ""
      usage = if data["usage"]
                {
                  input: data["usage"]["input_tokens"] || 0,
                  output: data["usage"]["output_tokens"] || 0,
                  cost_usd: data["total_cost_usd"],
                  num_turns: data["num_turns"],
                  duration_ms: data["duration_ms"]
                }
              end
      [strip_code_fences(result), usage]
    rescue JSON::ParserError
      # If not JSON, return raw stdout
      [strip_code_fences(stdout.strip), nil]
    end

    def self.strip_code_fences(text)
      text.gsub(/\A```\w*\n?/, "").gsub(/\n?```\z/, "").strip
    end

    def self.extract_session_id(stdout)
      match = stdout.match(/session_id["\s:]+([a-f0-9-]+)/)
      match ? match[1] : nil
    end

    def self.sanitize(name)
      name.gsub(/[^a-zA-Z0-9_-]/, "_")
    end

    def self.track_usage(project_slug, run_id, agent_name, usage)
      run = Spark::Tracker::Run.load(project_slug, run_id) || {}
      run[:token_usage] ||= { agents: {}, totals: { input: 0, output: 0, cost_usd: 0.0 } }

      cost = usage[:cost_usd] || 0.0

      run[:token_usage][:agents][agent_name.to_sym] = {
        input: usage[:input],
        output: usage[:output],
        total: usage[:input] + usage[:output],
        cost_usd: cost,
        num_turns: usage[:num_turns],
        duration_s: usage[:duration_ms] ? (usage[:duration_ms] / 1000.0).round : nil
      }

      run[:token_usage][:totals][:input] += usage[:input]
      run[:token_usage][:totals][:output] += usage[:output]
      run[:token_usage][:totals][:cost_usd] = (run[:token_usage][:totals][:cost_usd] || 0.0) + cost

      Spark::Tracker::Run.save(project_slug, run_id, run)
    rescue StandardError => e
      warn "[Agent] Warning: failed to track usage: #{e.message}"
    end

    def self.print_usage_summary(project_slug, run_id)
      run = Spark::Tracker::Run.load(project_slug, run_id) || {}
      usage = run[:token_usage]
      return unless usage

      totals = usage[:totals] || {}
      total_in = totals[:input] || 0
      total_out = totals[:output] || 0
      total_cost = totals[:cost_usd] || 0.0

      warn "\n#{'=' * 70}"
      warn "USAGE SUMMARY (run: #{run_id[0..7]})"
      warn "=" * 70

      agents = usage[:agents] || {}
      agents.each do |name, u|
        cost_str = u[:cost_usd] ? "$%.2f" % u[:cost_usd] : "—"
        dur_str = u[:duration_s] ? "#{u[:duration_s]}s" : "—"
        turns_str = u[:num_turns] ? u[:num_turns].to_s : "—"
        warn format("  %-30s out: %6d  turns: %3s  dur: %5s  cost: %6s", name, u[:output] || 0, turns_str, dur_str, cost_str)
      end

      warn "-" * 70
      if total_cost.positive?
        warn format("  %-30s out: %6d  %19s  cost: $%.2f", "TOTAL", total_out, "", total_cost)
      else
        # Fallback to estimate if no real cost data
        cost_in = total_in * 3.0 / 1_000_000
        cost_out = total_out * 15.0 / 1_000_000
        warn format("  %-30s out: %6d  %19s  cost: ~$%.2f (est.)", "TOTAL", total_out, "", cost_in + cost_out)
      end
      warn "=" * 70
    end
  end
end
