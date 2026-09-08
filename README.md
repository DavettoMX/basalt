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

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated.
- A project you want to map with Basalt.

### Step 1 — Clone this repository

```bash
git clone git@github.com:DavettoMX/basalt.git
```

This gives you the skill definition that Claude Code needs. The skill is a structured prompt — not a binary — that tells Claude how to analyze a codebase and generate `.decree` files.

### Step 2 — Install the skill into Claude Code

```bash
cp -r basalt/skills/basalt ~/.claude/skills/basalt
```

Claude Code loads skills from `~/.claude/skills/`. Each subdirectory there becomes available as a `/command` in any Claude Code session. After this step, `/basalt` is available globally — you only need to do this once.

### Step 3 — Open your project in Claude Code

```bash
cd your-project/
claude
```

### Step 4 — Run `/basalt`

Inside the Claude Code session, type:

```
/basalt
```

This is the only command you run. The skill handles everything else automatically:

1. **Ecosystem detection** — reads `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, etc. to identify the tech stack.
2. **Domain discovery** — scans for database schemas, API routes, frontend components, and application logic using ecosystem-specific patterns.
3. **`.basalt/` generation** — creates the directory with `manifest.decree` (topology), plus per-domain subdirectories containing `spec.decree` (structural contract), `body.decree` (behavioral context), and `decisions.log` (institutional memory).
4. **Validation** — cross-checks all references: FK targets exist, imports resolve, frontend components match actual files, body claims are verifiable against source.
5. **`CLAUDE.md` integration** — appends a basalt section to the project's `CLAUDE.md` (creates it if it doesn't exist). This section tells future Claude sessions how to navigate using `.basalt/` — read the manifest first, drill into specs on demand, update decrees after structural changes.
6. **Hook installation** — generates two shell scripts in `.claude/hooks/` and registers them in the project's `.claude/settings.json`. This step is automatic — no manual configuration needed.

No source files are modified. All output goes to `.basalt/`, `.claude/`, and `CLAUDE.md`.

### What the hooks do and why they exist

Generating `.decree` files is only half the problem. The other half is making sure agents actually *use* them — and keep them updated. Without enforcement, an agent will skip the manifest, go straight to `grep`, and make the same blind assumptions Basalt exists to prevent. Instructions in `CLAUDE.md` help, but agents under pressure take shortcuts. Hooks make compliance mechanical, not optional.

Claude Code [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) are shell scripts that execute automatically at specific points in the agent's lifecycle. They can block an action (exit code 2) or allow it (exit code 0). Basalt uses two:

**`enforce-decree-read.sh`** — triggers on `PreToolUse` when the agent calls `Edit` or `Write`.

Before the agent can modify any source file, this hook checks whether `manifest.decree` has been read in the current session. If it hasn't, the hook blocks the edit and tells the agent to read the manifest and relevant decree files first. This forces the agent to understand the project architecture before changing it. Edits to `.basalt/` and `CLAUDE.md` are always allowed (the agent needs to update its own metadata).

**`enforce-decree-update.sh`** — triggers on `Stop` when the agent finishes responding.

When the agent is about to end its turn, this hook checks whether it created new source files (via `Write`) without also creating or updating any `.decree` or `decisions.log` file. If it did, the hook blocks the stop and tells the agent to update the relevant decree files before finishing. This prevents documentation drift at the exact moment it would begin — the agent cannot "finish and update later."

Both hooks are registered in `.claude/settings.json` like this:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/enforce-decree-read.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/enforce-decree-update.sh"
          }
        ]
      }
    ]
  }
}
```

### After setup

Every subsequent Claude Code session in the project will automatically:

1. **Read `.basalt/manifest.decree` before touching any code** — the `PreToolUse` hook blocks edits until the agent has read the manifest. The agent learns the full project topology before making changes.
2. **Drill into `spec.decree` and `body.decree` on demand** — the `CLAUDE.md` protocol tells the agent to read only the domains relevant to its current task, not the entire codebase.
3. **Update decree files after structural changes** — the `Stop` hook blocks the agent from finishing if it created new files without updating the corresponding `.decree` or `decisions.log`.

No manual intervention required. The hooks and `CLAUDE.md` work together to keep the agent aligned and the metadata current.
