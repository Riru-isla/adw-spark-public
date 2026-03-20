require "dotenv/load"
require "service_actor"
require "dry-struct"
require "dry-types"
require "json"
require "yaml"
require "logger"
require "securerandom"

module Spark
  def self.root
    @root ||= File.expand_path("../..", __dir__)
  end

  def self.projects_dir
    @projects_dir ||= ENV.fetch("SPARK_PROJECTS_DIR", File.join(root, ".projects"))
  end

  def self.default_stack
    @default_stack ||= ENV.fetch("SPARK_DEFAULT_STACK", "rails+vue")
  end

  def self.default_mode
    @default_mode ||= ENV.fetch("SPARK_DEFAULT_MODE", "sketch")
  end

  VALID_MODES = %w[sketch plan build ship].freeze
  VALID_STACKS = %w[rails+vue rails+react phoenix+react phoenix+liveview nextjs].freeze

  RUN_MODES = {
    "sketch" => "Spec + stories only",
    "plan" => "Spec + stories + implementation plans",
    "build" => "Full implementation up to PR",
    "ship" => "Full cycle including deploy"
  }.freeze
end

# Core modules
require_relative "spark/data_types"
require_relative "spark/utils"
require_relative "spark/tracker"
require_relative "spark/agent"
require_relative "spark/github"

# Actors
require_relative "spark/actors/pipeline_inputs"
Dir[File.join(__dir__, "spark/actors", "*.rb")].sort.each { |f| require f }

# Workflows
Dir[File.join(__dir__, "spark/workflows", "*.rb")].sort.each { |f| require f }
