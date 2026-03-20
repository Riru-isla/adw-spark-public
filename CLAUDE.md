# Spark — Idea to App Pipeline

Spark takes a casual message describing an app idea and autonomously produces a working application.

## How It Works

Spark runs through a pipeline of AI-powered stages: message parsing, spec generation, story breakdown, project scaffolding, implementation, testing, and deployment. Each stage is a separate Claude Code session with fresh context, coordinated by a Ruby actor system.

## Pipeline Overview

```
Message → ParseMessage → GenerateSpec → GateCheck → GenerateStories → GateCheck
  → CreateRepo → Bootstrap → BuildLoop (plan → implement → context per story)
  → RunTests → CondenseContext → SmokeTest → Deploy
```

## Run Modes

| Mode | What happens |
|------|-------------|
| sketch | Parse message → spec → stories (quick capture) |
| plan | sketch + create GitHub repo + file issues |
| build | plan + implement all stories + test + review |
| ship | build + deploy via Docker |

## Key Patterns

- **Ruby actors** (service_actor gem) compose the pipeline
- **YAML trackers** are the "memory" between Claude sessions
- **Gate checks** ask clarifying questions between phases (skip with "guess everything")
- **Separate Claude sessions** per phase — each gets only the context it needs

## Default Stack

Rails 8 + Vue 3 (overridable in the message: "build this with phoenix+react")

## Usage

```bash
cd spark && bundle install
./bin/spark "an app to organize my paint collection"
./bin/spark "recipe manager, ship it" ship
./bin/spark "bookmark manager, guess everything" build
```

## Full Version

The agent prompts and detailed architecture docs are available in the private version.
Contact [@Riru-isla](https://github.com/Riru-isla) for access.
