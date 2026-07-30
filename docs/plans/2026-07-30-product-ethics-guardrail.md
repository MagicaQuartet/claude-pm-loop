# Product-ethics Guardrail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the pm-loop an always-on anti-dark-pattern guardrail — it never originates a dark pattern (planner/implementer/reviewer) and pushes back with a reconsider prompt when a human asks for one (PM reflex).

**Architecture:** One plugin-owned canonical doctrine (`skills/reviewing-prs/product-ethics.md`) that the code-review org reads on a trigger hit, plus a compact inline principle carried by the three non-reviewer roles (PM, planner, implementer) that cannot reliably read a plugin-internal file. A project extension (`.claude/pm/rubric/product-ethics.md`, scaffolded by `/pm-loop-init`) absorbs project-specific examples. Every addition is pinned by `scripts/check.sh`, keeping the gate green after every commit.

**Tech Stack:** Markdown role/skill/command docs; Bash gate (`scripts/check.sh`); JSON plugin manifests. No runtime code — "tests" are `check.sh` assertions plus scenario walk-throughs.

**Spec:** `docs/specs/2026-07-30-product-ethics-guardrail-design.md` (decisions D22–D29).

## Global Constraints

- **check.sh stays green after every commit.** Add each gate assertion in the SAME commit as the content it checks. Verify with `bash scripts/check.sh` → must print `OK: all checks passed`.
- **Zero-coupling audit** (check.sh §3): plugin content under `commands/ agents/ skills/ templates/` must be project-agnostic — NO project-specific tokens and NO concrete project domain examples. Project-specific dark-pattern examples belong ONLY in the scaffolded consumer file `.claude/pm/rubric/product-ethics.md`, never in the plugin stub. (`README.md` and `docs/` are exempt.)
- **No bare `/pm`** (check.sh §5d): always write `/pm-loop` or the `.claude/pm/...` path form.
- **Doctrine size budget** (D29): `skills/reviewing-prs/product-ethics.md` ≤ **550 words** (`wc -w`).
- **Commit format:** gitmoji `<emoji>: [<scope>] <title>`, English, ending with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer. Work on branch `feat/product-ethics-guardrail` (already checked out; the spec is its first commit).
- **Version bump last** (Task 5): `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` must advertise the same version (check.sh §5i).

---

### Task 1: Canonical doctrine + project-extension stub

Foundation both the reviewer (full read) and the gate depend on. Non-reviewer wiring comes in later tasks.

**Files:**
- Create: `skills/reviewing-prs/product-ethics.md`
- Create: `templates/rubric/product-ethics.md`
- Modify: `scripts/check.sh` (required-files array; doctrine heading loop; word-count bound)

