# quarry

Spec-driven + QA scaffolding for agentic coding. A standalone Basalt-aligned tool
that generates a project skeleton: visible **specs** the agent reads, hidden
**tests** it cannot read, and a **QA harness** that reports per-spec pass/fail
verdicts — run by the architect or CI, never the agent.

## Philosophy

- **Specs = visible contract.** The agent reads them, plus `.decree` headers.
- **Tests = hidden verification.** The agent may not read `qa/hidden/` — enforced
  via generated permission configs (`.agent-guards/`), or by running the harness
  outside the agent's context for local-model flows.
- **The agent is disposable.** Invoked → task → gone (the "Meeseeks" model). No
  long self-correcting sessions; the architect is the feedback loop.
- **Verdicts, not internals.** `qa/run_qa.sh` emits per-spec pass/fail. Zero
  test bodies leak; the architect still locates failures in seconds.
- **Correlation.** `specs/<domain>/` must match `.basalt/<domain>/`. `quarry
  check` enforces it — the seam Basalt's future traceability tool will hook into.

See `docs/decisions/008-hidden-verification-qa.md` for the rationale.

## Usage

```bash
quarry init <project-dir> [--lang python] [--force]
quarry check <project-dir>
```

`init` copies `templates/` into the target, substituting `__PROJECT_NAME__`.
Existing files are skipped unless `--force`.

## What gets generated

```
<project>/
├── specs/
│   ├── 000-index.md          # spec ↔ decree-domain correlation index
│   ├── README.md             # how specs work here
│   └── _template/            # copy to specs/<domain>/: spec.md, plan.md, acceptance.feature
├── qa/
│   ├── policy.md             # coverage / mutation / verdict gates
│   ├── README.md
│   ├── run_qa.sh             # THE HARNESS — architect/CI only, never the agent
│   └── hidden/               # PROTECTED: agent deny-read
│       ├── conftest.py  pytest.ini  mutation.conf  README.md
│       ├── unit/  integration/  steps/  fixtures/   # tests as <suite>/<domain>/test_*.py
`── .agent-guards/            # deny-read configs to merge into your agent
    ├── opencode.json  claude-settings.json  README.md
```

**QA toolchain:** pytest + pytest-cov + pytest-bdd (gherkin) + mutmut (mutation).
Gherkin `.feature` files live in the visible `specs/<domain>/` (they *are* the
spec); step definitions live in `qa/hidden/`.

## Roadmap

- v0.1 (this): `init` + `check`, Python only, per-spec verdicts, mutmut config.
- v0.2: `quarry run` (wraps `run_qa.sh` with the visibility policy knob), coverage/mutation gate enforcement.
- v1.0: Basalt-component form (`basalt init-qa`), polyglot templates (Go, TS), correlation to the traceability tool.