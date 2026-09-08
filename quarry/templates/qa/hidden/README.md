# qa/hidden — PROTECTED (agent deny-read)

Place tests mirroring the spec domains:

```
unit/<domain>/test_*.py
integration/<domain>/test_*.py
steps/<domain>/test_steps.py      # pytest-bdd step defs (features live in specs/)
fixtures/<domain>/...
```

`<domain>` MUST match a `specs/<domain>/` directory. `run_qa.sh` aggregates
results per `<domain>` from the junit XML's `file`/`classname` attributes — no
markers required.

The agent MUST NOT read this directory. Enforcement:
- OpenCode / Claude Code: `.agent-guards/` deny configs (merge into agent config).
- llama.cpp / local models: run `run_qa.sh` from your shell or CI, outside the
  agent's mounted context (physical separation — the strongest guarantee).