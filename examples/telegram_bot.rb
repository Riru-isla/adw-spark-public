# frozen_string_literal: true

# Example: Telegram bot that triggers Spark pipelines
# Requires: gem "telegram-bot-ruby"
#
# Usage:
#   1. Create a bot via @BotFather on Telegram
#   2. Set TELEGRAM_BOT_TOKEN in .env
#   3. Run: ruby examples/telegram_bot.rb
#   4. Send your bot a message: "paint collection app, ship it"

require 'telegram/bot'
require 'open3'

token = ENV.fetch('TELEGRAM_BOT_TOKEN')
spark_bin = File.expand_path('../spark/bin/spark', __dir__)
authorized_users = ENV.fetch('TELEGRAM_AUTHORIZED_USERS', '').split(',').map(&:strip)

Telegram::Bot::Client.run(token) do |bot|
  puts 'Spark Telegram bot started. Listening for ideas...'

  bot.listen do |message|
    next unless message.is_a?(Telegram::Bot::Types::Message)
    next unless message.text

    user = message.from.username
    chat_id = message.chat.id

    # Authorization check
    unless authorized_users.empty? || authorized_users.include?(user)
      bot.api.send_message(chat_id: chat_id, text: 'Not authorized. Add your username to TELEGRAM_AUTHORIZED_USERS.')
      next
    end

    text = message.text.strip
    next if text.start_with?('/start')

    if text == '/status'
      # List recent projects
      projects_dir = File.expand_path('../.projects', __dir__)
      if Dir.exist?(projects_dir)
        projects = Dir.children(projects_dir).sort
        status = projects.map { |p| "- #{p}" }.join("\n")
        bot.api.send_message(chat_id: chat_id, text: "Projects:\n#{status}")
      else
        bot.api.send_message(chat_id: chat_id, text: 'No projects yet.')
      end
      next
    end

    # Trigger Spark
    bot.api.send_message(chat_id: chat_id, text: 'Idea received! Sparking...')

    Thread.new do
      _, stderr, status = Open3.capture3(spark_bin, text)

      if status.success?
        bot.api.send_message(chat_id: chat_id, text: 'Done! Your idea has been captured and processed.')
      else
        bot.api.send_message(chat_id: chat_id, text: "Something went wrong:\n#{stderr.lines.last(3).join}")
      end
    end
  end
end
