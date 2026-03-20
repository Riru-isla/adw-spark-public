module Spark
  module Actors
    class CreateGithubRepo < Actor
      include Spark::Actors::PipelineInputs

      input :app_spec
      output :repo_name
      output :project_tracker

      def call
        log_actor("Creating GitHub repository")
        update_phase("creating_repo")

        gh_user = `gh api user --jq '.login'`.strip
        self.repo_name = "#{gh_user}/#{project_slug}"

        if Spark::GitHub.repo_exists?(repo_name)
          log_actor("Repo #{repo_name} already exists, skipping creation")
        else
          Spark::GitHub.create_repo(
            project_slug,
            description: app_spec.description,
            private: true
          )
          log_actor("Created repo: #{repo_name}")
        end

        tracker = Spark::Tracker::Project.load(project_slug) || {}
        tracker[:repo_url] = "https://github.com/#{repo_name}"
        tracker[:repo_name] = repo_name
        Spark::Tracker::Project.save(project_slug, tracker)
        self.project_tracker = tracker
      end
    end
  end
end
