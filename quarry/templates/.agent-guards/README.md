# .agent-guards — agent deny-read configs

These prevent the agent from reading `qa/hidden/` (test internals). Merge the
relevant snippet into your agent's config; the agent SHOULD still read `specs/`,
`.basalt/`, and `decisions.log`.

| File | Merge into | For |
|------|------------|-----|
| `opencode.json` | your opencode config | OpenCode |
| `claude-settings.json` | `.claude/settings.local.json` | Claude Code |

## llama.cpp / local models
There is no file-permission model. The guarantee comes from **physical
separation**: run `qa/run_qa.sh` from your own shell or CI — never hand the agent
the `qa/hidden/` path, and don't mount it into the agent's working context. The
harness stays the architect's tool, not the agent's.