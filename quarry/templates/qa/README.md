# qa — verification layer for __PROJECT_NAME__

`qa/run_qa.sh` is THE HARNESS. **Run it yourself or in CI — never let the agent
invoke it**, and the agent must never read `qa/hidden/`.

```
qa/
├── policy.md     gates + verdict model + visibility policy
├── run_qa.sh     the harness: pytest -> per-spec verdict.json + summary
├── results.xml   generated (gitignore me)
├── verdict.json  generated (gitignore me)
└── hidden/       PROTECTED — agent deny-read
    ├── conftest.py     adds project root to sys.path
    ├── pytest.ini      testpaths, gherkin feature base dir = ../../specs
    ├── mutation.conf   mutmut config (merge into pyproject.toml)
    ├── unit/<domain>/test_*.py
    ├── integration/<domain>/test_*.py
    ├── steps/<domain>/test_steps.py   (pytest-bdd; features live in specs/)
    └── fixtures/<domain>/
```

## Test-to-spec convention
Tests live at `qa/hidden/<suite>/<domain>/test_*.py`. `<domain>` must match a
`specs/<domain>/` directory. `run_qa.sh` aggregates results per `<domain>` from
the junit XML's `file`/`classname` attributes — no markers needed.

## Install
```bash
pip install pytest pytest-cov pytest-bdd mutmut
```
Add `qa/results.xml` and `qa/verdict.json` to your `.gitignore`.