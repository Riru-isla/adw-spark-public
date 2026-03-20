# Spark

Spark takes a casual message describing an app idea and autonomously produces a working application. Describe what you want in plain English, and Spark handles the rest — from spec generation to deployment.

## How It Works

Spark runs your idea through a pipeline of stages, each powered by Claude Code:

| Mode | What It Does |
|------|-------------|
| **sketch** | Parse message, generate spec + user stories |
| **plan** | Sketch + create GitHub repo + file issues |
| **build** | Plan + implement all stories + test + review |
| **ship** | Build + deploy via Docker |

The default mode is `sketch`. You can escalate by passing a mode explicitly or by including keywords like `"ship it"` in your message.

## Prerequisites

- Ruby 3.x
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub CLI](https://cli.github.com/) (`gh`) — for `plan` mode and above
- Docker — for `ship` mode

## Setup

```bash
cd spark && bundle install
cp .env.example .env
# Edit .env with your GitHub token and preferences
```

## Usage

```bash
# Quick sketch — generates spec and stories
./bin/spark "an app to organize my paint collection"

# Specify a mode
./bin/spark "a recipe manager" plan

# Override the default stack
./bin/spark "budget tracker, build with phoenix+react" build

# Go all the way to deployment
./bin/spark "todo app, guess everything, ship it" ship

# Resume a paused project with answers to clarification questions
./bin/spark_resume paint-vault "yes barcode scanning, no sharing"

# Stream ideas from stdin (pipe from Action Cable, Telegram, etc.)
echo "paint collection app" | ./bin/spark_listen
```

## Configuration

All configuration lives in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_TOKEN` | — | GitHub personal access token |
| `SPARK_DEFAULT_STACK` | `rails+vue` | Default tech stack |
| `SPARK_DEFAULT_MODE` | `sketch` | Default run mode |
| `SPARK_PROJECTS_DIR` | `.projects` | Where generated projects are created |
| `SPARK_PLANNER_MODEL` | `sonnet` | Claude model for planning stages |
| `SPARK_WORKER_MODEL` | `sonnet` | Claude model for implementation |
| `SPARK_GATE_MODEL` | `sonnet` | Claude model for gate checks |
| `SPARK_AGENT_TIMEOUT_SECS` | `900` | Max seconds per agent invocation (15 min) |

### Supported Stacks

`rails+vue` | `rails+react` | `phoenix+react` | `phoenix+liveview` | `nextjs`

## Project Structure

```
adw-spark/
├── spark/                    # Ruby actor system (orchestration layer)
│   ├── lib/spark/
│   │   ├── actors/          # Individual pipeline steps (12 actors)
│   │   ├── workflows/       # Composed pipelines (sketch, plan, build, ship)
│   │   ├── agent.rb         # Claude Code CLI invocation (popen3 streaming + timeout)
│   │   ├── tracker.rb       # YAML-based state tracking
│   │   ├── github.rb        # GitHub API (via gh CLI)
│   │   ├── data_types.rb    # Dry::Struct types
│   │   └── utils.rb         # Logging, IDs, helpers
│   └── bin/                 # Entry points
├── .claude/commands/spark/  # Claude commands invoked by actors
├── .projects/               # Generated projects live here (gitignored)
└── examples/                # Action Cable integration example
```

## Agent Pipeline

Each run mode executes a subset of this pipeline. Every box is a separate Claude Code session with fresh context.

```
 Message arrives
 ("paint collection app, ship it")
       │
       ▼
 ┌─────────────┐
 │ ParseMessage │  Extract idea, stack, mode, skip_questions
 └──────┬──────┘
        ▼
 ┌──────────────────┐
 │ InitializeProject │  Create project tracker YAML
 └───────┬──────────┘
         ▼
 ┌──────────────┐
 │ GenerateSpec  │  Structured spec: name, features, assumptions
 └──────┬───────┘
        ▼
 ┌────────────────┐
 │ GateCheck: spec │  Ask-back or auto-approve
 └───────┬────────┘
         ▼
 ┌─────────────────┐
 │ GenerateStories  │  Dependency-ordered user stories
 └───────┬─────────┘
         ▼
 ┌────────────────────┐
 │ GateCheck: stories  │  Validate scope ← sketch stops here
 └───────┬────────────┘
         ▼
 ┌─────────────────┐
 │ CreateGithubRepo │  gh repo create --private
 └───────┬─────────┘
         ▼
 ┌───────────────┐
 │ BootstrapRepo  │  Scaffold (rails new, vue create, etc.)
 │                │  git init → commit → push
 └───────┬───────┘
         ▼
 ┌────────────────────┐
 │ CreateGithubIssues  │  File each story as an issue ← plan stops here
 └───────┬────────────┘
         ▼
 ┌──────────────────────────────────────────────┐
 │              BuildLoop (per story)            │
 │                                              │
 │  ┌────────────┐                              │
 │  │ PlanStory   │  Step-by-step impl plan     │
 │  └─────┬──────┘                              │
 │        ▼                                     │
 │  ┌────────────┐                              │
 │  │ Implement   │  Execute plan, write code    │
 │  │             │  (runs story-scoped tests)   │
 │  └─────┬──────┘                              │
 │        ▼                                     │
 │  ┌─────────────────┐                         │
 │  │ GenerateContext   │  Document what changed  │
 │  └─────┬───────────┘                         │
 │        ▼                                     │
 │    git commit → push                         │
 │    (repeat for next story)                   │
 └───────────────┬──────────────────────────────┘
                 ▼
 ┌──────────────────┐
 │ RunTests          │  Full test suite (shell, no AI)
 │                   │  → AI resolver only on failure
 └───────┬──────────┘
         ▼
 ┌──────────────────┐
 │ CondenseContext    │  Merge per-story context into project.md
 └───────┬──────────┘
         ▼
 ┌────────────┐
 │ SmokeTest   │  Verify assembled app structure ← build stops here
 └──────┬─────┘
        ▼
 ┌────────────┐
 │ Deploy      │  docker-compose up, report URL ← ship stops here
 └────────────┘
```

## Gate Checks

Between pipeline phases, Spark pauses to ask clarification questions (e.g., "Should the app support multi-tenancy?"). You can skip these by including phrases in your message:

- **"guess everything"** — Spark makes all decisions autonomously
- **"do mvp"** — Minimal viable scope, skip nice-to-haves

## Documentation

| Document | What it covers |
|----------|---------------|
| [README.md](./README.md) | Setup, usage, configuration, pipeline overview |
| [CLAUDE.md](./CLAUDE.md) | Architecture decisions, key patterns, project context (loaded by Claude Code on every session) |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Deep technical reference: YAML tracker schemas, agent invocation protocol, ask-back recovery flow, runtime file organization, git edge cases, error handling, and data types. Read this for onboarding or migration to another language |
