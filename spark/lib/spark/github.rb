require "open3"
require "json"

module Spark
  module GitHub
    def self.create_repo(name, description: "", private: true)
      visibility = private ? "--private" : "--public"
      cmd = ["gh", "repo", "create", name, visibility, "--description", description]
      stdout, stderr, status = Open3.capture3(*cmd)
      raise "Failed to create repo: #{stderr}" unless status.success?

      stdout.strip
    end

    def self.ensure_labels(repo, labels)
      labels.each do |label|
        Open3.capture3("gh", "label", "create", label, "--repo", repo, "--force")
      end
    end

    def self.create_issue(repo, title:, body:, labels: [])
      ensure_labels(repo, labels) if labels.any?
      cmd = ["gh", "issue", "create", "--repo", repo, "--title", title, "--body", body]
      labels.each { |l| cmd += ["--label", l] }
      stdout, stderr, status = Open3.capture3(*cmd)
      raise "Failed to create issue: #{stderr}" unless status.success?

      # Extract issue number from URL
      url = stdout.strip
      url.split("/").last.to_i
    end

    def self.create_issue_comment(repo, issue_number, body)
      cmd = ["gh", "issue", "comment", issue_number.to_s, "--repo", repo, "--body", body]
      stdout, stderr, status = Open3.capture3(*cmd)
      raise "Failed to create comment: #{stderr}" unless status.success?

      stdout.strip
    end

    def self.add_label(repo, issue_number, label)
      cmd = ["gh", "issue", "edit", issue_number.to_s, "--repo", repo, "--add-label", label]
      Open3.capture3(*cmd)
    end

    def self.fetch_issue(repo, issue_number)
      cmd = ["gh", "issue", "view", issue_number.to_s, "--repo", repo, "--json",
             "number,title,body,state,author,labels,comments"]
      stdout, stderr, status = Open3.capture3(*cmd)
      raise "Failed to fetch issue: #{stderr}" unless status.success?

      JSON.parse(stdout, symbolize_names: true)
    end

    def self.repo_exists?(name)
      _, _, status = Open3.capture3("gh", "repo", "view", name)
      status.success?
    end
  end
end
