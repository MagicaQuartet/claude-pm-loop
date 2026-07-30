---
name: reviewing-prs
description: Use when reviewing a PR in a pm-loop-managed project — severity ladder, review tiers, comment format, and the per-org rubrics.
---

# Reviewing PRs

Single source of review truth for this project. Each review org applies its own section below; the PM consolidates findings across orgs. Read the profile's `## Project` constraints first — a production-grade service weights security, data integrity, and compliance first.

The implementer does a *basic* self-check while building, and `pr-reviewer` does *basic* detection; **deep** security and compliance verification belong to the dedicated orgs.

## Severity ladder

Every finding carries exactly one severity. Use these definitions across all orgs so the PM can union and reconcile consistently:

- **blocker** — ships a real defect or risk: a security/access-control hole, data corruption or loss, a miscalculation in a profile-named sensitive flow, a crash on a normal path, or a compliance violation that exposes the service. Must be fixed before merge.
- **major** — a correctness or convention defect that is wrong but not catastrophic: a mishandled edge case, missing error handling on a fallible path, a missing required test (see Tests), or a meaningful spec deviation. Should be fixed before merge.
- **minor** — a low-impact issue: a narrow edge case, weak naming, light duplication, an incomplete-but-not-wrong test. Fix now or defer to a follow-up issue.
- **nit** — style/polish with no behavioral impact; non-blocking.

**Disagreement resolves to the higher severity** when reviewers (or orgs) rate the same finding differently — unless the PM documents why the lower rating wins. The PM records the resolved severity in the run doc.

**The PM may not unilaterally downgrade a security- or compliance-org finding.** A finding the **security or compliance org** rated blocker or major cannot be reclassified below "major" without that org's recorded concurrence in the run doc. (Other downgrades follow the disagreement rule above.) A **Tier-1 dark-pattern finding** (deceptive/illegal — see `product-ethics.md`) carries the same protection: not reclassified below major without the raising org's recorded concurrence.

## Review tiers (which orgs run, and how many)

Mechanical, not "PM-sized by feel" — the PM derives each org's count from the profile, never from memory.

**Baseline (no risk class matches the diff): 2 code-reviewers, 1 security reviewer, compliance per the profile's `## Compliance` mode.**

**Each risk class in the profile's `## Risk classes` that matches the diff applies its declared scaling on top of the baseline.** A class matches on **either** of two independent signals — a changed path against its glob, OR one of its keywords appearing in the diff content — path and keyword are equally sufficient; don't require both. When more than one class matches, take the highest reviewer count and the most-permissive yes for each yes/no dimension (a `security yes` or `compliance yes` from any matching class wins).

**"Docs-only PR"** — a PR confined to prose docs with no code, dependency, or config changes — gets a carve-out: **1 code-reviewer**, and **security may skip** (both recorded in the run doc with why). **Caveat:** this never applies to *operational* docs — any in-repo copies of loop-governing docs, everything under `.claude/pm/`, and the profile's own operational-docs globs (declared under `## Risk classes`) — a change there is never "docs-only": it keeps **≥2 code-reviewers** and **≥1 narrowly-scoped security reviewer** (scope: "did this change remove or weaken security-relevant guidance?"), because a single reviewer on a self-referential process change can miss what a second one catches.

**Light tier (small no-risk diffs).** A PR runs at the light tier only when ALL hold (record the tier and the measured numbers in the run doc): no risk class matches the diff (neither path nor keyword signal); the diff is **≤ 50 changed lines** (additions + deletions) across **≤ 3 files**; it touches no dependency manifest, schema/migration, auth/authz code, or CI/tool config; and the operational-docs caveat above does not apply (that caveat always wins). Staffing: **1 code-reviewer** (full rubric, including basic security detection), **security may skip** (recorded with why), compliance per the profile's `## Compliance` mode. **Escalation:** if the single reviewer files any blocker or major, or judges the light-tier criteria misapplied, the PM re-runs the review at baseline and records it. A profile may disable the tier with a `Light tier: off` line under `## Risk classes` (default: on).

When in doubt, scale **up**: an unnecessary reviewer is cheap, a missed class of defect is not.

## Re-review scope

After an address round, the default re-review is **delta-scoped**: verify each actionable finding's resolution, and review only the diff between the previously reviewed head and the new head (`git diff <reviewed-sha>...<new-head>`), dispatched to **one reviewer per org that raised the addressed findings**. Run a **full re-review at the PR's original tier** when any of these holds: the address-round delta matches a risk class (path or keyword); the delta exceeds the light-tier size limits (> 50 changed lines or > 3 files); or the address round changed files outside the scope of the findings being addressed. Record the scope decision in the run doc.

