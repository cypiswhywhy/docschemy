---
name: docs-update
description: Update an existing Diátaxis-structured docs/ directory (created by docs-init) to reflect a recent code change, without re-surveying or restructuring the whole project. Adds docs for what the change added and deletes docs for what it removed, keeping page names consistent with their siblings. Use right after making a change with Claude Code, or point it at a specific commit range / set of uncommitted changes, to keep tutorials/how-to-guides/reference/explanation in sync incrementally.
---

# docs-update

Incrementally updates `docs/` after a change — the cheap, targeted alternative to a full `docs-init` reconcile.

Assumes `docs/` already exists following the `docs-init` convention: `tutorials`, `how-to-guides`, `reference`, `explanation`, each either a flat `docs/<quadrant>.md` or a directory with a `README.md` landing page plus topic files. If `docs/` doesn't exist yet or doesn't follow this convention, stop and tell the user to run `/docs-init` first instead.

## 1. Determine the scope of the change

- If invoked in the same conversation where the change was just made, use that context directly — don't re-scan the whole repo.
- If invoked fresh (new session, or pointed at something specific), determine scope from what's available: uncommitted changes (`git diff`/`git status`), or a commit range/PR the user names. If neither is available and nothing is obvious, ask the user what changed.
- **Read the diff for removals as carefully as for additions.** Deleted files, renamed symbols, dropped CLI flags and config keys, and removed dependencies are all in-scope changes — `git diff --stat` and `git diff --diff-filter=DR --name-status` surface them directly. Write down the removed names; §3 needs them.

## 2. Update only what the change touches

For each quadrant, ask whether *this specific change* affects it:
- New/changed CLI flags, API endpoints, config keys → `reference`
- New/changed project-local Claude Code skill or slash command (`.claude/skills/`, `.claude/commands/`) → `reference` (list it), and `how-to-guides` too if it changes how a user/operator accomplishes a task
- New setup/deploy/troubleshooting step, or an existing recipe now behaves differently → `how-to-guides`
- Architecture, data flow, or a design decision changed → `explanation` (update Mermaid diagrams if the flow changed)
- A new onboarding-relevant capability that changes the learning path → `tutorials`

Don't touch quadrants the change doesn't affect, and don't restructure existing files beyond what this change actually requires. Two things always count as required: promoting a flat file to a directory when this change is what pushes that quadrant past one topic, and renaming siblings so a new page fits the naming pattern (§4) — both are the same rules `docs-init` applies.

If the change plausibly needs a quadrant that doesn't exist yet (e.g. the project just got its first CLI flag and never had `reference`), create it, following the same layout and content rules as `docs-init`.

If the change added markdown next to code (a runbook, a nested `docs/` tree), apply `docs-init`'s code-adjacent rule: the content belongs in a quadrant; a code-adjacent `README.md` stays only as a lean pointer.

## 3. Remove what the change removed

An update is not done when the new behavior is described — it's done when the old behavior is gone. This is the step that gets skipped, so run it explicitly rather than folding it into §2.

For every name on the removals list from §1 (deleted file, dropped flag, retired config key, removed command, renamed symbol), grep all of `docs/` for it and act on each hit:

- **A section about it** → delete the section.
- **A whole page about it** → delete the page, then grep the repo for links to that path — the quadrant's `README.md` landing, the `docs/README.md` router, the root `README.md`, sibling pages, site-generator nav, `CLAUDE.md`/`.claude/` — and remove every one (§5 covers the mechanics; it applies to deletions exactly as it does to moves).
- **A renamed thing** → rename it in the docs too, everywhere, not just on the page you were already editing.
- **The last page in a directory quadrant** → collapse the directory back to a flat `docs/<quadrant>.md` if only one topic remains.
- **A quadrant whose entire subject is gone** → delete it, and drop it from the `docs/README.md` router.

Then check what the removal *implies*: a deleted feature usually also appears in a how-to's prerequisites, a tutorial step, or an architecture diagram in `explanation` — grep hits point at the page, but Mermaid node labels and prose paraphrases won't match the grep. Re-read any page that mentioned the removed thing end to end.

Delete rather than mark deprecated, unless the project actually ships a deprecation period for that surface — in which case say what replaces it and when it goes away, and don't leave the note undated. Git holds the history either way.

If a doc describes something you can no longer find in the repo but the diff doesn't show it being removed, don't delete on a hunch — flag it in the summary and let the user decide.

## 4. Content rules (same as docs-init)

Relative links only, Mermaid for architecture/flow diagrams, one Diátaxis mode per page, concise Markdown, no invented content — use `<!-- TODO: verify -->` for genuine gaps; trim verifiable stale claims on touch. Fixed quadrant names: `tutorials`, `how-to-guides`, `reference`, `explanation`; `README.md` (never `index.md`) as directory landings; nothing in `docs/` besides the quadrants, the `README.md` router, and (with a site generator) `assets/`.

**Naming a new page** follows `docs-init`'s naming rule, and this is where it's easiest to get wrong: an incremental update sees one page at a time, so it invents a fresh name instead of extending a pattern. Before writing a new file, list the quadrant's existing files. If any of them cover the same subject, join that group — shared `<subject>-<qualifier>.md` prefix, or the existing `<subject>/` subdirectory, whichever is already in use. If the group would reach roughly four pages, promote it to a subdirectory now (and repoint per §5). If the pattern only becomes obvious once your new page exists, rename the older siblings to match rather than shipping the odd one out.

## 5. Renames, moves and deletions ripple beyond docs/

If this update moves, renames, or deletes a page, follow `docs-init`'s repointing rule: grep the whole repo (code docstrings, configs, CI, tests, `CLAUDE.md`/`.claude/`) and update every reference — for a deletion that means removing the link, not repointing it — and update the site-generator nav if one exists. Then verify: resolve every relative link in the affected pages *and* in anything that linked to them, and build the site if there is one. A link check that only covers files you edited will miss the landing page that still lists a page you deleted.

## 6. Finish with a summary

Report which quadrant(s)/file(s) were touched and why, what was deleted or renamed, and anything skipped because it seemed out of scope for this change — so the user can catch it if the scope was guessed wrong. Call out separately anything that looked stale but wasn't part of this change, so the user can decide whether it needs a full `/docs-init` reconcile.
