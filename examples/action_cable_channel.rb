# frozen_string_literal: true

# Example: Action Cable channel that triggers Spark pipelines
# Add this to a Rails app that serves as your "command center"
#
# 1. Mount Action Cable in config/routes.rb
# 2. Create this channel
# 3. Connect from any client (browser, mobile, Telegram bot relay)
#
# Client sends: { message: "paint collection app, ship it" }
# Server spawns a Spark pipeline and streams status updates back

class SparkChannel < ApplicationCable::Channel
  def subscribed
    stream_from "spark_#{current_user_id}"
  end

  def receive(data)
    message = data['message']
    return unless message.present?

    run_id = SecureRandom.uuid[0..7]

    # Notify client immediately
    ActionCable.server.broadcast("spark_#{current_user_id}", {
                                   type: 'accepted',
                                   run_id: run_id,
                                   message: 'Idea received! Starting Spark pipeline...'
                                 })

    # Spawn Spark in background
    SparkJob.perform_later(
      message: message,
      run_id: run_id,
      user_id: current_user_id
    )
  end

  private

  def current_user_id
    # Simplified — use your auth system
    params[:user_id] || 'default'
  end
end

# Example background job
class SparkJob < ApplicationJob
  queue_as :spark

  def perform(message:, run_id:, user_id:)
    # Call the spark CLI
    spark_bin = Rails.root.join('..', 'spark', 'bin', 'spark').to_s

    Open3.popen2e(spark_bin, message) do |_stdin, stdout_err, wait_thr|
      stdout_err.each_line do |line|
        # Stream progress back to the client
        ActionCable.server.broadcast("spark_#{user_id}", {
                                       type: 'progress',
                                       run_id: run_id,
                                       log: line.strip
                                     })
      end

      status = wait_thr.value

      ActionCable.server.broadcast("spark_#{user_id}", {
                                     type: status.success? ? 'complete' : 'error',
                                     run_id: run_id,
                                     message: status.success? ? 'Your app is ready!' : 'Pipeline failed — check logs'
                                   })
    end
  end
end
