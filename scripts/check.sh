#!/usr/bin/env bash
# Repo gate: structural checks + zero-coupling audit (spec §12.2).
# Grows with each milestone: append to required=() and add require_heading calls.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

# 1. Manifests exist and parse as JSON
for f in .claude-plugin/marketplace.json .claude-plugin/plugin.json hooks/hooks.json; do
  if ! python3 -m json.tool "$f" >/dev/null 2>&1; then
    echo "FAIL: $f missing or invalid JSON"; fail=1
  fi
done

# 2. Required files (append as milestones land)
required=(
  README.md
  hooks/hooks.json
  scripts/merge-gate-hook.sh
  commands/pm-loop.md
  commands/pm-loop-init.md
  templates/profile.md
  templates/knowledge/invariants/README.md
  templates/knowledge/gotchas/README.md
  templates/knowledge/domain/README.md
  templates/knowledge/decisions.md
  templates/knowledge/team-learnings.md
  templates/findings/index.md
  templates/rubric/code-review.md
  templates/rubric/security.md
  templates/rubric/compliance.md
  agents/implementer.md
  agents/pr-reviewer.md
  agents/security-reviewer.md
  agents/compliance-reviewer.md
  agents/product-planner.md
  skills/reviewing-prs/SKILL.md
  skills/reviewing-prs/code-review.md
  skills/reviewing-prs/security.md
  skills/reviewing-prs/compliance.md
  skills/reviewing-prs/product-ethics.md
  templates/rubric/product-ethics.md
)
for f in "${required[@]}"; do
  [ -f "$f" ] || { echo "FAIL: missing required file $f"; fail=1; }
done

# 3. Zero-coupling audit — shipped plugin content must be project-agnostic.
#    docs/ and README.md are exempt (may describe the extraction origin as labeled examples).
pattern='supabase|drizzle|\brls\b|\bbun\b|\bbunx\b|src/app/api|src/db/schema'
if grep -rinE "$pattern" commands agents skills templates 2>/dev/null; then
  echo "FAIL: project-specific token found in plugin content (see above)"; fail=1
fi

# 4. Required headings per doc (append as docs land)
require_heading() { # file, extended-regex
  grep -qE "$2" "$1" 2>/dev/null || { echo "FAIL: $1 missing /$2/"; fail=1; }
}

for h in '^## Project' '^## VCS' '^## Quality gate' '^## Architecture map' '^## Security model' '^## Risk classes' '^## Compliance' '^## Tooling' '^## Planner research axes' '^## Review diversity'; do
  require_heading templates/profile.md "$h"
done

for h in '^## Resume first' '^## Autonomy' '^## Plan docs' '^## Knowledge' '^## Loop' '^## Profile first'; do
  require_heading commands/pm-loop.md "$h"
done

for h in '^## Procedure' '^## Quick setup' '^## Idempotency'; do
  require_heading commands/pm-loop-init.md "$h"
done

for f in agents/implementer.md agents/pr-reviewer.md agents/security-reviewer.md; do
  require_heading "$f" '^\*\*Untrusted content:\*\*'
  require_heading "$f" '^## `## KNOWLEDGE` return block'
done
require_heading agents/implementer.md '^## Address-review mode'
for f in agents/pr-reviewer.md agents/security-reviewer.md; do
  require_heading "$f" '^## Feasibility-triage mode'
done
require_heading agents/pr-reviewer.md '^## Lens assignment'
require_heading agents/compliance-reviewer.md '^## Mode'
require_heading agents/compliance-reviewer.md '^## Feasibility-triage mode'
require_heading agents/product-planner.md '^## Restraint'
require_heading agents/product-planner.md '^## Return-value contract'

for h in '^## Severity ladder' '^## Review tiers' '^## Re-review scope' '^## Lens assignment' '^## Adversarial pass' '^## Product ethics' '^## Comment output' '^## Reading the diff at the right ref' '^## Existing comments' '^## Approval'; do
  require_heading skills/reviewing-prs/SKILL.md "$h"
done

for h in '^## What counts' '^## Two-tier response' '^## For reviewers'; do
  require_heading skills/reviewing-prs/product-ethics.md "$h"
done

