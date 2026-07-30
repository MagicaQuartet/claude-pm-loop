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
