# Design: product-ethics guardrail — anti-dark-pattern across the pm-loop

- **Date:** 2026-07-30
- **Status:** Implemented — shipped in v0.3.0 (merged via PR #7, 2026-07-30)
- **Author:** Dongseong Kim (with Claude Code)
- **Repo:** `claude-pm-loop` (builds on the v0.2 hardening design, `2026-07-23-v0.2-hardening-design.md`)

## 1. Goal

Give the pm-loop a standing **product-ethics guardrail** so that it never *originates* a
dark pattern — at ideation, at implementation, or at review — and, when a human *asks* for
one, pushes back and asks them to reconsider instead of silently complying. The loop's shape
is unchanged (stages, roles, and the human merge gate all stay). Two behaviors are added,
threaded through the existing roles:

- **G1 — Never originate.** The `product-planner` does not *propose* dark patterns, the
  `implementer` does not *introduce* them, and the review orgs *detect* any that slip through.
- **G2 — Push back on request.** When the human's task, or a planner proposal, embodies a dark
  pattern, the PM names the pattern and asks the human to reconsider **before** scoping it into
  issues — a **반려** (send-back-for-reconsideration), not blind compliance.

The mechanism is a single **cross-cutting doctrine** referenced by every relevant role, mirroring
the existing extensible-rubric pattern (`skills/reviewing-prs/compliance.md` +
`templates/rubric/compliance.md`). It is **always on** and cannot be disabled by a profile.

## 2. Non-goals

- **Not** a sixth reviewer org. A dedicated dark-pattern agent would cover only the review
  stage and miss ideation, implementation, and the human-intake reflex; it would also duplicate
  the untrusted-content and KNOWLEDGE boilerplate. The doctrine is cross-cutting instead.
- **Not** a profile toggle. Unlike compliance mode (`full`/`minimal`/`off`), the ethics
  guardrail has **no off switch** — a plugin whose values can be configured away is not a
  guardrail. Project specificity is absorbed only by the `.claude/pm/rubric/product-ethics.md`
  extension.
- **Not** a new deterministic hook. Dark patterns are semantic, not command-pattern-matchable
  (unlike merge/force-push); a `PreToolUse` hook cannot see "this countdown timer is fake." The
  guardrail is necessarily a prompt-level principle.
- **Not** a ban on legitimate persuasion. A real deadline's real countdown, honest
  user-favoring defaults, clear opt-ins, and genuine social proof are **not** dark patterns; the
  doctrine draws that line explicitly (§6) so the guardrail does not cry wolf.
- **Not** legal advice. Regulatory citations orient the reviewer; material/high-stakes calls
  still escalate to human/qualified counsel, exactly as `compliance-reviewer` already states.

## 3. Locked decisions

Settled during brainstorming (2026-07-30); numbering continues from the v0.2 design (…D21):

| # | Decision | Rationale |
|---|---|---|
| D22 | **Cross-cutting doctrine, not a new org and not compliance-only.** One canonical file (`skills/reviewing-prs/product-ethics.md`), referenced by the PM, `product-planner`, `implementer`, and `pr-reviewer`. | Dark patterns span ideation→build→review→human-intake; a single stage can't hold the guardrail. A doctrine referenced by path keeps it DRY and lets each role add only a one-line, role-specific behavior. |
| D23 | **Two-tier response.** **Tier 1 (deceptive/illegal** — hidden charges, false statements, fake scarcity/social proof, forged/ tricked consent, disguised ads, sneaking, obstruction of a legally-required easy exit): **hard-refuse** — do not build even on insistence; explain and offer the honest alternative. **Tier 2 (manipulative-but-legal** — confirmshaming, nagging, visual misdirection, legal default opt-ins, mild urgency, user-hostile-but-legal friction): **push back → name the pattern → explain user-harm + business risk → propose an honest alternative;** on explicit human reconfirmation, **record the decision and proceed.** | Matches the plugin's "advisory, human decides" philosophy for the legal-but-manipulative middle, while drawing a hard line at deception/illegality (which already falls under the plugin's malicious-request refusal and typically violates law). |
| D24 | **Always on; no profile toggle.** Project specificity lives only in the `.claude/pm/rubric/product-ethics.md` extension (domain-specific examples, bright lines, and any documented legitimate-persuasion carve-outs). | An ethics guardrail with an off switch isn't one. The extension gives per-project precision without letting a project disable the principle. |
| D25 | **Review home is `pr-reviewer`, always-applied, scoped to user-facing surfaces — NOT gated by compliance mode, NOT a rotating lens.** `compliance-reviewer` additionally covers the *regulatory* dark-pattern angle within its declared domains. | `pr-reviewer` always runs, so protection survives `Compliance: off`. Scoping to user-facing surfaces (UI, copy, consent, defaults, flows) keeps it token-frugal — a backend-only diff records a skip. A rotating lens would fire only for one of N≥2 reviewers; an always-applied check fires every review (its full doctrine read trigger-gated per D29). (Also avoids worsening the known "lens" term overload.) |
| D26 | **Persuasion-vs-manipulation boundary test, stated in the doctrine.** "Does it deceive, coerce, or exploit a cognitive bias **against the user's own interest** — or does it inform and let the user choose freely?" Only the former is a dark pattern. | Without an explicit line the guardrail flags every countdown and default, becomes noise, and gets ignored. |
| D27 | **Tier-1 findings get no-unilateral-downgrade protection.** A `pr-reviewer` (or `compliance-reviewer`) Tier-1 dark-pattern finding is treated as a compliance-class finding for the Severity ladder's no-unilateral-downgrade rule: not reclassified below major without the raising org's recorded concurrence. | Keeps the guardrail from being quietly defeated at PM triage — the same protection compliance/security findings already have. |
| D28 | **Taxonomy anchored on established deceptive-design categories + regulatory hooks, kept token-frugal; plugin content stays project-agnostic.** Named categories (sneaking, urgency, misdirection, social proof, scarcity, obstruction, forced action, nagging, confirmshaming, disguised ads, trick wording, hard-to-cancel) plus regime pointers (EU DSA Art. 25, GDPR consent/Art. 7, FTC Act §5 — "and jurisdiction-specific equivalents"). No project-domain examples in plugin content (they trip the zero-coupling audit and belong in the project rubric). | A concrete, named taxonomy makes the guardrail checkable rather than vibes-based; regulatory hooks give the reviewer somewhere to verify. Token-frugality matters because planner/implementer/PM all reference the doctrine. |
| D29 | **The reviewer's doctrine read is trigger-gated and size-budgeted, not unconditional.** `pr-reviewer` runs a cheap keyword/surface-signal scan on every review; it reads `product-ethics.md` (and the project rubric extension, only when non-empty) **only** when that scan hits a user-facing copy/consent/default/flow signal — the findings-index trigger mechanism, reused. A miss records a one-line skip and reads nothing. The doctrine is capped at a lean named-list (~≤500 words), pinned by a `check.sh` word-count bound. | The always-on review home (D25) must not become an always-*read* on every user-facing PR — for a UI-heavy product that is a real recurring cost. Gating the full read behind a cheap signal, and bounding the doctrine's size, keeps the hotspot proportional to the actual dark-pattern surface, not to PR count. |

