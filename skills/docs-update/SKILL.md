---
name: docs-update
description: Update an existing Diátaxis-structured docs/ directory (created by docs-init) to reflect a recent code change, without re-surveying or restructuring the whole project. Adds docs for what the change added and deletes docs for what it removed, keeps diagrams and figures in sync with the new shape, and keeps page names consistent with their siblings. Use right after making a change with Claude Code, or point it at a specific commit range / set of uncommitted changes, to keep tutorials/how-to-guides/reference/explanation in sync incrementally.
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
- Architecture, data flow, or a design decision changed → `explanation`
- A new onboarding-relevant capability that changes the learning path → `tutorials`

**Then ask the same question of the visuals, separately.** Diagrams are the part of a page that goes stale invisibly — prose reads plausibly wrong, a diagram reads *authoritatively* wrong. So for every page you touch, and every page whose subject this change reshaped:

- A new or removed component, endpoint, queue, or dependency → it belongs in (or must come out of) the flowchart that shows the system.
- A changed call order, retry, or protocol step → the `sequenceDiagram` is now lying; fix it.
- A new status value or transition → update the `stateDiagram-v2`.
- A schema/model change → update the `erDiagram`.
- A UI change → any screenshot of that screen is now wrong. Re-capture it, or delete it and say what it showed.
- If the change introduces something structural that no diagram covers yet, add one (`docs-init` §8 covers form, type selection, and where files live) rather than describing the new topology in a paragraph.

**Before writing anything new, check whether it already has a home.** This is the incremental blind spot: seeing one page at a time is precisely how a second copy of a fact gets created, and duplication doesn't stay duplicated — it drifts, leaving a reader no way to tell which copy is current. So grep `docs/` for the subject (the flag name, the command, the component) before adding a page or a section:

- **It's already documented and still correct** → link to it; don't restate it.
- **It's already documented but now wrong** → edit that page. Don't write a fresh, correct section beside a stale one.
- **It's documented in the wrong quadrant** → move it rather than adding a second copy in the right one (§5 covers repointing).
- **It's genuinely new** → write it once, in the quadrant matching its Diátaxis mode, and link from anywhere else that needs it.

`docs-init` §9 has the full rule; this is the part of it an incremental run can enforce without re-reading every page.

Don't touch quadrants the change doesn't affect, and don't restructure existing files beyond what this change actually requires. Two things always count as required: promoting a flat file to a directory when this change is what pushes that quadrant past one topic, and renaming siblings so a new page fits the naming pattern (§4) — both are the same rules `docs-init` applies.

If the change plausibly needs a quadrant that doesn't exist yet (e.g. the project just got its first CLI flag and never had `reference`), create it, following the same layout and content rules as `docs-init`.

If the change added markdown next to code (a runbook, a nested `docs/` tree), apply `docs-init`'s code-adjacent rule: the content belongs in a quadrant; a code-adjacent `README.md` stays only as a lean pointer.

## 3. Remove what the change removed

An update is not done when the new behavior is described — it's done when the old behavior is gone. This is the step that gets skipped, so run it explicitly rather than folding it into §2.

For every name on the removals list from §1 (deleted file, dropped flag, retired config key, removed command, renamed symbol), grep all of `docs/` for it and act on each hit:

- **A section about it** → delete the section.
- **A whole page about it** → delete the page and any figure in `docs/assets/` that only it referenced (grep the filename across `docs/` first — shared figures stay), then grep the repo for links to that path — the quadrant's `README.md` landing, the `docs/README.md` router, the root `README.md`, sibling pages, site-generator nav, `CLAUDE.md`/`.claude/` — and remove every one (§5 covers the mechanics; it applies to deletions exactly as it does to moves).
- **A renamed thing** → rename it in the docs too, everywhere, not just on the page you were already editing.
- **The last page in a directory quadrant** → collapse the directory back to a flat `docs/<quadrant>.md` if only one topic remains.
- **A quadrant whose entire subject is gone** → delete it, and drop it from the `docs/README.md` router.

Then check what the removal *implies*: a deleted feature usually also appears in a how-to's prerequisites, a tutorial step, or an architecture diagram in `explanation` — grep hits point at the page, but Mermaid node labels, alt text, and prose paraphrases won't match the grep. Re-read any page that mentioned the removed thing end to end, **and re-read every diagram on it node by node**: a removed component whose box still sits in the flowchart is a worse artifact than no diagram, because readers trust the picture over the prose. Same for screenshots — an image showing a removed button gets re-captured or deleted, never left because "it's mostly still right".

Delete rather than mark deprecated, unless the project actually ships a deprecation period for that surface — in which case say what replaces it and when it goes away, and don't leave the note undated. Git holds the history either way.

If a doc describes something you can no longer find in the repo but the diff doesn't show it being removed, don't delete on a hunch — flag it in the summary and let the user decide.

## 4. Content rules (same as docs-init)

Relative links only, one Diátaxis mode per page, concise Markdown, no invented content — use `<!-- TODO: verify -->` for genuine gaps; trim verifiable stale claims on touch. Fixed quadrant names: `tutorials`, `how-to-guides`, `reference`, `explanation`; `README.md` (never `index.md`) as directory landings; nothing in `docs/` besides the quadrants, the `README.md` router, and `assets/`.

**One canonical home per fact** (`docs-init` §9) — every other mention links to it. An incremental run enforces this going in (§2), not by auditing the whole tree; if you notice existing duplication outside this change's scope, report it in §6 rather than fixing it here.

**Visuals follow `docs-init` §8** in full: diagram-as-code by default, diagram type chosen from the content (`flowchart` / `sequenceDiagram` / `stateDiagram-v2` / `erDiagram`), one idea per diagram, figures in `docs/assets/` named after their page's subject, real alt text on every image, and nothing drawn that you didn't trace in the code. When you add a paragraph explaining how several pieces now fit together, that's the signal to draw it instead.

**Naming a new page** follows `docs-init`'s naming rule, and this is where it's easiest to get wrong: an incremental update sees one page at a time, so it invents a fresh name instead of extending a pattern. Before writing a new file, list the quadrant's existing files. If any of them cover the same subject, join that group — shared `<subject>-<qualifier>.md` prefix, or the existing `<subject>/` subdirectory, whichever is already in use. If the group would reach roughly four pages, promote it to a subdirectory now (and repoint per §5). If the pattern only becomes obvious once your new page exists, rename the older siblings to match rather than shipping the odd one out.

## 5. Renames, moves and deletions ripple beyond docs/

If this update moves, renames, or deletes a page, follow `docs-init`'s repointing rule: grep the whole repo (code docstrings, configs, CI, tests, `CLAUDE.md`/`.claude/`) and update every reference — for a deletion that means removing the link, not repointing it — and update the site-generator nav if one exists. Then verify: resolve every relative link **and `![…]()` figure path** in the affected pages *and* in anything that linked to them, and build the site if there is one. A link check that only covers files you edited will miss the landing page that still lists a page you deleted. Moving a page between a flat file and a directory changes its relative depth into `../assets/`, so figure paths break on exactly the moves where you're least looking at them — and a broken image renders as quiet alt text rather than an obvious 404.

## 6. Finish with a summary

Report which quadrant(s)/file(s) were touched and why, which diagrams or figures were updated, added, or removed, what was deleted or renamed, and anything skipped because it seemed out of scope for this change — so the user can catch it if the scope was guessed wrong. Call out separately anything that looked stale, duplicated, or orphaned but wasn't part of this change — this skill deliberately never opens pages the change didn't touch, so it can't vouch for them — and say plainly that a full `/docs-init` reconcile is what sweeps those.
