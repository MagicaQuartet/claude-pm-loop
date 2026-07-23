---
description: Bootstrap this repository as a pm-loop consumer — scaffold .claude/pm/ (profile, knowledge base, findings, rubric)
---

Bootstrap the current repository as a pm-loop consumer.

## Procedure

1. **Gather signal:** read `CLAUDE.md`/`README` if present, `git remote -v`,
   the default branch, and any build/test manifests you find at the repo root.
   Use them to pre-fill profile defaults — never to invent facts.
2. **Interview the user** for what you cannot infer, one question at a time:
   quality-gate commands (the literal list + blocking/advisory), risk classes
   (offer the profile template's examples as a starting shape), compliance
   mode (`full`/`minimal`/`off`) and domains, base branch + merge style if
   ambiguous.
3. **Scaffold:** copy the plugin's `templates/` tree into `.claude/pm/` —
   `profile.md` (filled with gathered + interviewed values; keep unanswered
   optional sections as the template's guided placeholders), `knowledge/`
   (all five stores), `findings/index.md`, `rubric/` (all three). Create an
   empty `.claude/pm/plans/` directory.
4. **Gitignore:** ensure `.claude/pm/plans/` is git-ignored (append to
   `.gitignore` if needed); everything else under `.claude/pm/` is meant to
   be committed and reviewed.
5. **Report:** list created vs skipped files, then suggest committing the
   scaffold and running `/pm-loop <first task>`.

## Idempotency

Never overwrite an existing file under `.claude/pm/` — report it as skipped.
Re-running on a bootstrapped repo is a no-op that just reports state. It is
always safe to run this command to fill in files a partial bootstrap missed.
