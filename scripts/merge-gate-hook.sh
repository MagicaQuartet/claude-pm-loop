#!/usr/bin/env bash
# pm-loop merge gate (PreToolUse / Bash): forces a harness "ask" prompt when a
# merge or history-rewriting push actually runs in a pm-loop-managed repo.
# Defense-in-depth, not a security boundary (spec D13): pattern-matched, and it
# FAILS OPEN — any internal error exits 0 with no stdout so a broken hook can
# never brick Bash. The prose merge gate in commands/pm-loop.md stays primary.
set -u

# Scope: only repos that opted into pm-loop (spec D12).
root="$(git rev-parse --show-toplevel 2>/dev/null)" || root="$PWD"
[ -f "$root/.claude/pm/profile.md" ] || exit 0

command -v python3 >/dev/null 2>&1 || exit 0

python3 -c '
import json, re, sys

try:
    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
except Exception:
    print("merge-gate-hook: unparseable hook input - failing open", file=sys.stderr)
    sys.exit(0)
if not isinstance(cmd, str):
    sys.exit(0)

gated = None
if re.search(r"\bgh\s+pr\s+merge\b", cmd):
    gated = "gh pr merge"
elif re.search(r"\bgh\s+api\b", cmd) and re.search(r"pulls/\d+/merge", cmd):
    gated = "gh api .../pulls/<n>/merge"
elif re.search(r"\bgit\s+push\b", cmd) and re.search(r"(\s--force(-with-lease)?\b|\s-f\b)", cmd):
    gated = "git push --force"

if gated:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": "pm-loop merge gate: %s - human approval required at execution time" % gated,
        }
    }))
sys.exit(0)
' || exit 0
exit 0
