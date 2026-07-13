---
name: docs-update
description: Update an existing Diátaxis-structured docs/ directory (created by docs-init) to reflect a recent code change, without re-surveying or restructuring the whole project. Use right after making a change with Claude Code, or point it at a specific commit range / set of uncommitted changes, to keep tutorials/how-to-guides/reference/explanation in sync incrementally.
---

# docs-update

Incrementally updates `docs/` after a change — the cheap, targeted alternative to a full `docs-init` reconcile.

Assumes `docs/` already exists following the `docs-init` convention: `tutorials`, `how-to-guides`, `reference`, `explanation`, each either a flat `docs/<quadrant>.md` or a directory with a `README.md` landing page plus topic files. If `docs/` doesn't exist yet or doesn't follow this convention, stop and tell the user to run `/docs-init` first instead.

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

If the change plausibly needs a quadrant that doesn't exist yet (e.g. the project just got its first CLI flag and never had `reference`), create it, following the same layout and content rules as `docs-init`.

If the change added markdown next to code (a runbook, a nested `docs/` tree), apply `docs-init`'s code-adjacent rule: the content belongs in a quadrant; a code-adjacent `README.md` stays only as a lean pointer.

## 3. Content rules (same as docs-init)

Relative links only, Mermaid for architecture/flow diagrams, one Diátaxis mode per page, concise Markdown, no invented content — use `<!-- TODO: verify -->` for genuine gaps; trim verifiable stale claims on touch. Fixed quadrant names: `tutorials`, `how-to-guides`, `reference`, `explanation`; `README.md` (never `index.md`) as directory landings; nothing in `docs/` besides the quadrants, the `README.md` router, and (with a site generator) `assets/`.

## 4. Renames and moves ripple beyond docs/

If this update moves or renames a page, follow `docs-init`'s repointing rule: grep the whole repo (code docstrings, configs, CI, tests, `CLAUDE.md`/`.claude/`) and update every reference, and update the site-generator nav if one exists. Then verify: resolve the affected relative links, and build the site if there is one.

## 5. Finish with a summary

Report which quadrant(s)/file(s) were touched and why, and anything skipped because it seemed out of scope for this change — so the user can catch it if the scope was guessed wrong.
