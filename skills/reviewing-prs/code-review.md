# Code review

The code-review org's (`pr-reviewer`) rubric — referenced from the shared `SKILL.md`.

Applied by the code-review org (`pr-reviewer`, run at the count `SKILL.md`'s Review tiers section derives from the profile).

**Correctness**
- Types are sound; no unsafe casts hiding real mismatches.
- Error handling is present on every fallible path.
- Edge cases are covered; no regressions to existing behavior.

**Conventions**
- Commit / branch / PR title and body format per the profile's `## VCS`.
- Scope is contained — no scope creep beyond the issue; commits are small, logically coherent units.

**Tests**
- Tests exist and are adequate for the change.
- **Tests must track the spec (in the same PR):** a behavior-changing PR that adds a behavior with no covering test, changes a behavior without updating its tests, or leaves tests asserting the superseded behavior, is a finding. Severity: **blocker** when the rule below applies; otherwise **major** (a real coverage/staleness gap) or **minor** (a narrow edge) per the Severity ladder. Stale tests that still pass while asserting old behavior are a defect, not a convenience.
- **A bug-fix PR whose root cause NO existing gate caught (lint/typecheck/unit/build all stayed green through the bug) must ship a regression test in the SAME PR, at the LOWEST tier that can actually observe the failure mode — manual one-off verification is not a substitute.** Those gates are by construction equally blind to a re-break of the merged fix. Accept deferral only when NO matching test infra exists for that failure mode, and only with a tracking issue opened in the same PR.
- **Blocker — required tests may not be deferred:** for a change touching a profile-named sensitive flow, or a risk class the profile flags as test-requiring, a missing test on that path is a **blocker**, not a deferrable minor, once matching test infra exists.

**Basic security & compliance detection**
- Flag anything that *looks* like a security or compliance issue and defer the deep verdict to the security / compliance orgs — do not re-verify in depth here.

## Recurring findings (prevent at implement time)

Defect classes reviewers keep filing, split by topic under `.claude/pm/findings/*.md` and indexed at `.claude/pm/findings/index.md` (category → what it covers → file → the diff signal that means "read this one"). Fed by the knowledge loop: a reviewer surfaces a repeat finding in its `## KNOWLEDGE` block, the PM adds a row to the index and detail to the matching topic file.

Read the index, then every topic file whose trigger matches the PR on **either** signal: a changed path against the trigger's glob, OR one of its named keywords/call-sites appearing in the diff content.

**Floor rule:** when a risk class matching this PR declares `security yes`, treat every findings-index category whose trigger overlaps that class's keywords as a **floor** — read all of them, not only the ones a strict keyword scan happens to hit. This is additive to the two-signal matching above, not a substitute for it. If the PR's domain is unclear, spans many areas, or matches no trigger cleanly on either signal, default to reading **all** category files — the skill's own "when in doubt, scale up" posture.

## Auditing a "covers every X" claim

When a PR claims to cover/audit **every** occurrence of something (every role change, every write, every leak path), don't trust the PR's named list — **grep every mutation site of the underlying resource**: direct writes, raw queries, and any **DB trigger or hook** that also mutates it. A mutation site the PR didn't name is a gap. A trigger/hook that sets a column to a default on creation is a *legitimate* non-gap for a **change** audit (a creation default is not a change to an existing value), but it must be **explicitly ruled out** in the review, not silently assumed.

## Reviewing a contract-change PR

When a PR standardizes or changes a shared contract (e.g. an API response envelope), verify completeness on **both sides** of the boundary:

- **Producer side:** an exhaustive grep of tracked files for the OLD shape's construction pattern — any surviving match is an un-migrated site still emitting it.
- **Consumer side:** enumerate every call site and split it in two — **body-readers** that pull a field out of the response MUST be updated to the new shape, or they render garbage/undefined; **hardcoded-fallback sites** that ignore the body are unaffected and should NOT be flagged. Missing a body-reader site is a real regression; "fixing" a fallback site is noise.
- Also check handlers that **lack tests** for this contract — a contract change to an untested handler has no regression net.