## Lens assignment

When the tier yields **N ≥ 2 code-reviewers**, the PM assigns reviewer *i* lens *i* from this ordered list (cycling when N > 4) and passes the lens in the dispatch prompt:

1. correctness & edge cases
2. API contracts & cross-module consistency
3. test adequacy & spec fidelity
4. maintainability & conventions

A lens is a **lead emphasis, not blinders**: the full rubric still applies to every reviewer, and out-of-lens findings carry equal weight and equal reporting obligation. The PM records the lens map in the run doc.

## Adversarial pass

Mechanical, not discretionary. Run **one** adversarial pass — at most one per review round — when either trigger holds:

- **(a)** the initial review round of a PR whose tier yields **≥ 3 code-reviewers**;
- **(b)** a **blocker** finding on which orgs disagree about severity, or which the PM proposes to downgrade — the pass runs before the severity is resolved (consistent with the no-unilateral-downgrade rule in the Severity ladder).

The pass is one `pr-reviewer` instance dispatched with the consolidated top findings and the mandate: *refute or confirm each, and hunt for what every reviewer missed.* Its findings join the union under the normal severity ladder.

## Code review

Applied by the code-review org (`pr-reviewer`, run at the count the Review tiers section above derives from the profile). Full rubric: `code-review.md`.

## Security (deep)

Applied by the security org (`security-reviewer`). Full rubric: `security.md`.

## Compliance

Applied by the compliance org (`compliance-reviewer`), dispatched per the profile's `## Compliance` mode. Full rubric: `compliance.md`.

## Product ethics

Applied by the code-review org (`pr-reviewer`), **always** — explicitly **not** gated by the profile's `## Compliance` mode, so `Compliance: off` never removes it. It is **trigger-gated**: every review runs a cheap signal scan — does the diff add or change user-facing copy, consent, defaults, or flows? On a **miss**, record a one-line skip and read no further; on a **hit**, read the doctrine and apply it. Full taxonomy, the boundary test, the two-tier response, and severity mapping: `product-ethics.md`.

## Comment output

Post findings as PR comments in English, closing with the `🤖 Written with [Claude Code](https://claude.ai/code)` attribution line; whenever a finding asks for a code change, include a "Suggested fix prompt" block — a copy-pasteable prompt an implementer agent can run to apply that one fix, scoped tightly enough that applying it can't silently absorb unrelated changes.

## Reading the diff at the right ref

**A review subagent's on-disk working tree may be checked out on the base branch, NOT the PR branch** — a naive `Read` of a changed file then shows pre-PR content, and you can conclude a change is missing when it's actually on the PR head. Before drawing conclusions, read changed files at the PR ref: `git show origin/<branch>:<path>` (or `git diff origin/<base>...origin/<branch>`), or check out a throwaway worktree at the PR head. Confirm with `gh pr view <n> --json headRefOid` and compare it to your `HEAD`.

## Existing comments (re-review of an already-open PR)

When a PR already carries review comments, assessing each one's legitimacy is part of the review. **Every assessed comment thread must end resolved** — never leave an assessed thread open:

- **Change needed:** the comment flows into the consolidated fix list; once the fix is pushed, reply on that thread with what was changed, then resolve it. The implementer that applies the fix owns this.
- **Change not needed:** reply with the concrete reason it isn't warranted, then resolve it. The reviewer that judged it owns this.

Resolve a thread via GitHub's "Resolve conversation" (`gh api graphql` `resolveReviewThread`). Replies follow the same comment format above.

**Only inline review-thread comments are resolvable.** Diff-anchored comments (`gh api …/pulls/<n>/comments`) can be resolved; conversation/issue-level comments (`…/issues/<n>/comments`) are **reply-only** — for those, "end resolved" means reply-with-outcome, since there is no thread to resolve. Don't try to `resolveReviewThread` a conversation comment.

## Approval

When **all** review orgs have completed and their findings are addressed, the PM records review completion. This is **distinct from the human merge gate** — completion ≠ permission to merge; merging into the base branch still requires explicit human approval. **If the reviewing account is the PR author, `gh pr review <n> --approve` fails** (`Can not approve your own pull request`) — record completion with `gh pr review <n> --comment -F <file>` carrying a structured "✅ PM review complete — recommended for merge" summary instead (a plain comment carries no APPROVE/CHANGES_REQUESTED state, so GitHub allows it on your own PR).
