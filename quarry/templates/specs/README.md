# Specs — __PROJECT_NAME__

Specs are the VISIBLE contract. The agent reads them; it may not read `qa/hidden/`.

## Layout
```
specs/<domain>/
  spec.md            — what & why (business requirement)
  plan.md            — architect-owned technical plan
  acceptance.feature — gherkin acceptance criteria (visible: it IS the spec)
```
The `spec.md` front-matter:
```yaml
---
id: SPEC-000
domain: <domain>          # MUST match .basalt/<domain>/
decisions: []             # refs into decisions.log
status: draft | ready | done
---
```

## Correlation
`specs/<domain>/` must match `.basalt/<domain>/` (decree domain).
Run `quarry check` to verify — it errors on orphan specs or decree domains.

## Workflow
1. Architect writes `spec.md` + `acceptance.feature`.
2. Agent implements against the spec + `.decree` headers.
3. Architect / CI runs `qa/run_qa.sh` → per-spec verdict (no test internals).
4. On structural change, append `.basalt/<domain>/decisions.log`.