**Interfaces:**
- Produces: the doctrine file with headings `## What counts`, `## Two-tier response`, `## For reviewers` (Task 2's SKILL.md section points here); the stub path `.claude/pm/rubric/product-ethics.md` (referenced by Tasks 2–4 and the reviewer).

- [ ] **Step 1: Add the gate assertions to `scripts/check.sh` (failing first).**

In the `required=(` array (after the `skills/reviewing-prs/compliance.md` line), add:

```bash
  skills/reviewing-prs/product-ethics.md
  templates/rubric/product-ethics.md
```

(Do NOT touch the SKILL.md heading loop here — the `## Product ethics` heading lands in Task 2.) After the existing SKILL.md heading loop (the `for h in '^## Severity ladder' … done` block), add a new block:

```bash
for h in '^## What counts' '^## Two-tier response' '^## For reviewers'; do
  require_heading skills/reviewing-prs/product-ethics.md "$h"
done

# product-ethics doctrine stays lean — every role that reads it pays for its length (spec D29)
pe_words=$(wc -w < skills/reviewing-prs/product-ethics.md 2>/dev/null | tr -d ' ')
[ -n "$pe_words" ] && [ "$pe_words" -le 550 ] || { echo "FAIL: product-ethics.md is '${pe_words:-missing}' words (budget <=550)"; fail=1; }
```

- [ ] **Step 2: Run the gate to verify it fails.**

Run: `bash scripts/check.sh`
Expected: FAIL — `missing required file skills/reviewing-prs/product-ethics.md` and the word-count line reports `missing`.

- [ ] **Step 3: Create `skills/reviewing-prs/product-ethics.md`** with exactly this content (kept under 550 words):

```markdown
# Product ethics

The pm-loop's anti-dark-pattern doctrine. It is **always on** — no profile toggle disables it — and is *extended, never overridden*, by the project's `.claude/pm/rubric/product-ethics.md` (domain examples, bright lines, documented legitimate-persuasion carve-outs). Every role honors it: the planner does not propose dark patterns, the implementer does not introduce them, the PM pushes back when a human asks for one, and the code-review org detects any that slip through.

## What counts

A **dark pattern** is design that deceives, coerces, or exploits a cognitive bias **against the user's own interest**. Named categories (the tell in parentheses):

- **sneaking** — costs/items the user didn't agree to, revealed late or hidden
- **urgency / scarcity** — a countdown or "only 2 left" that isn't real
- **misdirection** — visual or wording steer toward the choice that benefits you, not them
- **social proof** — fabricated reviews, activity, or testimonials
- **obstruction / hard-to-cancel** — the exit is far harder than the entrance
- **forced action** — an unrelated requirement bundled into a wanted action
- **nagging** — repeated interruption to wear the user down
- **confirmshaming** — guilt-wording to decline ("No thanks, I hate saving money")
- **disguised ads** — ads styled as content or native UI
- **trick wording / forced or tricked consent** — double negatives, pre-ticked boxes, consent obtained by confusion

**Boundary test (do not cry wolf):** legitimate persuasion is allowed — a *real* deadline's countdown, honest defaults that favor the user, clear opt-ins, genuine social proof, good onboarding. Ask: *does it deceive, coerce, or exploit a bias against the user's interest — or inform and let the user choose freely?* Only the former is a dark pattern. Regulatory backdrop (orientation, not a gate): EU DSA Art. 25, GDPR consent (Art. 7), FTC Act §5, and jurisdiction-specific equivalents.

## Two-tier response

When a dark pattern is requested or proposed:

- **Tier 1 — deceptive or illegal** (hidden charges, false statements, fake scarcity/social proof, forged or tricked consent, disguised ads, sneaking, obstruction of a legally-required easy exit): **do not build it, even on insistence.** Explain why and offer the honest alternative.
- **Tier 2 — manipulative but legal** (confirmshaming, nagging, misdirection, legal default opt-ins, mild urgency, user-hostile-but-legal friction): **push back** — name the pattern, explain the user harm and the business risk (trust, churn, brand, regulatory drift), and propose an honest alternative that meets the underlying goal. Proceed only on the human's explicit reconfirmation, and record that decision.

When unsure which tier, treat it as the higher one.

## For reviewers

Applied by the code-review org (`pr-reviewer`), **always** — not gated by the profile's `## Compliance` mode. **Trigger gate first:** scan the diff for a user-facing-surface signal (does it add or change user-facing copy, consent, defaults, or flows?). On a **miss**, record a one-line skip and read no further. On a **hit**, read this doctrine and the project's `.claude/pm/rubric/product-ethics.md` (when non-empty), then file findings: a **Tier-1** pattern is a **blocker**, a **Tier-2** pattern is **major/minor** by user harm. Frame each as {pattern name → what in the diff triggers it → honest remediation}, in the skill's standard comment format with a "Suggested fix prompt." A Tier-1 finding carries the Severity ladder's no-unilateral-downgrade protection.
```

- [ ] **Step 4: Create `templates/rubric/product-ethics.md`** (project-agnostic stub, mirrors the compliance stub shape):

```markdown
# Product-ethics rubric — project extensions

Extends (never overrides) the pm-loop's always-on product-ethics doctrine in the
`reviewing-prs` skill. List what is **specific to this project**:

- **Domain dark-pattern examples** — concrete patterns to watch for in this
  product's own surfaces (checkout, onboarding, consent, subscription, ...).
- **Bright lines** — patterns never acceptable here, with the regime or policy
  behind them where one applies.
- **Legitimate-persuasion carve-outs** — persuasion this project has decided is
  honest and allowed (e.g. "a limited-inventory badge backed by real stock"), so
  the reviewer does not flag it.

Empty is valid — the doctrine's own taxonomy still applies.
```

- [ ] **Step 5: Verify the word budget and the gate.**

Run: `wc -w < skills/reviewing-prs/product-ethics.md` — expect a number **≤ 550** (if over, tighten prose, do not raise the bound).
Run: `bash scripts/check.sh`
Expected: PASS — `OK: all checks passed`.

- [ ] **Step 6: Commit.**

```bash
git add skills/reviewing-prs/product-ethics.md templates/rubric/product-ethics.md scripts/check.sh
git commit -m "$(printf '%s\n' '✨: [plugin] product-ethics doctrine + project-extension stub' '' 'Canonical anti-dark-pattern doctrine (taxonomy, boundary test, two-tier' 'response) read by the code-review org on a trigger hit; project stub scaffolds' 'to .claude/pm/rubric/product-ethics.md. Pinned by check.sh (headings + <=550-word' 'budget).' '' 'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 2: Review layer — detection (SKILL.md + pr-reviewer + compliance-reviewer)

Wires the always-on, trigger-gated reviewer check and the Tier-1 downgrade protection.

**Files:**
- Modify: `skills/reviewing-prs/SKILL.md` (new `## Product ethics` section; Severity-ladder amendment)
- Modify: `agents/pr-reviewer.md` (one clause in Procedure step 2)
- Modify: `agents/compliance-reviewer.md` (one sentence — regulatory angle)
- Modify: `scripts/check.sh` (require `^## Product ethics` in SKILL.md; grep pr-reviewer references `product-ethics`)

**Interfaces:**
- Consumes: `skills/reviewing-prs/product-ethics.md` (Task 1).
- Produces: SKILL.md `## Product ethics` section (referenced by `pr-reviewer`); no new symbols downstream tasks depend on.

- [ ] **Step 1: Add the gate assertions to `scripts/check.sh` (failing first).**

In the SKILL.md heading loop, insert `'^## Product ethics'` after `'^## Adversarial pass'`:

```bash
for h in '^## Severity ladder' '^## Review tiers' '^## Re-review scope' '^## Lens assignment' '^## Adversarial pass' '^## Product ethics' '^## Comment output' '^## Reading the diff at the right ref' '^## Existing comments' '^## Approval'; do
  require_heading skills/reviewing-prs/SKILL.md "$h"
done
```

In the cross-file-consistency block (after the §5f/§5g lens/adversarial greps), add:

```bash
# 5j. Product-ethics guardrail: reviewer detection wired
grep -qF 'product-ethics' agents/pr-reviewer.md || { echo "FAIL: pr-reviewer.md does not reference product-ethics"; fail=1; }
```

- [ ] **Step 2: Run the gate to verify it fails.**

Run: `bash scripts/check.sh`
Expected: FAIL — `SKILL.md missing /^## Product ethics/` and `pr-reviewer.md does not reference product-ethics`.

- [ ] **Step 3: Add the `## Product ethics` section to `skills/reviewing-prs/SKILL.md`.**

Insert immediately **after** the `## Compliance` section and **before** `## Comment output`:

```markdown
## Product ethics

Applied by the code-review org (`pr-reviewer`), **always** — explicitly **not** gated by the profile's `## Compliance` mode, so `Compliance: off` never removes it. It is **trigger-gated**: every review runs a cheap signal scan — does the diff add or change user-facing copy, consent, defaults, or flows? On a **miss**, record a one-line skip and read no further; on a **hit**, read the doctrine and apply it. Full taxonomy, the boundary test, the two-tier response, and severity mapping: `product-ethics.md`.
```

- [ ] **Step 4: Amend the Severity ladder's no-unilateral-downgrade rule in `SKILL.md`.**

Find the paragraph beginning `**The PM may not unilaterally downgrade a security- or compliance-org finding.**` and append this sentence to it:

```markdown
 A **Tier-1 dark-pattern finding** (deceptive/illegal — see `product-ethics.md`) carries the same protection: not reclassified below major without the raising org's recorded concurrence.
```

- [ ] **Step 5: Add the reviewer clause to `agents/pr-reviewer.md`.**

In `## Procedure` step 2, after the existing `- If the PR's domain is unclear…` sub-bullet, add a new sub-bullet:

```markdown
   - **Product ethics (always, trigger-gated):** run the skill's **Product ethics** signal scan — does the diff add or change user-facing copy, consent, defaults, or flows? On a hit, read `product-ethics.md` and the project's `.claude/pm/rubric/product-ethics.md`, and file any dark-pattern findings (Tier-1 = blocker, Tier-2 = major/minor); on a miss, record a one-line skip. This is **not** gated by the profile's compliance mode.
```

- [ ] **Step 6: Add the regulatory sentence to `agents/compliance-reviewer.md`.**

In `## Procedure`, append to step 3 (the `Apply the **Compliance** section…` step) this sentence:

```markdown
 Deceptive-design / dark-pattern violations (e.g. EU DSA Art. 25, GDPR consent, FTC-style deception) are in scope **when a declared domain regulates them**; the always-on home for dark-pattern review is `pr-reviewer` (`Compliance: off` never removes it), so your coverage here is additive within your declared domains.
```

- [ ] **Step 7: Run the gate.**

Run: `bash scripts/check.sh`
Expected: PASS — `OK: all checks passed`.

- [ ] **Step 8: Commit.**

```bash
git add skills/reviewing-prs/SKILL.md agents/pr-reviewer.md agents/compliance-reviewer.md scripts/check.sh
git commit -m "$(printf '%s\n' '✨: [plugin] wire product-ethics detection into the review layer' '' 'pr-reviewer applies the always-on, trigger-gated Product ethics check (not' 'compliance-mode-gated); Tier-1 dark-pattern findings get no-unilateral-downgrade' 'protection; compliance-reviewer covers the regulatory angle within declared' 'domains.' '' 'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 3: PM reflex — push back on request (commands/pm-loop.md)

The G2 behavior: the PM refuses to silently scope a dark pattern.

**Files:**
- Modify: `commands/pm-loop.md` (new `## Product-ethics reflex` section)
- Modify: `scripts/check.sh` (grep pm-loop.md references `product-ethics`)

**Interfaces:**
- Consumes: the two-tier response and boundary test (inlined compactly here; full doctrine in Task 1). Records Tier-2 reconfirmation into `.claude/pm/knowledge/decisions.md` (already a wired knowledge store).

- [ ] **Step 1: Add the gate assertion to `scripts/check.sh` (failing first).**

In the cross-file block (after the §5j grep from Task 2), add:

```bash
grep -qF 'product-ethics' commands/pm-loop.md || { echo "FAIL: pm-loop.md does not reference product-ethics"; fail=1; }
```

- [ ] **Step 2: Run the gate to verify it fails.**

Run: `bash scripts/check.sh`
Expected: FAIL — `pm-loop.md does not reference product-ethics`.

- [ ] **Step 3: Add the `## Product-ethics reflex` section to `commands/pm-loop.md`.**

Insert as a new top-level section immediately **before** `## Loop`:

```markdown
## Product-ethics reflex

The pm-loop never *originates* a dark pattern and never silently builds one on request. The full doctrine (taxonomy, boundary test, two-tier response) lives in the `reviewing-prs` skill's `product-ethics.md`, extended by `.claude/pm/rubric/product-ethics.md`.

When the human's task — or a `product-planner` proposal you are about to present — embodies a dark pattern (deceptive or manipulative design working against the user's interest: fake urgency/scarcity, confirmshaming, sneaking, forced action, hard-to-cancel, disguised ads, misdirection, forged/tricked consent), apply the **two-tier response before scoping it into issues**:

- **Tier 1 — deceptive or illegal:** decline; explain why and offer the honest alternative; do not create the issue, even on insistence.
- **Tier 2 — manipulative but legal:** push back — name the pattern, explain the user harm and business risk, propose an honest alternative — and proceed only on the human's **explicit reconfirmation**. Record that reconfirmation as a `decision` (dated, in `.claude/pm/knowledge/decisions.md`) so the review orgs and future runs see it was a deliberate, human-owned call.

Legitimate persuasion (a real deadline's countdown, honest user-favoring defaults, clear opt-ins, genuine social proof) is **not** a dark pattern — do not block it (boundary test in `product-ethics.md`). When unsure which tier, treat it as the higher one.
```

- [ ] **Step 4: Run the gate.**

Run: `bash scripts/check.sh`
Expected: PASS — `OK: all checks passed`.

- [ ] **Step 5: Commit.**

```bash
git add commands/pm-loop.md scripts/check.sh
git commit -m "$(printf '%s\n' '✨: [plugin] PM product-ethics reflex — push back before scoping' '' 'At Scope and when presenting planner proposals, the PM applies the two-tier' 'response to any dark pattern before creating issues; Tier-2 proceeds only on' 'explicit human reconfirmation, recorded as a dated decision.' '' 'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 4: Ideation & build restraint (product-planner + implementer)

The G1 behavior at the two origination points that precede review.

**Files:**
- Modify: `agents/product-planner.md` (`## Restraint` clause + Risks/flags mention)
- Modify: `agents/implementer.md` (restraint clause)
- Modify: `scripts/check.sh` (grep both files reference `product-ethics`)

**Interfaces:**
- Consumes: two-tier gist (inlined compactly); project extension `.claude/pm/rubric/product-ethics.md`.

- [ ] **Step 1: Add the gate assertions to `scripts/check.sh` (failing first).**

After the pm-loop.md grep from Task 3, add:

```bash
grep -qF 'product-ethics' agents/product-planner.md || { echo "FAIL: product-planner.md does not reference product-ethics"; fail=1; }
grep -qF 'product-ethics' agents/implementer.md || { echo "FAIL: implementer.md does not reference product-ethics"; fail=1; }
```

- [ ] **Step 2: Run the gate to verify it fails.**

Run: `bash scripts/check.sh`
Expected: FAIL — `product-planner.md does not reference product-ethics` and `implementer.md does not reference product-ethics`.

- [ ] **Step 3: Add the restraint clause to `agents/product-planner.md`.**

At the END of the `## Restraint — don't propose for the sake of proposing` section (after `…that rationale is your deliverable for the run.`), add a new paragraph:

```markdown
**Never propose a dark pattern.** Deceptive or manipulative design that works against the user's interest — fake urgency/scarcity, confirmshaming, sneaking, forced action, hard-to-cancel, disguised ads, forged/tricked consent — is out of scope no matter how well it "converts." If a reference product uses one, note it as an anti-pattern, do not copy it. Flag any product-ethics surface a proposal would touch in its Risks/flags (project specifics: `.claude/pm/rubric/product-ethics.md`).
```

Then, in the `## Output shape (issue-ready)` list, find the `- **Risks / flags**` line and change `especially **security** and **compliance**` to `especially **security**, **compliance**, and **product-ethics**`.

- [ ] **Step 4: Add the restraint clause to `agents/implementer.md`.**

Immediately **after** the paragraph `Do not expand scope beyond the issue you were dispatched for; if scope grows mid-implementation, note it and stop rather than sprawl.`, add a new paragraph:

```markdown
**Never introduce a dark pattern** — deceptive or manipulative design working against the user's interest (fake urgency/scarcity, confirmshaming, sneaking, forced action, hard-to-cancel, disguised ads, forged/tricked consent). If the issue or its design brief requires one, **flag it and stop** rather than build it (same posture as scope growth above); the product-ethics call belongs to the PM. Project specifics: `.claude/pm/rubric/product-ethics.md`.
```

- [ ] **Step 5: Run the gate.**

Run: `bash scripts/check.sh`
Expected: PASS — `OK: all checks passed`.

- [ ] **Step 6: Commit.**

```bash
git add agents/product-planner.md agents/implementer.md scripts/check.sh
git commit -m "$(printf '%s\n' '✨: [plugin] planner + implementer never originate a dark pattern' '' 'product-planner will not propose dark patterns (and flags product-ethics' 'surfaces in Risks/flags); implementer will not introduce one, flagging and' 'stopping if an issue/brief requires it.' '' 'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

### Task 5: Consumer docs, scaffold, and release

Non-gated glue plus the version bump; finished with the acceptance walk-through.

**Files:**
- Modify: `commands/pm-loop-init.md` (rubric scaffold count)
- Modify: `README.md` (Product-ethics guardrail subsection)
- Modify: `.claude-plugin/plugin.json` (version → `0.3.0`)
- Modify: `.claude-plugin/marketplace.json` (version → `0.3.0`)

**Interfaces:**
- Consumes: all prior tasks. Produces the released, documented v0.3.0.

- [ ] **Step 1: Update the rubric scaffold count in `commands/pm-loop-init.md`.**

In `## Procedure` step 3, change `` `rubric/` (all three) `` to `` `rubric/` (all four) ``.

- [ ] **Step 2: Add the README subsection.**

In `README.md`, immediately **after** the `## Deterministic guardrails` section (before `## How updates work`), insert:

```markdown
## Product-ethics guardrail

The loop never *originates* a dark pattern — the `product-planner` won't propose
one, the `implementer` won't introduce one, and the code-review org detects any
that slip through — and when *you* ask for one, it pushes back and asks you to
reconsider instead of silently complying. The response is two-tier: **deceptive
or illegal** patterns (hidden charges, fake scarcity, forged consent, disguised
ads, obstruction of a legally-required easy exit) are **declined**; **manipulative
but legal** patterns (confirmshaming, nagging, misdirection, mild urgency) are
**sent back** — the pattern named, the user harm and business risk explained, an
honest alternative proposed — and built only on your explicit reconfirmation,
which the loop records as a dated decision.

This guardrail is **always on**: unlike compliance mode, there is no profile
switch to disable it. Legitimate persuasion (a real deadline's countdown, honest
defaults, clear opt-ins, genuine social proof) is not a dark pattern and is not
blocked. Projects **extend, never override** the doctrine with domain-specific
examples and bright lines in `.claude/pm/rubric/product-ethics.md`.
```

- [ ] **Step 3: Bump the version in both manifests.**

Set `"version"` to `"0.3.0"` in `.claude-plugin/plugin.json`, and set the matching `plugins[0].version` to `"0.3.0"` in `.claude-plugin/marketplace.json`. Verify:

Run: `python3 -c 'import json;print(json.load(open(".claude-plugin/plugin.json"))["version"], json.load(open(".claude-plugin/marketplace.json"))["plugins"][0]["version"])'`
Expected: `0.3.0 0.3.0`

- [ ] **Step 4: Run the full gate.**

Run: `bash scripts/check.sh`
Expected: PASS — `OK: all checks passed`.

- [ ] **Step 5: Acceptance walk-throughs (manual, read-only — confirm the docs say the right thing).**

Confirm by re-reading the edited files:
1. **Tier-2 request** — a request like "add a fake countdown timer to checkout" is covered by `commands/pm-loop.md`'s reflex (name pattern → alternative → reconfirm → record decision), and a *real* countdown is explicitly allowed by the boundary test.
2. **Tier-1 request** — "hide the cancel link / pre-tick data-sale consent" is declined by the reflex's Tier-1 branch.
3. **Planner restraint** — `agents/product-planner.md` forbids proposing one and flags it in Risks/flags.
4. **Reviewer detection with `Compliance: off`** — `SKILL.md`'s `## Product ethics` states it is not compliance-mode-gated; a backend-only diff records a one-line skip.
5. **Consumer compatibility** — `commands/pm-loop-init.md` scaffolds four rubric stubs; a repo missing the stub still works because the doctrine's own taxonomy applies (README says extend-not-override).

- [ ] **Step 6: Commit.**

```bash
git add commands/pm-loop-init.md README.md .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "$(printf '%s\n' '🔖: [plugin] v0.3.0 — product-ethics guardrail: docs, scaffold, release' '' 'Scaffold the fourth rubric stub; README Product-ethics guardrail section;' 'version bump to 0.3.0.' '' 'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---

## Plan Self-Review

- **Spec coverage:** G1 non-origination → Task 2 (reviewer), Task 4 (planner/implementer); G2 push-back → Task 3 (PM reflex). D22 doctrine → Task 1. D23 two-tier → Tasks 1/3. D24 always-on + extension → Tasks 1/5. D25 review home (pr-reviewer, not compliance-gated, not a lens) → Task 2. D26 boundary test → Task 1. D27 downgrade protection → Task 2 (Severity-ladder amendment). D28 taxonomy/agnostic → Task 1. D29 trigger-gate + size budget → Task 1 (word-count), Task 2 (trigger-gate wording). §8 gate additions → distributed across Tasks 1–4, each with its content. §12 acceptance → Task 5 Step 5. All covered.
- **Placeholder scan:** every doc insertion carries its full literal text; no TBD/TODO; every check.sh edit is shown verbatim.
- **Token wiring consistency:** the literal token `product-ethics` appears in `pr-reviewer.md` (T2), `pm-loop.md` (T3), `product-planner.md` + `implementer.md` (T4) — matching each `grep -qF 'product-ethics'` gate; `## Product ethics` heading added to `SKILL.md` (T2) matches the `require_heading` for it; the three doctrine headings (T1) match their `require_heading` loop.
