---
name: docs-update
description: Update an existing Diátaxis-structured docs/ directory (created by docs-init) to reflect a recent code change, without re-surveying or restructuring the whole project. Use right after making a change with Claude Code, or point it at a specific commit range / set of uncommitted changes, to keep tutorials/how-to-guides/reference/explanation in sync incrementally.
---

# docs-update

Incrementally updates `docs/` after a change — the cheap, targeted alternative to a full `docs-init` reconcile.

Assumes `docs/` already exists following the `docs-init` convention: `tutorials`, `how-to-guides`, `reference`, `explanation`, each either a flat `docs/<quadrant>.md` or a directory with an `index.md` plus topic files. If `docs/` doesn't exist yet or doesn't follow this convention, stop and tell the user to run `/docs-init` first instead.

## 1. Determine the scope of the change

- If invoked in the same conversation where the change was just made, use that context directly — don't re-scan the whole repo.
- If invoked fresh (new session, or pointed at something specific), determine scope from what's available: uncommitted changes (`git diff`/`git status`), or a commit range/PR the user names. If neither is available and nothing is obvious, ask the user what changed.

## 2. Update only what the change touches

For each quadrant, ask whether *this specific change* affects it:
- New/changed CLI flags, API endpoints, config keys → `reference`
- New/changed project-local Claude Code skill or slash command (`.claude/skills/`, `.claude/commands/`) → `reference` (list it), and `how-to-guides` too if it changes how a user/operator accomplishes a task
- New setup/deploy/troubleshooting step, or an existing recipe now behaves differently → `how-to-guides`
- Architecture, data flow, or a design decision changed → `explanation` (update Mermaid diagrams if the flow changed)
- A new onboarding-relevant capability that changes the learning path → `tutorials`

Don't touch quadrants the change doesn't affect, and don't restructure existing files beyond what this change actually requires — except promoting a flat file to a directory is still fine if this change is what pushes that quadrant past one topic (same rule as `docs-init`).

If the change plausibly needs a quadrant that doesn't exist yet (e.g. the project just got its first CLI flag and never had `reference`), create it, following the same file-vs-directory and content rules as `docs-init`.

## 3. Content rules (same as docs-init)

Relative links only, Mermaid for architecture/flow diagrams, concise Markdown, no invented content — use `<!-- TODO: verify -->` for genuine gaps. Fixed quadrant names: `tutorials`, `how-to-guides`, `reference`, `explanation`.

## 4. Finish with a summary

Report which quadrant(s)/file(s) were touched and why, and anything skipped because it seemed out of scope for this change — so the user can catch it if the scope was guessed wrong.