## 4. Architecture

One doctrine, four touch-points, one project extension:

```
skills/reviewing-prs/product-ethics.md   ← canonical doctrine (plugin-owned, project-agnostic)
        ▲            ▲            ▲            ▲
        │            │            │            │  (referenced by path; full read only on a dark-pattern smell)
   PM reflex    product-planner  implementer  pr-reviewer   ← + compliance-reviewer (regulatory angle)
 (commands/     (don't propose)  (don't       (detect,
  pm-loop.md)                     introduce)   always-applied)

templates/rubric/product-ethics.md  ──/pm-loop-init scaffold──▶  .claude/pm/rubric/product-ethics.md
   (project-agnostic stub, plugin)                                 (project's domain examples / bright lines)
```

Each role carries a **short, role-specific instruction** and a **pointer** to the doctrine; the
full doctrine is read only when a dark-pattern smell is present (the plugin's established
"read when the trigger matches" pattern), so per-dispatch token cost stays near zero.

## 5. The doctrine — `skills/reviewing-prs/product-ethics.md` (new)

A lean, project-agnostic file with pinned headings:

- **Intro** — what the doctrine is; who applies it (all pm-loop roles); that it is always on and
  extended, never overridden, by `.claude/pm/rubric/product-ethics.md`.
- **`## What counts`** — the named dark-pattern taxonomy (D28 list), each as one line: the
  category and its tell. Closes with the **boundary test** (D26) distinguishing dark patterns
  from legitimate persuasion, and the note that project-specific examples/bright-lines live in
  the rubric extension.
