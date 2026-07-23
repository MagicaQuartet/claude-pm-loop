# claude-pm-loop

A Claude Code plugin that runs a supervised, multi-agent PM loop against your
project: **scope → design (gated) → implement → review → address →
human-approved merge.** One command drives the whole thing; five config-driven
subagent roles do the work.

The loop reads everything it needs to know about *your* project from a single
committed profile (`.claude/pm/profile.md`) — VCS conventions, quality-gate
commands, risk classes, compliance mode — so the plugin itself stays
project-agnostic. An `implementer` turns one issue into a PR; a `pr-reviewer`,
`security-reviewer`, and `compliance-reviewer` review it in parallel, sized by
your profile's risk classes; a `product-planner` can propose work when you
don't already have a task in mind. A continuous **knowledge loop** lets every
subagent surface durable findings (invariants, gotchas, decisions, domain
facts) that the PM triages into your repo's own knowledge base, so the team's
know-how compounds run over run instead of evaporating. The only fixed human
checkpoint is the **merge gate** (the PM also always asks before
destructive/irreversible operations and production/infra changes): the PM
asks before every squash-merge into your base branch and never merges
without an explicit go. (This plugin was extracted from a production
project's in-repo multi-agent setup.)

## Prerequisites

- [Claude Code](https://claude.com/claude-code)
- A GitHub repository, with `gh` installed and authenticated (`gh auth login`)
  — v1 supports GitHub only.

## Install

Add the marketplace, then install the plugin from it:

```
/plugin marketplace add MagicaQuartet/claude-pm-loop   # private repo (needs gh/SSH auth)
/plugin marketplace add /path/to/claude-pm-loop        # or a local clone
/plugin install pm-loop@claude-pm-loop
```

Depending on context the commands may surface under their fully-qualified
names — `/pm-loop:pm-loop` and `/pm-loop:pm-loop-init` (plugin:command); in
headless (`claude -p`) use the fully-qualified form.

### Using on another device

Plugin installs are per-user and machine-global, not per-project: once
installed, every project you open on that machine gets `/pm-loop` and
`/pm-loop-init`. Installed plugins are cached under `~/.claude/plugins/`, so
there's no network fetch on every session — only on install/update.

On a new machine, there's nothing project-specific to carry over: authenticate
(`gh auth login`, or set up an SSH key if you're using the private-repo form)
and run the same two commands above.

## Quick start

1. In a repo you want the loop to manage, run `/pm-loop-init`. It reads
   whatever signal it can find (`CLAUDE.md`/`README`, `git remote -v`, the
   default branch, build/test manifests) to pre-fill defaults, interviews you
   for what it can't infer (quality-gate commands, risk classes, compliance
   mode and domains, base branch if ambiguous), and scaffolds
   `.claude/pm/`: the filled `profile.md`, the knowledge-base skeleton
   (`knowledge/invariants/`, `knowledge/gotchas/`, `knowledge/decisions.md`,
   `knowledge/domain/`, `knowledge/team-learnings.md`), `findings/index.md`,
   and `rubric/` stubs for the three review orgs. It never overwrites an
   existing file — re-running is a safe no-op that just reports state.
2. Commit the scaffold (everything under `.claude/pm/` except `plans/`, which
   is git-ignored — that directory holds ephemeral, resumable run state).
3. Run `/pm-loop "<your task, in natural language>"`.

## The profile

`.claude/pm/profile.md` is the single source of project truth every pm-loop
agent reads first. Ten sections, each required or optional:

| Section | Required? | Purpose |
|---|---|---|
| Project | Required | What the project is, plus hard constraints agents must honor. |
| VCS | Required | Base branch, merge style, branch naming, commit/PR title format. |
| Quality gate | Required | The literal commands an implementer runs before opening a PR. |
| Architecture map | Optional | Structural landmarks (routes, schema, entry points) — empty is valid. |
| Security model | Optional | Where authorization is enforced, or any privileged-connection bypass. |
| Risk classes | Required (list may be empty, but say so) | Named classes of risky change that scale how heavily a PR is reviewed. |
| Compliance | Required | Compliance mode (`full`/`minimal`/`off`) and the domains it covers. |
| Tooling | Required | Issue tracker, issue templates, labels/conventions. |
| Planner research axes | Optional | What the `product-planner` grounds its proposals in. |
| Review diversity | Optional | Per-org reviewer model overrides; absent = every review agent inherits the session model. |

## Deterministic guardrails

The plugin ships a `PreToolUse` hook that watches Bash commands in
pm-loop-managed repos (those with `.claude/pm/profile.md`) and forces a
harness permission prompt — even in accept-edits mode — at the moment a merge
or history-rewriting push actually runs: `gh pr merge`,
`gh api …/pulls/<n>/merge`, or `git push` with
`--force`/`--force-with-lease`/`-f`.

Expect one prompt per merge, *after* your chat-level "go": chat approval is
not machine-verifiable, so the execution-time prompt is the hard gate — the
double confirm is intentional. Caveats: this is defense-in-depth, not a
security boundary — it matches command patterns, and `bypassPermissions`
weakens it. Repos without a pm-loop profile are unaffected; the hook stays
silent there.

## How updates work

The plugin's version is pinned in `.claude-plugin/plugin.json`; nothing
updates automatically. Pull a new release yourself with:

```
/plugin marketplace update claude-pm-loop
```

`.claude/pm/` belongs to your repo, not the plugin — updates never touch your
profile, knowledge base, or findings. You control if and when to adopt any
schema changes a new plugin version introduces.

For one-step onboarding across a team or across your own devices, commit an
`extraKnownMarketplaces` entry to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-pm-loop": {
      "source": { "source": "github", "repo": "MagicaQuartet/claude-pm-loop" }
    }
  }
}
```

Anyone opening the repo then only needs `/plugin install pm-loop@claude-pm-loop`
— no separate `marketplace add` step.

## Design docs

The full design rationale, decisions, and milestone history live under
[`docs/specs/`](docs/specs/).
