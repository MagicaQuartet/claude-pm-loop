---
description: Bootstrap this repository as a pm-loop consumer — scaffold .claude/pm/ (profile, knowledge base, findings, rubric)
---

Bootstrap the current repository as a pm-loop consumer.

## Procedure

1. **Gather signal:** read `CLAUDE.md`/`README` if present, `git remote -v`,
   the default branch, and any build/test manifests you find at the repo root.
   Use them to pre-fill profile defaults — never to invent facts.
2. **Offer two paths, then gather what you cannot infer.** Ask the user to
   pick: the **interview** below, or **Quick setup** (its own section).
   Interview: one question at a time:
   quality-gate commands (the literal list + blocking/advisory), risk classes
   (offer the profile template's examples as a starting shape), compliance
   mode (`full`/`minimal`/`off`) and domains, base branch if ambiguous.
3. **Scaffold:** copy the tree at `${CLAUDE_PLUGIN_ROOT}/templates/` into
   `.claude/pm/` — `profile.md` (filled with gathered + interviewed values;
   keep unanswered optional sections — including `## Review diversity`, which
   is never interviewed — as the template's guided placeholders),
   `knowledge/` (all five stores), `findings/index.md`, `rubric/` (all
   three). If `${CLAUDE_PLUGIN_ROOT}` is unset or unexpanded, locate the
   installed plugin under `~/.claude/plugins/` (the marketplace cache) and
   use its `templates/` instead. Create an empty `.claude/pm/plans/`
   directory.
4. **Gitignore:** ensure `.claude/pm/plans/` is git-ignored (append to
   `.gitignore` if needed); everything else under `.claude/pm/` is meant to
   be committed and reviewed.
5. **Report:** list created vs skipped files, then suggest committing the
   scaffold and running `/pm-loop <first task>`.

## Quick setup

The one-round alternative to the interview:

1. Gather signal (step 1 above) and fill a complete `profile.md` draft.
2. Present the entire draft in **one message**, tagging every value
   `(inferred)` or `(default)`.
3. **Never silently default a safety field.** If compliance mode or risk
   classes are left at a default, the same message carries a one-line callout
   each — e.g. "Compliance is `off` — change this if the project touches
   regulated domains"; "Risk classes are empty — declare classes if any
   change type deserves heavier review."
4. One confirm-or-edit round, then scaffold (steps 3–5 above). Idempotency
   rules apply unchanged.

## Idempotency

Never overwrite an existing file under `.claude/pm/` — report it as skipped.
Re-running on a bootstrapped repo is a no-op that just reports state. It is
always safe to run this command to fill in files a partial bootstrap missed.
