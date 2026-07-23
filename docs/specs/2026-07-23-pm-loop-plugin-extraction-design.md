# Design: Extract the SourceApp PM loop into a reusable Claude Code plugin

- **Date:** 2026-07-23
- **Status:** Draft — awaiting author review before writing the implementation plan
- **Author:** Dongseong Kim (with Claude Code)
- **Repo:** `claude-pm-loop` (private, GitHub `MagicaQuartet/claude-pm-loop`)

## 1. Goal

SourceApp runs a supervised multi-agent orchestration loop (`/pm`) with five roles —
product-planner, implementer, code reviewer, security reviewer, legal reviewer — plus a
continuous knowledge-accumulation loop and a human merge gate. It works well but is welded to
SourceApp: paths (`src/app/api/**`), gate commands (`bun run lint`), stack (Next.js / Supabase /
Drizzle / RLS), VCS conventions (`develop`, gitmoji), and domain law (domain-specific regulation).

Extract the **project-agnostic framework** into a standalone, installable Claude Code **plugin**
so any project can adopt the same loop, roles, and knowledge discipline — with **zero SourceApp
coupling in the plugin**, and with a clean per-project configuration seam.

## 2. Non-goals

- **Not** migrating SourceApp onto the plugin. SourceApp is untouched by this work (see §11).
- **Not** changing the loop's behavior or the roles' responsibilities — this is an
  extraction + generalization, not a redesign.
- **Not** shipping any domain content (domain-specific law, SourceApp schema facts). Those are
  examples at most, never plugin defaults.

## 3. Locked decisions

Settled during brainstorming (2026-07-22 → 07-23):

| # | Decision | Rationale |
|---|---|---|
| D1 | **Distribution: private plugin + marketplace.** Own git repo with `.claude-plugin/marketplace.json` + `plugin.json`; consumers `/plugin marketplace add` then `/plugin install`. | The native Claude Code mechanism for bundling commands/agents/skills with versioning and "call it anywhere." |
| D2 | **Private via personal GitHub repo** (`git@github.com-personal:MagicaQuartet/claude-pm-loop.git`), or a fully-local directory marketplace. **Pin versions explicitly; update manually** (`/plugin marketplace update`). | Private repos authenticate via existing `gh`/SSH creds. Background auto-update disables credential helpers and can fail on private HTTPS — manual + pinned is predictable. |
| D3 | **Thin plugin + project profile.** Plugin = 100% generic and immutable (loop, roles, review scaffold, knowledge-loop mechanics). Everything project-specific lives in the **consuming repo** under a fixed convention (`.claude/pm/`). | The knowledge loop must *write* project facts continuously; plugin files are read-only (overwritten on update). So all mutable/project content lives in the consumer, and plugin updates never clobber it. |
| D4 | **Heterogeneous consumers.** Assume any language/stack. Agents never hardcode TS/Supabase/`bun`. Gate commands, branch model, stack, and authz model are supplied 100% by `profile.md`. | Maximum reusability; safest default. |
| D5 | **All five roles retained, config-driven.** `legal-reviewer` → generic **`compliance-reviewer`** whose rubric comes entirely from the profile (auto-disabled when the profile declares no compliance domains). `product-planner`'s research axes are profile-injected. | Keeps the full structure the user relies on without baking in any one domain. |
| D6 | **Review tiers: mechanism in the skill, triggers in the profile.** The skill owns *how* reviewer counts scale, the severity ladder, and the docs-only / operational-docs carve-out logic. The profile owns *which* paths/keywords are risky (the "risk classes"). | Today's tiers hardcode `src/app/api/**`; this splits the invariant mechanism from the per-project trigger map. |
| D7 | **SourceApp relationship: parallel copy.** SourceApp stays as-is; the plugin is built alongside it. Drift is accepted and mitigated (§11). | User choice; least invasive to a production setup. |
| D8 | **Slash command stays `/pm`.** Plus a new `/pm-init` bootstrap command. | Continuity. |

## 4. Architecture

### 4.1 Plugin repo layout (`claude-pm-loop`, immutable, generic)

