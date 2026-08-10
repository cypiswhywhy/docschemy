# 0001. Symlink skills into `~/.claude/skills` instead of copying them

- **Status**: Accepted
- **Date**: 2026-07-07

## Context

Recorded retroactively from the original `Makefile` (commit `b47e00d`) and the rationale that was written up in the repo's own docs.

Claude Code loads skills from `~/.claude/skills/`. This repo wants to be the single source of truth for a set of skills used across many unrelated projects, which means an installer that publishes each skill to that location. The obvious implementation is a copy.

A copy has one disqualifying property: the moment a skill is edited — here or there — the two diverge, and the stale one is the copy Claude Code actually reads. Editing a skill is the common operation, not installing one, so an install step standing between an edit and its effect would be paid constantly.

## Decision

`make install` creates a symlink per skill directory, from `~/.claude/skills/<name>` to `skills/<name>` in this checkout. Nothing is ever copied.

The installer refuses to overwrite: a path that already exists and is not a symlink into this repo is reported and skipped, never replaced.

## Consequences

- Editing a skill takes effect immediately in every project, with no reinstall. Only frontmatter changes need a Claude Code reload, because that is what gets indexed at startup.
- There is exactly one copy of every skill and it is under version control, so "which one is current" is never a question.
- `~/.claude/skills/` now depends on this repo staying checked out at a fixed path. The symlinks are absolute; moving the clone breaks all of them until `make install` runs again. This is the accepted cost.
- The refuse-to-overwrite rule means a name collision with a hand-installed or third-party skill has to be resolved by hand. That asymmetry is deliberate: a skill lost from this repo is a `git checkout` away, one installed by hand is not.
