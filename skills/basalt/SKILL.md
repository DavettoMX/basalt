---
name: basalt
description: >
  This skill should be used when the user asks to "generate codebase metadata",
  "create .basalt directory", "map project architecture", "run basalt",
  "analyze codebase structure", "generate decree files", or mentions
  "basalt" or ".decree" in the context of project documentation.
  Scans the project, identifies domains (schemas, APIs, services), and
  generates compressed .decree metadata files optimized for AI token consumption.
---

# Basalt: AI-Optimized Codebase Metadata Generator

Basalt generates compressed `.decree` metadata files from source code. The `.basalt/` directory acts as a navigation layer for AI agents — like C++ headers, but for LLMs. Agents read the manifest first, then drill into specific domains on demand, saving tokens and preserving design context.

## Step 1 — Detect Project Type

Glob for ecosystem markers in the project root:

| Marker | Ecosystem |
|--------|-----------|
| `package.json` | Node.js / TypeScript |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pyproject.toml`, `requirements.txt`, `setup.py` | Python |
| `pom.xml`, `build.gradle` | Java / Kotlin |
| `mix.exs` | Elixir |
| `Gemfile` | Ruby |

Read the first marker found to extract project name and version. If no marker is found, use the directory name as the project name and `0.1.0` as version.

## Step 1.5 — Load Ecosystem Packages

**You MUST complete this step before proceeding to Step 2.** Do not rely on training knowledge for detection patterns — use the ecosystem packages.

1. Read `ecosystems/_index.md` (relative to this skill's directory)
2. Look up the detected markers in the table to identify which package file(s) to load
3. Glob for `**/*.proto` and `**/openapi.{yaml,yml,json}` in the project — if found, also load `cross-cutting.md`
4. Read ALL matching package files in a **single parallel batch**

For polyglot projects (multiple markers), load all matching packages. The packages contain the detection patterns and extraction rules needed for Steps 2-3.

## Step 2 — Discover Domains

Use the detection patterns from the loaded ecosystem package(s) to scan for domain sources. Each package defines patterns for: Database/Schema, API/Routes, Frontend/UI, State Management, and Application/Business Logic.

**Feature-based detection override:** If the project organizes by feature (directories that contain both model AND route files — e.g., `src/users/model.ts` + `src/users/routes.ts`), use feature directories as domain names instead of layer-based grouping. Convert to snake_case: `users/` → `user_management`, `orders/` → `order_processing`, `products/` → `product_catalog`.

If no sources are found in a category, skip that domain entirely.

## Step 3 — Generate .basalt/

Create the `.basalt/` directory in the project root. Refer to `references/format-spec.md` for the exact syntax of each file type.

### Generation Order

1. **Read all discovered source files** from Step 2
2. **Root `manifest.decree`** — List project name, version, engine, and all domains with their public/private entities and dependencies
3. **For each domain directory:**
   - `manifest.decree` — Domain-specific map (for database: entity list; for API: route groups)
   - `spec.decree` — Compressed structural contract following the symbol notation
   - `body.decree` — Behavioral context and business rules — implementation details not captured by the structural spec. Free-form markdown, not a DSL. See `references/format-spec.md` for format and examples.
   - `decisions.log` — **Append-only.** If the file already exists, read its current content and only add new entries below. Never truncate or overwrite existing entries. Detect design decisions from **architectural patterns in code** (search service files, not just schemas):
       - `$transaction` / `transaction(` → document atomicity decisions
       - `httpOnly` / `cookie` / `sameSite` → document auth storage decisions
       - Fields stored as JSON strings instead of relations → document denormalization
       - Unique constraints on compound fields → document why the combination matters
       - Enum mappings or value transformations → document the mapping rationale
       - `@default` values that aren't obvious (not `now`, `true`, `0`) → document why that default
     - Before adding an entry, check if a decision for the same `domain/Entity.field` already exists in the log. If it does, skip it — do not duplicate or rephrase existing entries.
     - **Do NOT** scan for or depend on code comments (`// WHY:`, `// PERF:`, `// HACK:`, `// NOTE:`, `// TODO:`). Do NOT add `$why:` annotations to any generated `.decree` file. Do NOT add any comments to the user's source code.
     - If no new decisions are found, leave the file as-is (or empty if it didn't exist). No placeholder text.
4. **Root `decisions.log`** — Same append-only rules. Aggregate the most critical new decisions across domains. Never truncate existing entries.

### Universal Extraction Rules for spec.decree

These type mappings apply across all ecosystems:

- Map source types to decree type codes: `String/VARCHAR/text` → `s`, `Int/INTEGER` → `i`, `Float/DECIMAL/REAL` → `f`, `Boolean` → `b`, `DateTime/TIMESTAMP` → `t`, `UUID/CUID` → `u`, `JSON/JSONB` → `j`
- Map `@id`/`PRIMARY KEY` → `!` suffix
- Map nullable/optional fields → `?` prefix
- Map `@default(...)` → `=val`
- Map `@relation`/`REFERENCES`/foreign keys → `->Entity.field`
- Map `@@index`/`CREATE INDEX` → `#[fields]`
- Map `@unique`/`UNIQUE` → `@unique`
- Detect sensitive fields by name pattern: `password`, `token`, `secret`, `api_key`, `ssn`, `credit_card` → `@sens`

For API domains:
- Map HTTP methods directly: `GET`, `POST`, `PUT`, `PATCH`, `DEL`
- Map route paths preserving params: `/users/:id`, `/orders`
- Map request body/params → `>fields`
- Map response types → `->Entity` or `->Entity[]`
- Detect auth middleware → `@auth`
- Detect role guards → `@role(name)`

For Application domains:
- Map classes/structs with data fields → `+Entity` with fields
- Map enums → `+EnumName : val1,val2,val3`
- Map service/orchestrator classes → `+ClassName` with `.method(params) ->return` declarations
- Map important constants → `K NAME type =value`
- Only include **public methods** that define the service's contract — skip internal helpers
- Dependencies on other domains → `>domain::Entity` forward declarations

**Framework-specific extraction rules** are in the loaded ecosystem package(s).

### Extraction Rules for body.decree

body.decree captures **behavioral context not present in the spec**. Format: free-form markdown with `## Name` headers. One body.decree per domain.

- **Database:** cascade/delete behavior, state machine transitions, computed fields, encryption/hashing, non-obvious validation
- **API:** auth mechanism details, transaction boundaries, side effects (emails, webhooks), error handling patterns, rate limiting
- **Application:** orchestration flow, external service integration, business rules/thresholds, error handling, caching strategies
- **Frontend:** rendering implementation details, data transformation utilities, fallback/placeholder patterns, auth flow, SSR/SSG hydration

**Rules:**
- Only include behavior that **cannot be inferred from spec.decree alone**
- Reference source file paths when useful: `(src/path/file.ts)`
- Do not duplicate information already in spec (fields, types, constraints)
- Do not duplicate information already in decisions.log (dated design rationale)
- Keep each entry to 2-4 lines. Be concise — the goal is to save the agent from reading source, not to replace it

## Step 4 — Validate

After generating all files, verify:

1. Every `->Entity.field` reference in spec files points to an entity that exists in some domain
2. Every domain listed in the root manifest has a corresponding directory in `.basalt/`
3. Every `>domain::Entity` import references a domain that exists
4. No empty spec files (if a domain has no entities or routes, remove it)
5. Every `<<group.METHOD path` in frontend spec references a route that exists in the api domain
6. Every `{Component}` reference in a page or component matches a `C` declaration in the same frontend spec
7. Every `~Store` reference matches a `~` declaration in the same frontend spec
8. Every `C ComponentName` declaration in frontend spec must correspond to an actual component file in the source. Glob for the component name in `components/` directories — if no matching file exists, remove the `C` declaration and all `{ComponentName}` references to it
9. Every claim in body.decree must be verifiable against source code. After writing body.decree, re-read the relevant source files and cross-check: field counts, array sizes, specific values (e.g., number of gradient variants), and utility function signatures. Correct any discrepancies before finalizing
10. The root manifest `F` line must list only components and pages that passed validation in rules 6-8

Report validation errors to the user. Fix what can be fixed automatically, flag the rest.

## Step 5 — Configure CLAUDE.md

After generating `.basalt/`, ensure the project's `CLAUDE.md` instructs future Claude instances to use basalt.

**If `CLAUDE.md` does not exist:** Create it with the basalt section.

**If `CLAUDE.md` already exists:** Append the basalt section at the end, only if it does not already contain a basalt reference.

The basalt section to add:

```markdown
## Basalt

This project uses Basalt for AI-optimized codebase metadata. The `.basalt/` directory contains `.decree` files that describe the full architecture — schemas, APIs, frontend, behavior, and design decisions. These files are the source of truth for understanding the codebase.

**Answering questions:**
1. Read `.basalt/manifest.decree` to identify which domains are relevant to the question.
2. Read ALL relevant `spec.decree` and `body.decree` files **in a single parallel batch** — do not read one, think, then read another. One round of reads, then answer.
3. Answer directly from their content. Do NOT explore source files to supplement or verify decree content.

**When to read body.decree:** Only when the question is about *how* something works or behaves, not *what* exists. For "what" questions, spec.decree is sufficient.
**When to read decisions.log:** Only when the question is about *why* a design choice was made.

**When to read source files:** Only when you need to *modify* code, or when the manifest has no domain covering the topic asked about. Use spec.decree to know WHICH file to open. Never read source files to supplement, verify, or expand on information that the decrees already cover.

**CRITICAL — Before modifying code:**
1. MUST read `.basalt/manifest.decree` FIRST to understand the project architecture.
2. MUST read the `spec.decree` of every domain you will touch BEFORE writing any code.
3. Do NOT skip this step. Do NOT go straight to source files. The decree files exist so you understand the architecture before changing it.

**CRITICAL — After making structural changes:**
If you create new files, new endpoints, new entities, new tools, new domains, or change schemas/relationships, you MUST update the decree files BEFORE finishing your response:

1. Update `spec.decree` — add/modify the structural contract for what changed.
2. Update `body.decree` — add/modify behavioral context if the change affects how things work.
3. Append to `decisions.log`:
   `<YYYY-MM-DD> <domain>/<Entity>.<field> "<what changed and why>"`
4. If you created a new domain directory, create its `.basalt/<domain>/` with all four files (manifest.decree, spec.decree, body.decree, decisions.log) AND update the root `manifest.decree`.

Do NOT treat documentation as optional. Do NOT plan to "do it later". Update decree files as part of the same task, not as a separate step.

**What NOT to log in decisions.log:** typo fixes, copy/text changes, style adjustments, dependency bumps without breaking changes, or formatting. Only log changes that affect codebase architecture.
```

## Step 6 — Report

Print a summary:

```
.basalt/ generated:
  Domains: 3 (database, api, frontend)
  Entities: 12 public, 2 private
  API routes: 15
  Pages: 8, Components: 12, Stores: 3
  Decisions captured: 4
  Token estimate: ~480 (vs ~3500 reading source files directly)
  CLAUDE.md: updated ✓
```

## Step 7 — Save Memory

After generating `.basalt/`, save a feedback memory to the project's memory directory so future conversations remember to follow the basalt workflow. Write the following file to the project's memory path (`~/.claude/projects/<project-key>/memory/feedback_basalt_docs.md`):

```markdown
---
name: Always document in basalt
description: NEVER skip basalt decree documentation when making structural changes — create spec.decree, body.decree, decisions.log for new domains
type: feedback
---

ALWAYS create and update basalt decree files when making structural changes. This includes:
- New domains → create directory + spec.decree + body.decree + manifest.decree + decisions.log
- New API endpoints → update api/spec.decree
- New tools → update tools/spec.decree
- New frontend components → update or create frontend decree files
- Architecture decisions → append to relevant decisions.log

**Why:** The CLAUDE.md explicitly says decree files are the source of truth. Skipping them means future conversations can't understand the architecture without reading all source files. The user was very clear: the instructions exist for a reason and must be followed exactly.

**How to apply:** Before finishing any task that adds new files, endpoints, schemas, or domains, verify that all relevant decree files are created/updated. Do this DURING implementation, not as an afterthought.
```

Then add a pointer to it in the project's `MEMORY.md`. If `MEMORY.md` doesn't exist, create it. If a `feedback_basalt_docs.md` entry already exists, skip this step.

## Step 8 — Generate Enforcement Hooks

Create `.claude/hooks/` in the project and register them in `.claude/settings.json` to mechanically enforce the basalt workflow. If `.claude/settings.json` already exists, merge the `hooks` key into it without overwriting other settings.

**Hook 1 — `enforce-decree-read.sh` (PreToolUse on Edit|Write):**

Blocks edits to project source files if `manifest.decree` has not been read in the current session transcript.

- If editing inside `.basalt/` or `CLAUDE.md` → allow (updating docs)
- If editing outside the project directory → allow (not our concern)
- If no transcript available → allow
- Otherwise → check transcript for `manifest.decree` read. If missing → exit 2 with message telling the model to read the manifest and relevant decree files first.

**Hook 2 — `enforce-decree-update.sh` (Stop):**

When the model finishes responding, check if it created new source files (Write tool to project paths outside `.basalt/`) without touching any `.decree` or `decisions.log` file.

- If new source files were created AND no decree/decisions.log was written/edited → exit 2 with message telling the model to update the relevant decree files before finishing.
- Otherwise → allow.

**settings.json hooks config:**

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

Make both scripts executable (`chmod +x`).

## Important Rules

- **Never fabricate** entities, fields, or relationships not found in source code
- **Never add `$why:` to generated `.decree` files** — design decisions belong exclusively in `decisions.log`, not inline in specs
- **Never scan for or depend on code comments** (`// WHY:`, `// PERF:`, `// HACK:`, `// NOTE:`, `// TODO:`) — these are developer notes, not basalt input
- **Never add comments to the user's source code** — basalt only writes to `.basalt/`
- **Skip empty domains** — if no database schemas found, do not create a `database/` directory
- **Preserve naming** — use the entity/model names as they appear in code, converted to PascalCase for entities
- **One source of truth** — the `.decree` files describe what exists in code, nothing more
- **Idempotent specs** — running basalt again on the same codebase produces the same manifest, spec, and body output
- **Append-only decisions** — `decisions.log` is never truncated; new entries are appended, existing ones are preserved

## Additional Resources

### Reference Files

For exact syntax and grammar:
- **`references/format-spec.md`** — Complete .decree format specification with grammar rules and symbol table

### Ecosystem Packages

Language/framework-specific detection patterns and extraction rules:
- **`ecosystems/_index.md`** — Package registry (marker → package mapping)
- **`ecosystems/python.md`** — SQLAlchemy, FastAPI, Django, application domains
- **`ecosystems/node-typescript.md`** — Prisma, TypeORM, Express, Next.js, React, Vue, Svelte, Angular
- **`ecosystems/go.md`** — GORM, SQLx, Gin, Chi, Echo
- **`ecosystems/rust.md`** — Diesel, SQLx, Actix, Axum
- **`ecosystems/java-kotlin.md`** — JPA/Hibernate, Spring, JAX-RS
- **`ecosystems/ruby.md`** — ActiveRecord, Rails, Sinatra
- **`ecosystems/elixir.md`** — Ecto, Phoenix
- **`ecosystems/cross-cutting.md`** — OpenAPI, gRPC/Protobuf