- **`## Two-tier response`** — Tier 1 (hard-refuse) vs Tier 2 (push-back → reconsider → record),
  per D23, written role-neutrally so the PM, planner, and implementer all apply the same ladder.
- **`## For reviewers`** — the **trigger gate first** (D29): a cheap keyword/surface-signal scan
  of the diff (does it add or change user-facing copy, consent, defaults, or flows?). A **miss**
  records a one-line skip and reads nothing further. Only on a **hit** does the reviewer read
  this doctrine (and the project rubric extension, when non-empty) and file the finding: a Tier-1
  pattern is a **blocker** (and carries D27 downgrade protection), a Tier-2 pattern is
  **major/minor** by user-harm; frame it as {pattern name → what in the diff triggers it →
  honest remediation} and post it in the skill's standard comment format with a "Suggested fix
  prompt."

The regulatory pointers (DSA/GDPR/FTC + "jurisdiction-specific equivalents") appear inline in
`## What counts`/`## For reviewers` as orientation, not as a compliance-mode gate.

**Size budget (D29):** the doctrine stays a lean named-list — target **~≤500 words**, pinned by
a `check.sh` word-count bound. Every role that reads it pays for its length, so bloat is a
regression the gate catches, not a style nit.

## 6. Project extension — `templates/rubric/product-ethics.md` (new stub)

Mirrors the existing rubric stubs (`templates/rubric/compliance.md` shape): a short,
project-agnostic guided placeholder inviting the project to list its **domain-specific**
dark-pattern examples and bright lines, and any **documented legitimate-persuasion carve-outs**
(e.g. "a genuine limited-inventory badge backed by real stock is allowed"). Scaffolded to
`.claude/pm/rubric/product-ethics.md` by `/pm-loop-init`. Empty is valid — the doctrine's own
taxonomy still applies.

## 7. Role touch-points

### 7.1 PM orchestrator — `commands/pm-loop.md` (G2 reflex)

A new short **Product-ethics reflex** subsection, applied at two moments:

- **At Scope (Loop step 1), before creating issues:** if the human's task embodies a dark
  pattern, apply the doctrine's two-tier response *first* — Tier 1: decline and offer the honest
  alternative; Tier 2: name the pattern, explain user-harm + business risk, propose an honest
  alternative, and proceed only on explicit human reconfirmation, **recording that reconfirmation
  as a `decision` knowledge entry** (`decisions.md`, dated) so the review orgs and future runs
  see it was a deliberate, human-owned call.
- **When presenting planner proposals (ideation branch):** any proposal that embodies a dark
  pattern is surfaced with the same send-back framing, consistent with how feasibility flags are
  already carried into the presentation.

Written as a pointer to the doctrine plus the reflex behavior — not a re-statement of the
taxonomy.

### 7.2 `product-planner` — `agents/product-planner.md` (G1: don't propose)

One clause in the existing `## Restraint` section: **never propose a dark pattern**; if a
reference product (research axis 3) uses one, do not copy it — note it as an anti-pattern
instead; and add product-ethics to the surfaces it already **flags** (alongside security and
compliance) in each proposal's Risks/flags. Pointer to the doctrine for the definition.

### 7.3 `implementer` — `agents/implementer.md` (G1: don't introduce)