```
claude-pm-loop/
  .claude-plugin/
    marketplace.json        # name: claude-pm-loop; owner; plugins:[{name: pm-loop, source: "./"}]
    plugin.json             # name: pm-loop; version (pinned); description
  commands/
    pm.md                   # the generic PM loop (invoked as /pm)
    pm-init.md              # bootstrap a consuming repo (invoked as /pm-init)
  agents/
    implementer.md
    pr-reviewer.md
    security-reviewer.md
    compliance-reviewer.md  # generalized from legal-reviewer
    product-planner.md
  skills/
    reviewing-prs/
      SKILL.md              # severity ladder · review-tier MECHANISM · comment format · approval · knowledge loop
      code-review.md        # generic correctness / conventions / tests rubric
      security.md           # generic security rubric
      compliance.md         # generic compliance rubric scaffold
  templates/                # copied into the consuming repo by /pm-init (never read at loop time)
    profile.md              # the contract doc, with guided placeholders
    agent-safety.md         # (only if we choose the "scaffold" option for it — see §9 open Q)
    knowledge/
      invariants/README.md
      gotchas/README.md
      decisions.md
      domain/README.md
      team-learnings.md
    findings/index.md
    rubric/
      code-review.md        # project extensions to the generic rubric
      security.md
      compliance.md
  docs/
    specs/2026-07-23-pm-loop-plugin-extraction-design.md   # this doc
  README.md                 # human-facing: what it is, install, quick start
```

**Manifest facts (confirmed against current Claude Code docs):**
- `marketplace.json` requires `name` (kebab-case), `owner` (object with `name`), `plugins` (array).
- `plugin.json` requires only `name` (kebab-case); version resolves plugin.json → marketplace entry → git SHA.
- Components auto-discover: `commands/` (flat `.md` → `/name`), `agents/` (`.md` w/ frontmatter), `skills/` (subdir with `SKILL.md`), `hooks/hooks.json`.
- Sources for `/plugin marketplace add`: `owner/repo[#branch]`, git/SSH URL, **local path** (offline), direct `marketplace.json` URL.

### 4.2 Consuming repo convention (project-owned, mutable — where the knowledge loop writes)

```
<consuming-repo>/.claude/pm/
  profile.md                       # ★ single contract doc (see §5)
  knowledge/
    invariants/ *.md               # durable codebase facts (index + per-domain)
    gotchas/    *.md               # external-system / tooling traps
    decisions.md                   # ADR log (dated, supersede-don't-delete)
    domain/     *.md               # domain / market / compliance know-how (was domain-knowledge)
    team-learnings.md              # staging for not-yet-codified process learnings
  findings/
    index.md                       # recurring-findings index (category → covers → file → trigger)
    *.md                           # per-topic finding files
  rubric/
    code-review.md                 # project extensions to the plugin's generic code-review rubric
    security.md
    compliance.md
  plans/                           # git-ignored; resumable run-*.md / task-*.md plan docs
```

### 4.3 Reference resolution (the crux of the seam)

- **Plugin → project files:** by **fixed project-relative path** (`.claude/pm/profile.md`, `.claude/pm/knowledge/…`). Resolves correctly because the agent/command cwd is the consuming repo root.
- **Plugin → plugin siblings:** by **name** where possible. Agents invoke the `reviewing-prs` **skill** by name (Claude Code auto-discovers plugin skills); the skill references its own bundled `code-review.md`/`security.md`/`compliance.md` as skill-relative siblings. Agents are referenced by name in `pm.md`.
- **`agent-safety.md`:** the one plugin-owned doc every agent must *read*. Resolution approach is an open implementation question (§9).

This physical separation is what guarantees D3: a plugin update replaces plugin files only; the consumer's `.claude/pm/` is never touched.

## 5. The `profile.md` contract

`profile.md` is the heart of the seam — the single file that absorbs a heterogeneous stack so agents stay assumption-free. It supplies:

| Slot | What it declares | Example (SourceApp-flavored → generic) |
|---|---|---|
| **Identity & vision** | One-line project description + hard constraints reviewers must honor. | "Production-grade, not a prototype; web-first." |
| **VCS model** | Base branch; merge style; branch naming; commit + PR title format. | `develop`; squash; `<type>/issue-<n>`; gitmoji `<emoji>: [<scope>] <title>`. |
| **Quality-gate commands** | The **literal** commands to run before opening a PR, and which are blocking. Agents run exactly this list — no hardcoded `bun`/`npm`. | lint / typecheck / test / build commands. |
| **Architecture map** | Where routes/handlers, schema, and auth live. | `src/app/api/**`, `src/db/schema.ts`, `src/lib/auth*`. |
| **Authz / security model** | Where authorization is enforced; privileged-connection / RLS situation (or `n/a`). | "`src/lib/db.ts` bypasses RLS; authz in route handlers." |
| **Risk classes (review-tier triggers)** | Named risk classes: path/keyword globs → reviewer-count scaling + which orgs (security/compliance) activate. | route-handler class, payment class, auth/RLS class, migration class. |
| **Compliance domains** | List of active regimes that turn the `compliance-reviewer` on (or `none` → disabled). | GDPR / PCI-DSS / PIPA / domain-specific law / … |
| **Issue & PR tooling** | Host (GitHub `gh`), issue-template locations, label conventions. | `.github/ISSUE_TEMPLATE/feat.md`. |
| **Planner research axes** | The grounding sources the product-planner reads (vision doc, existing-features surfaces, reference products, domain KB). | schema + routes + `gh issue list` + domain KB. |

