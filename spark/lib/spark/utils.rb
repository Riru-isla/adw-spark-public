module Spark
  module Utils
    def self.make_run_id
      SecureRandom.uuid[0..7]
    end

    def self.setup_logger(project_slug, run_id, trigger_type)
      log_dir = File.join(Spark.root, ".projects", project_slug, "logs", run_id, trigger_type)
      FileUtils.mkdir_p(log_dir)

      log_file = File.join(log_dir, "execution.log")

      logger = Logger.new(
        [$stdout, File.open(log_file, "a")],
        level: Logger::DEBUG
      )
      logger.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] [#{severity}] #{msg}\n"
      end
      logger
    rescue StandardError => e
      # Fallback to stdout only
      logger = Logger.new($stdout)
      logger.warn("Could not create file logger: #{e.message}")
      logger
    end

    def self.project_dir(project_slug)
      File.join(Spark.projects_dir, project_slug)
    end

    def self.slugify(name)
      name.downcase
          .gsub(/[^a-z0-9\s-]/, "")
          .gsub(/\s+/, "-")
          .gsub(/-+/, "-")
          .gsub(/^-|-$/, "")
    end
  end
end
