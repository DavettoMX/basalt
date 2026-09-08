#!/usr/bin/env bash
# run_qa.sh — Basalt QA harness. Run by ARCHITECT or CI, NEVER the agent.
# Emits per-spec pass/fail verdicts to qa/verdict.json + a one-line summary.
# Visibility policy: "full" by default (ADR-008) — the agent sees only verdicts.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$HERE/.." && pwd)"
HIDDEN="$HERE/hidden"
RESULTS="$HERE/results.xml"
VERDICT="$HERE/verdict.json"
VISIBILITY="${QA_VISIBILITY:-full}"   # full | summary | open

[ -d "$HIDDEN" ] || { echo "qa: no qa/hidden/ dir" >&2; exit 2; }
command -v pytest >/dev/null 2>&1 || {
  echo "qa: pytest not installed (pip install pytest pytest-cov pytest-bdd)" >&2
  exit 2
}

# For the 'open' policy the agent may read everything; we still run here.
# For 'full'/'summary' the deny configs in .agent-guards/ should already keep
# the agent out of qa/hidden — this script is just the judge.

cd "$HIDDEN"
export QA_PROJECT="$PROJECT" QA_HIDDEN="$HIDDEN" QA_RESULTS="$RESULTS"
export QA_VERDICT="$VERDICT" QA_VISIBILITY="$VISIBILITY"

RC=0
python -m pytest unit integration \
  --junit-xml="$RESULTS" \
  --rootdir="$HIDDEN" \
  --no-header -p no:cacheprovider -q > /dev/null 2>&1 || RC=$?

python - <<'PYEOF'
import json, os, re, sys, xml.etree.ElementTree as ET

project      = os.environ["QA_PROJECT"]
results      = os.environ["QA_RESULTS"]
verdict_path = os.environ["QA_VERDICT"]
visibility   = os.environ.get("QA_VISIBILITY", "full")
specs_dir    = os.path.join(project, "specs")

def spec_domains():
    if not os.path.isdir(specs_dir):
        return []
    return sorted(d for d in os.listdir(specs_dir)
                  if d and not d.startswith(("_", "."))
                  and os.path.isdir(os.path.join(specs_dir, d)))

verdict = {f"specs/{d}": "unverified" for d in spec_domains()}
tested  = set()

if os.path.exists(results):
    for tc in ET.parse(results).iter("testcase"):
        f = (tc.get("file") or tc.get("classname") or "").replace("\\", "/")
        m = re.search(r"(?:unit|integration)[/. ](\w+)", f)
        if not m:
            continue
        domain = m.group(1)
        tested.add(domain)
        key = f"specs/{domain}"
        cur = verdict.get(key)          # may be None if no spec dir exists
        failed = (tc.find("failure") is not None) or (tc.find("error") is not None)
        if cur == "fail":
            verdict[key] = "fail"
        elif failed:
            verdict[key] = "fail"
        elif cur is None:
            verdict[key] = "pass"
        elif cur == "pass":
            verdict[key] = "pass"
        # 'unverified' with passing tests -> pass
        elif cur == "unverified":
            verdict[key] = "pass"

with open(verdict_path, "w") as fh:
    json.dump(verdict, fh, indent=2, sort_keys=True)

n_pass = sum(1 for v in verdict.values() if v == "pass")
n_fail = sum(1 for v in verdict.values() if v == "fail")
n_unv  = sum(1 for v in verdict.values() if v == "unverified")

line = f"qa: PASS={n_pass} FAIL={n_fail} UNVERIFIED={n_unv}"
if n_fail:
    line += " | failed: " + ", ".join(k for k, v in verdict.items() if v == "fail")
print(line)

orphans = tested - set(spec_domains())
if orphans:
    print(f"qa: WARNING orphan tests (no matching spec): {sorted(orphans)}", file=sys.stderr)

sys.exit(1 if n_fail else 0)
PYEOF