One clause alongside the existing "honor `## Project` constraints / don't expand scope": **do
not introduce a dark pattern**; if the issue or its design brief requires one, **flag and stop**
(same posture as its existing "if scope grows mid-implementation, note it and stop") rather than
build it. Pointer to the doctrine. **Carve-out:** when a dated `decision` in
`.claude/pm/knowledge/decisions.md` records that the PM already obtained the human's explicit
reconfirmation for a specific Tier-2 pattern (the PM reflex's Tier-2 path, §7.1), the implementer
builds it per that decision and the review orgs re-flag — so the documented Tier-2 "proceed on
reconfirmation" path completes end-to-end.

### 7.4 `pr-reviewer` + `reviewing-prs` skill — `SKILL.md` (G1: detect)

- **`SKILL.md`** gains a **`## Product ethics`** section (sibling to `## Compliance`): the
  **check** always runs for the code-review org (`pr-reviewer`) and is explicitly *not* gated by
  the profile's `## Compliance` mode — but it is **trigger-gated** (D29): a cheap signal scan
  runs every review, and the doctrine + project rubric extension are read only on a
  user-facing-surface hit (copy, consent, defaults, flows); a miss records a one-line skip and
  reads nothing. Full doctrine and severity mapping live in `product-ethics.md`. The section also
  amends the **Severity ladder**'s no-unilateral-downgrade note to include Tier-1 dark-pattern
  findings (D27).
- **`agents/pr-reviewer.md`** step 2 gains one clause: run the skill's **Product ethics** signal
  scan, and read + apply `product-ethics.md` only on a user-facing-surface hit — pointer-only, no
  taxonomy restated.

### 7.5 `compliance-reviewer` — `agents/compliance-reviewer.md` (regulatory angle)

One line: regulated dark patterns (DSA Art. 25 / GDPR consent / FTC-style deception) are in
scope **within the profile's declared `## Compliance` domains** — the always-on home is
`pr-reviewer`, so `compliance: off` never removes the guardrail; this is additive coverage where
a declared domain regulates deceptive design. No behavior change when no such domain is declared.

### 7.6 `/pm-loop-init` — `commands/pm-loop-init.md`

Scaffold step 3 copies the `rubric/` tree; update its parenthetical from "(all three)" to "(all
four)" so the new `product-ethics.md` stub scaffolds with the others. No new interview question —
the guardrail is always on, so there is nothing to ask.

### 7.7 `README.md`

A new short **Product-ethics guardrail** subsection near **Deterministic guardrails**: the loop
never originates dark patterns and pushes back (with a reconsider prompt) when asked for one;
the two-tier response in one sentence; that it is always on and cannot be disabled; and that
projects extend—never override—it via `.claude/pm/rubric/product-ethics.md`.

## 8. Gate additions — `scripts/check.sh`

Every addition is mechanical and pinned, per the repo's D21 posture:

- **Required files** += `skills/reviewing-prs/product-ethics.md`,
  `templates/rubric/product-ethics.md`.
- `require_heading skills/reviewing-prs/SKILL.md '^## Product ethics'`.
- `require_heading skills/reviewing-prs/product-ethics.md '^## What counts'`,
  `'^## Two-tier response'`, `'^## For reviewers'`.
- **Doctrine size budget** (D29): a `wc -w` bound on `skills/reviewing-prs/product-ethics.md`
  (≤ ~550 words, small headroom over the ~500 target) so the file every role reads cannot
  silently bloat.
- **Cross-file wiring** (grep -F): `commands/pm-loop.md`, `agents/product-planner.md`,
  `agents/implementer.md`, and `agents/pr-reviewer.md` each reference `product-ethics`
  (`Product ethics` / the doctrine path).
- **Zero-coupling:** the new plugin files must pass the existing project-agnostic audit
  (§3 of `check.sh`) — no domain tokens, no project-specific examples (those live in the project
  rubric extension only).
- **Version consistency** (existing check 5i): `plugin.json` and `marketplace.json` both bump.

## 9. Token accounting (expected, per typical mixed run)

| Change | Delta |
|---|---|
| Doctrine file (`product-ethics.md`) | ~0 per dispatch — roles carry a one-line pointer; full read only on a dark-pattern smell |
| PM reflex | +1 short subsection read once by the PM per run |
| Planner / implementer clauses | +1 line each in files already read |
| `pr-reviewer` signal scan | a cheap keyword scan on every review; **no doctrine read on a miss** (backend-only diff = one-line skip) |
| `pr-reviewer` doctrine + rubric read | **only on a user-facing-surface hit** (D29) — proportional to actual dark-pattern surface, not to PR count; for UI-heavy products it fires often, which is the intended coverage |
| Project rubric extension | read only on a hit, and only when non-empty |

