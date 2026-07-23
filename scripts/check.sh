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
  commands/pm-loop.md
  commands/pm-loop-init.md
)
for f in "${required[@]}"; do
  [ -f "$f" ] || { echo "FAIL: missing required file $f"; fail=1; }
done

# 3. Zero-coupling audit — shipped plugin content must be project-agnostic.
#    docs/ and README.md are exempt (may cite SourceApp as labeled examples).
pattern='supabase|drizzle|\brls\b|\bbun\b|\bbunx\b|src/app/api|src/db/schema'
if grep -rinE "$pattern" commands agents skills templates 2>/dev/null; then
  echo "FAIL: project-specific token found in plugin content (see above)"; fail=1
fi

# 4. Required headings per doc (append as docs land)
require_heading() { # file, extended-regex
  grep -qE "$2" "$1" 2>/dev/null || { echo "FAIL: $1 missing /$2/"; fail=1; }
}

[ "$fail" -eq 0 ] && echo "OK: all checks passed"
exit "$fail"
