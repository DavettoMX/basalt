# QA Policy — __PROJECT_NAME__

## Gates (defaults — adjust to taste)
| Gate | Default | Tool |
|------|---------|------|
| Coverage | >= 80% | pytest-cov |
| Mutation | >= 60% | mutmut |
| Acceptance | all gherkin scenarios pass | pytest-bdd |

## Verdict model
- `qa/run_qa.sh` emits **per-spec** pass/fail to `qa/verdict.json` (no test internals).
- A spec with no tests yet is `unverified` (NOT a failure).
- Exit code: `0` = all pass, `1` = any spec failed.
- Deterministic: fixed seeds, no network. Keep it < 30s for small projects.

## Visibility policy (ADR-008)
- `full` (default) — agent sees only the per-spec verdict. Test bodies, steps, and
  fixtures are agent deny-read. This is the recommended setting.
- `summary` — per-spec verdict + failing scenario names (still no assertions).
- `open` — agent may read tests (TDD red-green). Use only for multi-agent / tutor scenarios.

Adjust by editing `run_qa.sh`. Default `full`; change only if you accept the gaming surface.

## Agent boundaries
| Path | Agent may read |
|------|----------------|
| `specs/`, `.basalt/`, `decisions.log` | yes |
| `qa/hidden/**` | **no** — enforced via `.agent-guards/` (OpenCode/Claude Code) or physical separation (local models) |