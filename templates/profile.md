# pm-loop Project Profile

The single source of project truth for the pm-loop plugin. Every pm-loop agent
reads this file first and assumes NOTHING not written here. Keep it lean —
every dispatched agent pays for these tokens.

## Project

_Required._ One line: what this project is. Then the hard constraints agents
must honor (e.g. "production-grade, not a prototype"; performance floors;
target platforms).

<!-- e.g.: AcmeCLI is a Go CLI for X. Production-grade; supports macOS+Linux. -->

## VCS

_Required._
- Base branch (work branches off it, PRs merge into it): <!-- e.g. main -->
- Merge style: squash (fixed in v1 — the loop's merge procedure always squash-merges).
- Branch naming: <!-- e.g. <type>/issue-<n> -->
- Commit & PR title format: <!-- e.g. gitmoji `<emoji>: [<scope>] <title>`, English -->
- PR body conventions (optional): <!-- e.g. required sections; leave out if none -->

## Quality gate

_Required._ The literal commands an implementer runs before opening a PR, in
order, each marked blocking or advisory. Agents run EXACTLY this list — they
never guess a toolchain.

<!-- e.g.:
1. `make lint` — blocking
2. `make test` — blocking
3. `make build` — advisory (run when build output is affected)
-->

## Architecture map

_Optional (delete the placeholder if you declare nothing)._ Free-form
structural landmarks: where routes/handlers, schema, entry points, or modules
live. An empty map is valid — agents then orient by exploring, at some token
cost.

## Security model

_Optional._ Where authorization is enforced; any privileged
connection/bypass situation; or `n/a` (e.g. a library with no auth surface).
Drives the implementer's basic self-check and the security org's focus.

- Named sensitive flows (money movement, settlement, account deletion, …), if any: <!-- list them — several review rules key on these -->

## Risk classes

_Required (the list may be empty, but say so explicitly)._ Named classes of
risky change that scale review. Path globs are optional — keyword-only
classes are valid; `tests-required` is optional and defaults to no. Format,
one per class:

- `<class-name>`: paths [<globs or —>], keywords [<terms>] → code-reviewers <n>, security [yes/no], compliance [yes/no], tests-required [yes/no]

<!-- e.g.:
- `payment`: paths [internal/billing/**], keywords [charge, refund, settle] → code-reviewers 3, security yes, compliance yes, tests-required yes
- `auth`: paths [—], keywords [login, session, token, permission] → code-reviewers 3, security yes, compliance no
-->

Baseline when no class matches: 2 code-reviewers, security 1, compliance per
its mode below. Operational-docs globs (files that govern this loop and thus
never count as "docs-only"): <!-- e.g. .claude/pm/** — add your own -->

## Compliance

_Required._
- Mode: <!-- full | minimal | off -->
  - `full` — compliance-reviewer runs whenever a risk class with `compliance yes` matches.
  - `minimal` — one token-frugal pass, only on the highest-risk classes, as judged by the PM from the profile's classes, or explicit request.
  - `off` — never dispatched; the loop records the skip.
- Domains (scope the rubric; required unless mode is off): <!-- e.g. GDPR, PCI-DSS -->

## Tooling

_Required._
- Issue tracker: GitHub Issues via `gh` (the only supported host in v1).
- Issue templates: <!-- path, e.g. .github/ISSUE_TEMPLATE/, or "none" -->
- Labels/conventions: <!-- e.g. feat/fix labels; or "none" -->

## Planner research axes

_Optional (product-planner uses sensible defaults if absent)._ What the
product-planner grounds proposals in: vision doc(s), where to see existing
features, reference products, and the domain knowledge base at
`.claude/pm/knowledge/domain/`.