# product-ethics doctrine stays lean — every role that reads it pays for its length (spec D29)
if [ -f skills/reviewing-prs/product-ethics.md ]; then
  pe_words=$(wc -w < skills/reviewing-prs/product-ethics.md | tr -d ' ')
  [ "$pe_words" -le 550 ] || { echo "FAIL: product-ethics.md is $pe_words words (budget <=550)"; fail=1; }
else
  echo "FAIL: skills/reviewing-prs/product-ethics.md missing (word-count check)"; fail=1
fi

# 5. Cross-file consistency
# 5a. Loop routes knowledge to every canonical consumer store
for p in '.claude/pm/knowledge/invariants/' '.claude/pm/findings/' '.claude/pm/knowledge/gotchas/' '.claude/pm/knowledge/decisions.md' '.claude/pm/knowledge/domain/' '.claude/pm/plans/' '.claude/pm/profile.md'; do
  grep -qF "$p" commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference $p"; fail=1; }
done
# 5b. Every agent carries the inlined safety paragraph and KNOWLEDGE contract
for f in agents/*.md; do
  grep -qF '**Untrusted content:**' "$f" || { echo "FAIL: $f missing safety paragraph"; fail=1; }
  grep -qF '## KNOWLEDGE' "$f" || { echo "FAIL: $f missing KNOWLEDGE contract"; fail=1; }
done
# 5c. Profile headings referenced by docs actually exist in the template
for h in '## Quality gate' '## Risk classes' '## Compliance' '## Security model' '## VCS'; do
  grep -qF "$h" templates/profile.md || { echo "FAIL: profile template lost '$h'"; fail=1; }
done
# 5d. Command names never drift back to bare /pm
#     (must not match /pm-loop, nor the .claude/pm/ path convention — hence:
#      no letter or / before the slash; no -, /, or letter after "pm")
if grep -rnE '(^|[^a-zA-Z/])/pm([^-/a-zA-Z]|$)' commands agents skills templates 2>/dev/null; then
  echo "FAIL: bare /pm reference found (must be /pm-loop)"; fail=1
fi
# 5e. W2: light tier + delta-scoped re-review are wired across files
grep -qF 'Light tier' skills/reviewing-prs/SKILL.md || { echo "FAIL: SKILL.md missing Light tier"; fail=1; }
grep -qF 'Light tier' templates/profile.md || { echo "FAIL: profile template missing Light tier line"; fail=1; }
grep -qF 'Re-review scope' commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference Re-review scope"; fail=1; }
# 5f. W3a: lens + adversarial pass are wired across files
grep -qF 'Lens assignment' commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference Lens assignment"; fail=1; }
grep -qF 'Adversarial pass' commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference Adversarial pass"; fail=1; }
# 5g. W3b: model-mix knob wired
grep -qF 'Review diversity' commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference Review diversity"; fail=1; }
# 5h. W4a: knowledge triage is mechanical
grep -qF 'Category test' commands/pm-loop.md || { echo "FAIL: pm-loop.md missing Category test"; fail=1; }
grep -qF 'Verified pointer' commands/pm-loop.md || { echo "FAIL: pm-loop.md missing Verified pointer"; fail=1; }
# 5i. plugin.json and marketplace.json advertise the same version
pv=$(python3 -c 'import json;print(json.load(open(".claude-plugin/plugin.json"))["version"])' 2>/dev/null)
mv=$(python3 -c 'import json,sys;d=json.load(open(".claude-plugin/marketplace.json"));print(d["plugins"][0]["version"])' 2>/dev/null)
[ -n "$pv" ] && [ "$pv" = "$mv" ] || { echo "FAIL: plugin.json version ($pv) != marketplace.json version ($mv)"; fail=1; }
# 5j. Product-ethics guardrail: reviewer detection wired
grep -qF 'product-ethics' agents/pr-reviewer.md || { echo "FAIL: pr-reviewer.md does not reference product-ethics"; fail=1; }
grep -qF 'product-ethics' commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference product-ethics"; fail=1; }
grep -qF 'product-ethics' agents/product-planner.md || { echo "FAIL: product-planner.md does not reference product-ethics"; fail=1; }
grep -qF 'product-ethics' agents/implementer.md || { echo "FAIL: implementer.md does not reference product-ethics"; fail=1; }

# 6. Merge-gate hook: syntax, executability, manifest wiring, smoke tests (spec §4, §11.2)
if [ -f scripts/merge-gate-hook.sh ]; then
  bash -n scripts/merge-gate-hook.sh || { echo "FAIL: merge-gate-hook.sh does not parse"; fail=1; }
  [ -x scripts/merge-gate-hook.sh ] || { echo "FAIL: merge-gate-hook.sh not executable"; fail=1; }
  grep -qF 'merge-gate-hook.sh' hooks/hooks.json 2>/dev/null || { echo "FAIL: hooks.json does not reference merge-gate-hook.sh"; fail=1; }
  hook="$PWD/scripts/merge-gate-hook.sh"
  smoke=$(mktemp -d); mkdir -p "$smoke/.claude/pm" "$smoke/sub"; : > "$smoke/.claude/pm/profile.md"
  git -C "$smoke" init -q
  out=$(cd "$smoke/sub" && echo '{"tool_input":{"command":"gh pr merge 12 --squash --delete-branch"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on gh pr merge"; fail=1; }
  echo "$out" | grep -qF '"permissionDecision": "ask"' || { echo "FAIL: hook did not ask on gh pr merge"; fail=1; }
  out=$(cd "$smoke" && echo '{"tool_input":{"command":"gh api repos/o/r/pulls/12/merge -X PUT"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on gh api pulls merge"; fail=1; }
  echo "$out" | grep -qF '"permissionDecision": "ask"' || { echo "FAIL: hook did not ask on gh api pulls merge"; fail=1; }
  out=$(cd "$smoke" && echo '{"tool_input":{"command":"git push --force origin feature"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on force push"; fail=1; }
  echo "$out" | grep -qF '"permissionDecision": "ask"' || { echo "FAIL: hook did not ask on force push"; fail=1; }
  out=$(cd "$smoke" && echo '{"tool_input":{"command":"git push --force-with-lease origin feature"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on force-with-lease push"; fail=1; }
  echo "$out" | grep -qF '"permissionDecision": "ask"' || { echo "FAIL: hook did not ask on force-with-lease push"; fail=1; }
  out=$(cd "$smoke" && echo '{"tool_input":{"command":"git push -f origin feature"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on -f push"; fail=1; }
  echo "$out" | grep -qF '"permissionDecision": "ask"' || { echo "FAIL: hook did not ask on -f push"; fail=1; }
  out=$(cd "$smoke" && echo '{"tool_input":{"command":"git push origin feature"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on plain push"; fail=1; }
  [ -z "$out" ] || { echo "FAIL: hook opined on a plain push"; fail=1; }
  out=$(cd "$smoke" && echo '{"tool_input":{"command":"ls -la"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on benign command"; fail=1; }
  [ -z "$out" ] || { echo "FAIL: hook opined on a benign command"; fail=1; }
  out=$(cd "$smoke" && echo 'not json' | "$hook" 2>"$smoke/stderr.txt"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero on bad JSON"; fail=1; }
  [ -z "$out" ] || { echo "FAIL: hook did not fail open on bad JSON"; fail=1; }
  [ -s "$smoke/stderr.txt" ] || { echo "FAIL: hook printed no stderr warning on bad JSON"; fail=1; }
  noprofile=$(mktemp -d)
  out=$(cd "$noprofile" && echo '{"tool_input":{"command":"gh pr merge 12"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero outside a pm-loop repo"; fail=1; }
  [ -z "$out" ] || { echo "FAIL: hook opined outside a pm-loop repo"; fail=1; }
  nongit=$(mktemp -d); mkdir -p "$nongit/.claude/pm"; : > "$nongit/.claude/pm/profile.md"
  out=$(cd "$nongit" && echo '{"tool_input":{"command":"gh pr merge 12"}}' | "$hook"); rc=$?
  [ "$rc" -eq 0 ] || { echo "FAIL: hook exited non-zero via non-git fallback"; fail=1; }
  echo "$out" | grep -qF '"permissionDecision": "ask"' || { echo "FAIL: hook did not ask via non-git fallback"; fail=1; }
  rm -rf "$smoke" "$noprofile" "$nongit"
else
  echo "FAIL: scripts/merge-gate-hook.sh missing (section 6)"; fail=1
fi

[ "$fail" -eq 0 ] && echo "OK: all checks passed"
exit "$fail"
