# 0006. Record docs preferences in `CLAUDE.md`, and let them override style but not verification

- **Status**: Accepted
- **Date**: 2026-08-13

## Context

`docs-edit` ([ADR 0005](0005-split-docs-skills-by-trigger.md)) lets a user change how their docs read. Applying that change is easy; keeping it is not. `docs-update` and `docs-init` are written to pull pages back toward the convention, and from inside a repo a deliberate deviation and ordinary drift look identical — so an unrecorded preference survives only until the next run corrects it. "Make the docs consistent with how I want them" is therefore a storage problem before it is a writing problem.

The obvious options were a dedicated file (`.docs-preferences.md` or similar), a block inside the docs themselves, or the project's `CLAUDE.md`. A dedicated file needs a format, a loader, and a rule in every skill to go read it. A block inside `docs/` would be reader-facing content that isn't documentation. `CLAUDE.md` is already loaded into every Claude Code session in that project, and users already edit it.

The second question is what a preference is allowed to override. Style is uncontroversial. Structure is the point of the convention, and verification against the repo is the rule that keeps the docs honest.

## Decision

Preferences live in a `## Docs preferences` block in the project's `CLAUDE.md`, or `~/.claude/CLAUDE.md` when they span projects. `docs-edit` writes them when a request is phrased durably ("always", "from now on", "I prefer"); all four skills read them at the start of a run.

They override style freely. They may override structure, but only as an override recorded with its reason, so a later run reads intent rather than a mistake to fix. They may not override verification: no preference can stop a skill checking a factual claim against the repo.

## Consequences

- A preference survives every later run, which is what makes the customization real rather than per-session.
- No new machinery: no file format, no loader, no install step, and the user can read and edit their own preferences in a file they already know.
- The convention becomes negotiable at the edges without becoming unenforced, because every deviation is written down where the next run will see it.
- `CLAUDE.md` is a shared, hand-edited file. A skill writing into it must append to one block and leave everything else alone, and a user who reorganizes their `CLAUDE.md` can silently detach the block.
- Preferences are prose, not schema. Two of them can contradict each other, and nothing validates that — the conflict surfaces only when a run tries to honor both.
- Projects genuinely diverge in style now, which is a real cost against the "identical everywhere" goal of [ADR 0004](0004-wrap-diataxis-in-a-fixed-structure.md). Paths stay identical; only the writing moves, and only where someone asked.
