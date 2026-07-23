# Compliance

The compliance org's (`compliance-reviewer`) rubric, referenced from the shared `SKILL.md`.

Applied by the compliance org (`compliance-reviewer`), scoped to the domains the profile's `## Compliance` section declares.

- Identify what regulated data, copy, or flow the diff touches (e.g. personal data, age-gated content, payment/settlement, location, marketing copy).
- Map each touch to one of the profile's declared `## Compliance` domains — a touch that maps to no declared domain is out of scope for this review.
- Verify it against that domain's bright lines in the project's `.claude/pm/rubric/compliance.md` extension and the matching `.claude/pm/knowledge/domain/` files.
- Use `WebFetch`/`WebSearch` to confirm current requirements when a bright line is unclear or may have changed, rather than guessing.
- No domains declared, or the profile's `## Compliance` mode is `off` — there is nothing to apply; record the skip rather than reviewing ad hoc.
