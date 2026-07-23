# Security (deep)

The security org's (`security-reviewer`) rubric, referenced from the shared `SKILL.md`.

Applied by the security org (`security-reviewer`).

- Every new privileged data path is covered by the project's access-control model (per the profile's `## Security model`) — never implicitly trust client input.
- Authentication & authorization: every protected route, action, and mutation is guarded; users can act only within their permissions.
- Input validation on all user-supplied data, enforced server side (not only in the client).
- Secrets are never committed or logged; they are read from env.
- The profile's named sensitive flows are checked for double-execution, reconciliation (do totals/amounts add up), per-actor authorization (each actor acts only on their own share), and partial-failure handling.