Design principle: **the plugin defines the mechanism and sensible defaults; the profile overrides with project truth.** A profile with everything at defaults must still yield a working loop.

## 6. Generalization plan (per artifact)

The bulk of the work is **rewriting** the ~20 docs so no SourceApp fact survives, while preserving behavior.

- **`commands/pm.md`** — keep verbatim in spirit: the loop, autonomy gates, resume + plan-docs discipline, the knowledge loop, the human merge gate + self-executed squash-merge, GC of orphaned runs. Replace every SourceApp path/command/law reference with "read `profile.md` and the KB at the convention paths." Plan docs move to `.claude/pm/plans/`.
- **`agents/implementer.md`** — replace `bun run lint`/`tsc`/RLS/Supabase blurb with "run the profile's gate commands; do the basic self-check scoped by the profile's authz/security model." Keep the KNOWLEDGE-return block, address-review mode, shared-sequence-resource reporting.
- **`agents/pr-reviewer.md`, `security-reviewer.md`, `compliance-reviewer.md`, `product-planner.md`** — generic rubric + "read the project `rubric/` extensions and `knowledge/` before judging." `compliance-reviewer` reads the profile's compliance domains and the project `domain/` KB; returns early/`n/a` when no domains are declared. `product-planner` reads the profile's research axes. All keep the feasibility-triage mode and KNOWLEDGE block.
- **`skills/reviewing-prs/SKILL.md`** — severity ladder (already generic), comment format (generic; the `🤖 Written with Claude Code` attribution stays), approval (generic; the single-account self-approve caveat becomes conditional "if reviewer == author"). **Review tiers** become the *mechanism* driven by the profile's risk classes. The "operational / self-referential docs" carve-out generalizes to "the files governing this loop (the plugin's own agents/commands/skill) + any globs the profile marks operational."
- **`skills/reviewing-prs/{code-review,security,compliance}.md`** — strip to the generic, universal rubric. SourceApp's findings-index rows, PR numbers, and file names are removed; the *pattern* (a findings index that the project fills in) stays, pointing at the project's `.claude/pm/findings/`.
- **Knowledge-base docs** — become empty, self-describing `templates/` scaffolds (headers + "how to use this store" + format rules), not content.
- **`agent-safety.md`** — already ~95% generic; drop the SourceApp role enumeration, keep the untrusted-content directive.

## 7. Knowledge loop in generic form

Behavior is unchanged; only the target paths generalize. Subagents emit `## KNOWLEDGE` candidates; the PM triages per return and routes each accepted entry to the consumer's stores:

