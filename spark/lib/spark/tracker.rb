require "fileutils"

module Spark
  module Tracker
    # Project-level tracker: .projects/{slug}/project.yaml
    module Project
      def self.path(project_slug)
        File.join(Spark.projects_dir, project_slug, "project.yaml")
      end

      def self.load(project_slug)
        file = path(project_slug)
        return nil unless File.exist?(file)

        YAML.safe_load(File.read(file), permitted_classes: [Symbol, Time], symbolize_names: true)
      end

      def self.save(project_slug, data)
        file = path(project_slug)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data.transform_keys(&:to_s)))
      end

      def self.create(project_slug:, raw_message:, stack:, mode:)
        data = {
          slug: project_slug,
          raw_message: raw_message,
          stack: stack,
          mode: mode,
          status: "received",
          created_at: Time.now.iso8601,
          updated_at: Time.now.iso8601,
          spec_path: nil,
          stories_path: nil,
          repo_url: nil,
          deploy_url: nil,
          runs: []
        }
        save(project_slug, data)
        data
      end
    end

    # Run-level tracker: .projects/{slug}/runs/{run_id}.yaml
    module Run
      def self.path(project_slug, run_id)
        File.join(Spark.projects_dir, project_slug, "runs", "#{run_id}.yaml")
      end

      def self.load(project_slug, run_id)
        file = path(project_slug, run_id)
        return nil unless File.exist?(file)

        YAML.safe_load(File.read(file), permitted_classes: [Symbol, Time], symbolize_names: true)
      end

      def self.save(project_slug, run_id, data)
        file = path(project_slug, run_id)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data.transform_keys(&:to_s)))
      end

      def self.create(run_id:, mode:, trigger:)
        {
          run_id: run_id,
          mode: mode,
          trigger: trigger,
          status: "started",
          started_at: Time.now.iso8601,
          current_phase: nil,
          completed_stories: [],
          errors: []
        }
      end
    end

    def self.update_status(project_slug, run_id, status, logger)
      run = Run.load(project_slug, run_id) || {}
      run[:status] = status
      run[:updated_at] = Time.now.iso8601
      Run.save(project_slug, run_id, run)
      logger.info("[Tracker] Status: #{status}")
      run
    end

    def self.update_phase(project_slug, run_id, phase, logger)
      run = Run.load(project_slug, run_id) || {}
      run[:current_phase] = phase
      run[:updated_at] = Time.now.iso8601
      Run.save(project_slug, run_id, run)
      logger.info("[Tracker] Phase: #{phase}")
      run
    end
  end
end
