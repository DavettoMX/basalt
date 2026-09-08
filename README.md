# Basalt

**An environment for agentic coding.** Basalt provisions context for AI agents the way Terraform provisions infrastructure — declaratively, reviewably, and with drift detection.

## Naming

Basalt is inspired by the Rosetta Stone — a granodiorite stele (long misidentified as basalt) inscribed with the **Decree** of Memphis (196 BC) in three scripts, the artifact that made translation between human languages possible. Basalt enables the transition from human to agent: the stone is **Basalt**, the text it bears is **Decree**.

## The Problem

AI agents working on a codebase wander. To find where a functionality lives, an agent runs `ls -a`, greps at random, or waits to be hand-fed files. Along the way it fills its context window with noise, burns tokens, and — worst of all — **makes assumptions** about structure, dependencies, and intent. When it encounters a denormalized field or an unusual constraint, it has no way to know whether that was deliberate — and may "fix" something that was load-bearing.

Meanwhile, developers don't document, and the documentation that does exist is prose written for humans, not consumable by machines.

## The Approach

For humans, Confluence answers "where does X live?" — you consult the space map and open a page only when you need depth. Basalt gives agents the same access pattern, machine-native:

- **Headers for codebases** — `.decree` files are to source code what C++ headers are to implementations: compressed structural metadata the agent reads *instead of* the source. Headers are **derived** from the namespace (the source code) — never hand-edited, regenerated on change, validated in CI.
- **Progressive disclosure** — three layers, each adding new information, never duplicating the previous:

  | Layer | File | Contains | When read |
  |---|---|---|---|
  | Topology | `manifest.decree` | Every domain, every component, every dependency | Always, first |
  | Structure | `spec.decree` | Complete structural contract of a single domain | Per domain |
  | Behavior | `body.decree` | Business rules, sample data, design decisions, ownership — *why the module exists* | Only when needed |

- **Institutional memory** — append-only `decisions.log` per domain: the *why* behind non-obvious choices, queryable by field path.
- **Protected sections** — zones agents can read but never write, preserving information integrity and preventing context corruption.

The result: fewer agent assumptions, faster navigation (bug tracebacks follow the dependency graph instead of filesystem walks), and lower token cost — accuracy and scope of context first, compression second.

## Components

| Component | Status | Role |
|---|---|---|
| **Decree** | Active | The `.decree` header system: `manifest` / `spec` / `body` + `decisions.log` |
| **quarry** | Active (standalone) | Spec-driven + QA scaffolding: visible specs, hidden tests, per-spec verdict harness (ADR-008) |
| **Change traceability** | Planned | Trace changes and classify them — business requirement vs. bug — linked to the rationale that motivated them |

## Current State

- Implemented today as an AI-agent skill (`/basalt`) that scans a codebase and generates the `.basalt/` directory (plan + apply + validate in one pass).
- Standalone CLI planned (Phase 1), Terraform-style: `plan` / `apply` / `validate` / `serve`.
- Benchmarked against the [OpenCode](https://github.com/sst/opencode) repository.

## Usage

Basalt is pre-alpha. It runs entirely inside **Claude Code** — no standalone binary yet. There are three pieces, and each exists for a reason:

### 1. The Skill (`/basalt`)

**What it is:** A Claude Code skill — a structured prompt that Claude executes when you type `/basalt` in any project.

**Why a skill:** Basalt needs to read source files, identify domains, generate a custom DSL, cross-validate references, and write multiple output files. A skill gives the agent a repeatable, step-by-step procedure instead of relying on ad-hoc prompting. It turns "generate codebase metadata" from a vague request into a deterministic pipeline.

**Install:**

```
cp -r skills/basalt ~/.claude/skills/basalt
```

**Run:**

```
/basalt
```

The skill scans the codebase and generates the `.basalt/` directory with all `.decree` files in one pass (plan + apply + validate). It detects the project ecosystem (Node, Go, Rust, Python, etc.), discovers domains (database, API, frontend, application), extracts structural contracts into the `.decree` DSL, captures behavioral context, and logs design decisions — all without touching your source code.

### 2. The Hooks (`PreToolUse` + `Stop`)

**What they are:** Shell scripts registered as Claude Code hooks in the project's `.claude/settings.json`. Claude Code executes them automatically at specific lifecycle points.

**Why hooks:** Generating `.decree` files is only half the problem. The other half is making sure agents actually *use* them — and keep them updated. Without enforcement, an agent will skip the manifest, go straight to `grep`, and make the same blind assumptions Basalt exists to prevent. Instructions in `CLAUDE.md` help, but agents under pressure take shortcuts. Hooks make compliance mechanical, not optional.

| Hook | Trigger | What it enforces |
|---|---|---|
| `enforce-decree-read.sh` | `PreToolUse` on `Edit` or `Write` | Blocks edits to source files until the agent has read `manifest.decree`. Forces the agent to understand the architecture before changing it. |
| `enforce-decree-update.sh` | `Stop` | Blocks the agent from finishing if it created new source files without updating the corresponding `.decree` or `decisions.log`. Prevents documentation drift at the moment it would begin. |

The skill generates both hooks automatically when you run `/basalt`. They are placed in `.claude/hooks/` and registered in `.claude/settings.json`.

### 3. The CLAUDE.md Section

**What it is:** A block of instructions the skill appends to the project's `CLAUDE.md`.

**Why CLAUDE.md:** `CLAUDE.md` is the first thing Claude Code reads when entering a project — it's the project-level system prompt. The basalt section tells future Claude sessions *how* to use the `.basalt/` directory: read the manifest first, drill into domain specs on demand, never explore source to verify decree content, and update decrees after structural changes. It's the behavioral contract between Basalt and every future agent session.

### Putting it together

```
# One-time setup: install the skill
cp -r skills/basalt ~/.claude/skills/basalt

# In any project: generate .basalt/ + hooks + CLAUDE.md
cd your-project/
claude
> /basalt

# From now on, every Claude session in this project:
#   - reads .basalt/manifest.decree before touching code (enforced by PreToolUse hook)
#   - updates .decree files after structural changes (enforced by Stop hook)
#   - follows the navigation protocol in CLAUDE.md
```