- `invariant` → `.claude/pm/knowledge/invariants/…`
- `recurring-finding` → `.claude/pm/findings/…` (+ matching invariant)
- `gotcha` → `.claude/pm/knowledge/gotchas/…`
- `decision` → `.claude/pm/knowledge/decisions.md` (dated, supersede-don't-delete)
- `domain` → `.claude/pm/knowledge/domain/…`
- `process` → the relevant workflow doc or `team-learnings.md`

The hybrid commit path (a PR's own knowledge rides that PR; orphans go through a docs PR), the scope-creep guard, size-discipline curation, and the harvest backstop all carry over unchanged. Crucially, **all writes land in the consuming repo** — never in the plugin.

## 8. `/pm-init` bootstrap

Run once per consuming repo. It:

1. Reads whatever signal exists (`CLAUDE.md`/`README`, git config, package/build manifests) to pre-fill defaults.
2. Interviews the user briefly for the profile slots it can't infer (gate commands, risk classes, compliance domains).
3. Writes `templates/*` into `.claude/pm/` — the filled `profile.md`, the empty KB skeleton, the `findings/index.md`, and the `rubric/` stubs.
4. Is **idempotent**: never overwrites an existing `.claude/pm/` file; reports what it created vs. skipped.
5. Reminds the user to add `.claude/pm/plans/` to `.gitignore`.

## 9. Open implementation questions (to resolve in the plan, not blocking this design)

1. **`agent-safety.md` resolution.** Three options: (a) **inline** the short directive into each agent file (most robust, ~5 small copies, no path resolution); (b) reference `${CLAUDE_PLUGIN_ROOT}/agent-safety.md` *if* the variable interpolates inside agent markdown bodies (needs verification); (c) scaffold it into the consumer via `/pm-init` and reference it project-relative. **Leaning (a).**
2. **Does `${CLAUDE_PLUGIN_ROOT}` interpolate in command/agent markdown bodies**, or only in `plugin.json`/`hooks.json`/`.mcp.json`? Determines whether plugin docs can reference plugin-relative paths at all. Verify empirically during Phase 0.
3. **Plugin vs. marketplace naming.** Repo is `claude-pm-loop`; proposed marketplace name `claude-pm-loop`, plugin name `pm-loop`, install `pm-loop@claude-pm-loop`. Confirm the command still resolves as `/pm` (and whether namespacing to `/pm-loop:pm` ever kicks in on collision).
4. **`gh` assumption.** The loop assumes GitHub + `gh`. Heterogeneous consumers might use GitLab. For v1, document GitHub-`gh` as a prerequisite; abstract the VCS-host layer only if a non-GitHub consumer appears.

## 10. Distribution & versioning

- Marketplace source for consumers: `MagicaQuartet/claude-pm-loop` (private) or a local clone path.
- **Pin** `version` in `plugin.json`; bump on release; consumers update via `/plugin marketplace update claude-pm-loop`.
- Optionally commit `extraKnownMarketplaces` into a consumer's `.claude/settings.json` for one-step team onboarding.

## 11. SourceApp relationship & drift mitigation

SourceApp keeps its in-repo `.claude/` setup unchanged (D7). The plugin is a **parallel extraction**, so the two will drift as each improves independently. Mitigations:

- The plugin is the **canonical generic** version; SourceApp-specific evolution stays in SourceApp's `.claude/`.
- Periodically reconcile generic improvements in one direction (SourceApp → plugin for loop/role mechanics; plugin → SourceApp is optional and manual).
- **Future option (out of scope here):** promote SourceApp to the plugin's first real consumer — install the plugin, move SourceApp's project-specific content into `.claude/pm/`, delete the now-duplicated generic files. This collapses the drift entirely and is the ultimate dogfood, but is deferred.

## 12. Verification / acceptance criteria

Since SourceApp is untouched, verification uses a **scratch consumer project**:

1. **Install round-trip:** `/plugin marketplace add` (local path + private repo) → `/plugin install pm-loop@claude-pm-loop` → `/pm` and `/pm-init` are discoverable; the five agents and the `reviewing-prs` skill load.
2. **Zero-coupling audit:** grep the entire plugin for SourceApp tokens (`Supabase`, `RLS`, `bun`, `src/app/api`, `drizzle`, domain-law terms). Must be **empty** outside `docs/`/`README` examples explicitly labeled as such.
3. **Bootstrap:** `/pm-init` in the scratch repo produces a coherent `.claude/pm/` and a working `profile.md`; re-running is a no-op.
4. **End-to-end loop:** in the scratch repo, `/pm "<small task>"` runs scope → implement → review → address → merge-gate using only the profile + generic rubric, with no SourceApp assumptions leaking in.
5. **Compliance auto-disable:** with `compliance domains: none`, the `compliance-reviewer` does not run and the loop records the skip.

## 13. Milestones (detailed steps deferred to the implementation plan)

- **M0 — Skeleton & install proof:** repo scaffolding, `marketplace.json` + `plugin.json`, a stub `/pm`, local + private install round-trip; resolve open Qs #1–#3.
- **M1 — Core loop & roles:** genericize `pm.md`, `implementer.md`, `pr-reviewer.md`, `security-reviewer.md`, the `reviewing-prs` skill core; define `profile.md` schema; build `/pm-init`.
- **M2 — Domain roles & knowledge loop:** `compliance-reviewer` + `product-planner` genericization; findings-index scaffold; knowledge-loop wiring to `.claude/pm/`.
- **M3 — Harden & verify:** run §12 on a scratch consumer; zero-coupling audit; README + release v0.1.0 (pinned).
```
