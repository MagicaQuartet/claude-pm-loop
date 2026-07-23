#!/usr/bin/env bash
# Repo gate: structural checks + zero-coupling audit (spec §12.2).
# Grows with each milestone: append to required=() and add require_heading calls.
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0

# 1. Manifests exist and parse as JSON
for f in .claude-plugin/marketplace.json .claude-plugin/plugin.json; do
  if ! python3 -m json.tool "$f" >/dev/null 2>&1; then
    echo "FAIL: $f missing or invalid JSON"; fail=1
  fi
done

# 2. Required files (append as milestones land)
required=(
  README.md
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

for h in '^## Project' '^## VCS' '^## Quality gate' '^## Architecture map' '^## Security model' '^## Risk classes' '^## Compliance' '^## Tooling' '^## Planner research axes'; do
  require_heading templates/profile.md "$h"
done

for h in '^## Resume first' '^## Autonomy' '^## Plan docs' '^## Knowledge' '^## Loop' '^## Profile first'; do
  require_heading commands/pm-loop.md "$h"
done

for h in '^## Procedure' '^## Idempotency'; do
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
require_heading agents/compliance-reviewer.md '^## Mode'
require_heading agents/compliance-reviewer.md '^## Feasibility-triage mode'
require_heading agents/product-planner.md '^## Restraint'
require_heading agents/product-planner.md '^## Return-value contract'

for h in '^## Severity ladder' '^## Review tiers' '^## Comment output' '^## Reading the diff at the right ref' '^## Existing comments' '^## Approval'; do
  require_heading skills/reviewing-prs/SKILL.md "$h"
done

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

[ "$fail" -eq 0 ] && echo "OK: all checks passed"
exit "$fail"
