# Basalt Ecosystem Packages

After detecting ecosystem markers in Step 1, look up the matching package(s) in this table and Read them before proceeding to Step 2.

| Marker | Package |
|--------|---------|
| `package.json` | `node-typescript.md` |
| `go.mod` | `go.md` |
| `Cargo.toml` | `rust.md` |
| `pyproject.toml` | `python.md` |
| `requirements.txt` | `python.md` |
| `setup.py` | `python.md` |
| `pom.xml` | `java-kotlin.md` |
| `build.gradle` | `java-kotlin.md` |
| `mix.exs` | `elixir.md` |
| `Gemfile` | `ruby.md` |

**Cross-cutting:** Also load `cross-cutting.md` if any `**/*.proto` or `**/openapi.{yaml,yml,json}` files exist in the project.

**Polyglot projects:** Load all matching packages. For example, a project with both `package.json` and `go.mod` loads both `node-typescript.md` and `go.md`.

**No markers found:** If no ecosystem marker is detected, do not load any package. Use only the core extraction rules in SKILL.md and scan for raw `.sql` files or other agnostic sources.