Net: negligible for typical runs; the cost lands only where a dark-pattern surface actually
exists, which is the point.

## 10. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Crying wolf — flagging every countdown/default as a dark pattern | Explicit persuasion-vs-manipulation boundary test (D26); project carve-outs in the rubric extension. |
| Guardrail quietly downgraded at PM triage | Tier-1 findings carry no-unilateral-downgrade protection (D27). |
| `Compliance: off` silently removing protection | Review home is `pr-reviewer`, always-applied and explicitly not compliance-gated (D25). |
| Doctrine living under `skills/reviewing-prs/` reads as review-only | Deliberate (matches the compliance-rubric precedent, which the planner also reads); the file's intro states it is cross-cutting and referenced by all roles. |
| Plugin content picking up project-specific examples | D28 + zero-coupling audit: examples live only in the project rubric extension; plugin taxonomy stays generic. |
| Token bloat from a new doc every role reads | Pointer-plus-lazy-read (§4); the reviewer's read is trigger-gated (D29), not per-PR; doctrine size-bounded by a `check.sh` word-count check. |
| Tier boundary ambiguity (is this deceptive or just manipulative?) | Two-tier ladder is defined by *deception/illegality* vs *legal manipulation*; when unsure, treat as the higher tier (consistent with "when in doubt, scale up"). |

## 11. File-touch summary

| File | Change |
|---|---|
| `skills/reviewing-prs/product-ethics.md` | **new** — canonical doctrine (§5) |
| `templates/rubric/product-ethics.md` | **new** — project extension stub (§6) |
| `skills/reviewing-prs/SKILL.md` | `## Product ethics` section; Severity-ladder downgrade-protection amendment (§7.4) |
| `agents/pr-reviewer.md` | one clause in step 2 — apply Product ethics on user-facing diffs |
| `commands/pm-loop.md` | **Product-ethics reflex** subsection (Scope + planner-proposal moments); records Tier-2 reconfirmation as a `decision` |
| `agents/product-planner.md` | `## Restraint` clause — never propose; flag ethics surfaces |
| `agents/implementer.md` | clause — never introduce; flag-and-stop if required |
| `agents/compliance-reviewer.md` | one line — regulatory dark patterns in scope within declared domains |
| `commands/pm-loop-init.md` | "(all three)" → "(all four)" rubric scaffold |
| `README.md` | Product-ethics guardrail subsection |
| `scripts/check.sh` | gate additions (§8) |
| `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` | version → `0.3.0` at release |

## 12. Acceptance

Prompt/doc changes are verified by `check.sh` plus scenario walk-throughs (the M3 acceptance-run
style):

1. `scripts/check.sh` passes with all new checks in place (headings, required files, cross-file
   wiring, zero-coupling, version bump).
2. **Doctrine coherence:** the taxonomy, the boundary test, and the two-tier response are
   internally consistent; every role file carries a working pointer to the doctrine.
3. **Scenario — human requests a Tier-2 pattern:** "add a fake countdown timer to the checkout"
   → PM reflex names the pattern, explains the harm, proposes an honest alternative (a real
   deadline or none), and proceeds only on explicit reconfirmation, recording it in
   `decisions.md`. A *real* deadline's countdown is **not** flagged (boundary test).
4. **Scenario — human requests a Tier-1 pattern:** "hide the cancellation link / pre-tick the
   data-sale consent" → PM declines and offers the honest alternative; does not build it on
   insistence.
5. **Scenario — planner restraint:** a proposal set contains no dark pattern even when a cited
   reference product uses one (it is noted as an anti-pattern instead).
6. **Scenario — reviewer detection:** a PR that adds confirmshaming copy draws a `pr-reviewer`
   finding at the right tier **even with `Compliance: off`**; a backend-only PR records a
   one-line product-ethics skip.
7. **Consumer compatibility:** a v0.2-initialized repo missing `.claude/pm/rubric/product-ethics.md`
   still runs — the doctrine's own taxonomy applies; `/pm-loop-init` re-run scaffolds the missing
   stub idempotently (never overwrites).
