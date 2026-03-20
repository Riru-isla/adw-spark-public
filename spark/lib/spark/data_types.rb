module Spark
  module Types
    include Dry.Types()
  end

  # Parsed from the raw user message
  class IdeaMessage < Dry::Struct
    transform_keys(&:to_sym)

    attribute :raw_text, Types::String
    attribute :stack_override, Types::String.optional.default(nil)
    attribute :mode_override, Types::String.optional.default(nil)
    attribute :skip_questions, Types::Bool.default(false)
    attribute(:received_at, Types::String.default { Time.now.iso8601 })
  end

  # Generated specification from the idea
  class AppSpec < Dry::Struct
    transform_keys(&:to_sym)

    attribute :name, Types::String
    attribute :slug, Types::String
    attribute :description, Types::String
    attribute(:stack, Types::String.default { Spark.default_stack })
    attribute :features, Types::Array.of(Types::String)
    attribute :assumptions, Types::Array.of(Types::String).default([].freeze)
    attribute :questions, Types::Array.of(Types::String).default([].freeze)
    attribute(:mode, Types::String.default { Spark.default_mode })
  end

  # A single story generated from the spec
  class Story < Dry::Struct
    transform_keys(&:to_sym)

    attribute :number, Types::Integer
    attribute :title, Types::String
    attribute :description, Types::String
    attribute :type, Types::String # feature, chore, bug
    attribute :depends_on, Types::Array.of(Types::Integer).default([].freeze)
    attribute :acceptance_criteria, Types::Array.of(Types::String).default([].freeze)
  end

  # Agent request/response (mirrors ADW pattern)
  class AgentRequest < Dry::Struct
    transform_keys(&:to_sym)

    attribute :agent_name, Types::String.default("ops".freeze)
    attribute :slash_command, Types::String
    attribute :args, Types::Array.of(Types::String).default([].freeze)
    attribute :project_slug, Types::String
    attribute :run_id, Types::String
    attribute :model, Types::String.default("sonnet".freeze)
    attribute :cwd, Types::String.optional.default(nil)
    attribute :dangerously_skip_permissions, Types::Bool.default(false)
  end

  class AgentResponse < Dry::Struct
    transform_keys(&:to_sym)

    attribute :output, Types::String
    attribute :success, Types::Bool
    attribute :session_id, Types::String.optional.default(nil)
    attribute :usage, Types::Hash.optional.default(nil)
  end

  # Gate decision from the orchestrator
  class GateDecision < Dry::Struct
    transform_keys(&:to_sym)

    attribute :proceed, Types::Bool
    attribute :reason, Types::String
    attribute :action, Types::String.default("proceed".freeze) # proceed, ask_back, refine, abort
    attribute :questions, Types::Array.of(Types::String).default([].freeze)
    attribute :suggestions, Types::Array.of(Types::String).default([].freeze)
  end
end
