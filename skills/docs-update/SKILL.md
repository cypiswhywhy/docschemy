---
name: docs-update
description: Update an existing docs/ structure (created by docs-init — README.md, CONTRIBUTING.md, docs/usage, docs/reference, docs/internals with ADRs) to reflect a recent code change, without re-surveying or restructuring the whole project. Routes new content into the right section, adds docs for what the change added and deletes docs for what it removed, records an ADR when a design decision changed, keeps diagrams and figures in sync with the new shape, and keeps page names consistent with their siblings. Use right after making a change with Claude Code, or point it at a specific commit range / set of uncommitted changes, to keep usage/reference/internals in sync incrementally.
---

# docs-update

Incrementally updates the docs after a change — the cheap, targeted alternative to a full `docs-init` reconcile.

Assumes the structure `docs-init` creates already exists: root `README.md` and `CONTRIBUTING.md`, and `docs/` holding `README.md`, `usage/`, `reference/`, `internals/` (with `adrs/`), and `assets/`. If the docs don't exist yet, or still use the older Diátaxis-only layout (`docs/tutorials`, `docs/how-to-guides`, `docs/explanation` at the top level), stop and tell the user to run `/docs-init` first — migrating between layouts is a reconcile job, not an incremental one.

If a *single* skeleton path is missing (say `docs/internals/adrs/`), create it with its landing page as part of this run rather than sending the user away — that's scaffolding, not restructuring.

## 1. Determine the scope of the change

- If invoked in the same conversation where the change was just made, use that context directly — don't re-scan the whole repo.
- If invoked fresh (new session, or pointed at something specific), determine scope from what's available: uncommitted changes (`git diff`/`git status`), or a commit range/PR the user names. If neither is available and nothing is obvious, ask the user what changed.
- **Read the diff for removals as carefully as for additions.** Deleted files, renamed symbols, dropped CLI flags and config keys, and removed dependencies are all in-scope changes — `git diff --stat` and `git diff --diff-filter=DR --name-status` surface them directly. Write down the removed names; §4 needs them.
- **Note changes to contributor-facing files specifically** — `Makefile`, task-runner scripts, CI workflows, tool-version pins, linter/pre-commit config, `.github/` templates. These don't touch `docs/` at all, which is exactly why they get missed; they are `CONTRIBUTING.md`'s scope (§3).

## 2. Route the change to a section

For each part of the change, ask **who it's for**, then **which Diátaxis mode it is** — the same routing table `docs-init` §2 uses:

| The change… | Home |
| --- | --- |
| adds/changes CLI flags, endpoints, config keys, env vars, schemas | `docs/reference/` |
| adds/changes a project-local Claude Code skill or slash command (`.claude/skills/`, `.claude/commands/`) | `docs/reference/` — and `docs/usage/` too if it changes how someone accomplishes a task |
| adds a setup/deploy/troubleshooting step, or makes an existing recipe behave differently | `docs/usage/` |
| changes architecture, data flow, or how something works internally | `docs/internals/` |
| makes or reverses a design decision | `docs/internals/adrs/` — a new ADR (§5) |
| changes the dev setup, test/lint commands, PR flow, or release process | `CONTRIBUTING.md` (overflowing to `docs/internals/development/`) |
| changes what the project *is*, or its install/quickstart command | root `README.md` |
| adds a learning-oriented onboarding path | `docs/usage/tutorials/` |

**The `usage/` boundary is strict** (`docs-init` §2): `usage/` documents the project as a black box. A new step that requires a source checkout, or names internal components, goes to `CONTRIBUTING.md` or `internals/` — not into a usage page because it happened to be about "running things".

**Then ask the same question of the visuals, separately.** Diagrams are the part of a page that goes stale invisibly — prose reads plausibly wrong, a diagram reads *authoritatively* wrong. So for every page you touch, and every page whose subject this change reshaped:

- A new or removed component, endpoint, queue, or dependency → it belongs in (or must come out of) the flowchart that shows the system.
- A changed call order, retry, or protocol step → the `sequenceDiagram` is now lying; fix it.
- A new status value or transition → update the `stateDiagram-v2`.
- A schema/model change → update the `erDiagram`.
- A UI change → any screenshot of that screen is now wrong. Re-capture it, or delete it and say what it showed.
- If the change introduces something structural that no diagram covers yet, add one (`docs-init` §11 covers form, type selection, and where files live) rather than describing the new topology in a paragraph.

**Before writing anything new, check whether it already has a home.** This is the incremental blind spot: seeing one page at a time is precisely how a second copy of a fact gets created, and duplication doesn't stay duplicated — it drifts, leaving a reader no way to tell which copy is current. So grep the docs *and* `README.md` and `CONTRIBUTING.md` for the subject (the flag name, the command, the component) before adding a page or a section:

- **It's already documented and still correct** → link to it; don't restate it.
- **It's already documented but now wrong** → edit that page. Don't write a fresh, correct section beside a stale one.
- **It's documented in the wrong section** → move it rather than adding a second copy in the right one (§6 covers repointing).
- **It's genuinely new** → write it once, in the section matching its audience and mode, and link from anywhere else that needs it.

`docs-init` §12 has the full rule; this is the part of it an incremental run can enforce without re-reading every page. The pairs to watch hardest here are `CONTRIBUTING.md` vs `docs/internals/` and `CONTRIBUTING.md` vs `docs/usage/`, because a change to the build touches both audiences at once.

Don't touch sections the change doesn't affect, and don't restructure existing files beyond what this change actually requires. Two things always count as required: creating a missing skeleton path this change needs (`usage/tutorials/`, `internals/development/`), and renaming siblings so a new page fits the naming pattern (§5) — both are the same rules `docs-init` applies.

If the change added markdown next to code (a runbook, a nested `docs/` tree), apply `docs-init`'s code-adjacent rule: the content belongs in a section; a code-adjacent `README.md` stays only as a lean pointer.

## 3. The root files are in scope too

`README.md` and `CONTRIBUTING.md` are part of the structure, not background furniture — and because they sit outside `docs/`, an update run that only looks at `docs/` will leave them stale indefinitely.

- **`README.md`** — touch it only when the change alters what §6 of `docs-init` puts there: the one-line description, the install command, the quickstart snippet, or a link target that moved. Everything else the change added belongs in a section, with the README linking to it. Resist growing the README.
- **`CONTRIBUTING.md`** — touch it when the change alters a prerequisite, a version pin, a setup step, a test/lint command, what CI enforces, the PR flow, or the release process. Every command you write must be traceable to the changed `Makefile`/CI/script, exactly as in `docs-init` §7; a `<!-- TODO: verify -->` beats a guess.

If a contributor procedure has now outgrown its section in `CONTRIBUTING.md`, move that procedure to `docs/internals/development/<topic>.md` and leave a one-line link — creating `development/` if it doesn't exist.

## 4. Remove what the change removed

An update is not done when the new behavior is described — it's done when the old behavior is gone. This is the step that gets skipped, so run it explicitly rather than folding it into §2.

For every name on the removals list from §1 (deleted file, dropped flag, retired config key, removed command, renamed symbol), grep all of `docs/`, `README.md` and `CONTRIBUTING.md` for it and act on each hit:

- **A section about it** → delete the section.
- **A whole page about it** → delete the page and any figure in `docs/assets/` that only it referenced (grep the filename across `docs/` first — shared figures stay), then grep the repo for links to that path — the section's `README.md` landing, the `docs/README.md` router, the root `README.md`, `CONTRIBUTING.md`, sibling pages, site-generator nav, `CLAUDE.md`/`.claude/` — and remove every one (§6 covers the mechanics; it applies to deletions exactly as it does to moves).
- **A renamed thing** → rename it in the docs too, everywhere, not just on the page you were already editing.
- **The last page in an optional subdirectory** (`usage/tutorials/`, `internals/development/`) → remove the directory and drop it from its parent landing.
- **A whole section emptied out** → don't delete it. `usage/`, `reference/` and `internals/` are part of the fixed skeleton; leave the landing page saying what belongs there. If a section really has nothing left, say so in the summary — it usually means the change was bigger than an incremental update should handle.
- **An ADR whose decision was reversed** → never delete it. Write a new ADR that supersedes it and update the old one's Status line (§5).

Then check what the removal *implies*: a deleted feature usually also appears in a usage page's prerequisites, a tutorial step, a `CONTRIBUTING.md` command, or an architecture diagram in `internals/` — grep hits point at the page, but Mermaid node labels, alt text, and prose paraphrases won't match the grep. Re-read any page that mentioned the removed thing end to end, **and re-read every diagram on it node by node**: a removed component whose box still sits in the flowchart is a worse artifact than no diagram, because readers trust the picture over the prose. Same for screenshots — an image showing a removed button gets re-captured or deleted, never left because "it's mostly still right".

Delete rather than mark deprecated, unless the project actually ships a deprecation period for that surface — in which case say what replaces it and when it goes away, and don't leave the note undated. Git holds the history either way.

If a doc describes something you can no longer find in the repo but the diff doesn't show it being removed, don't delete on a hunch — flag it in the summary and let the user decide.

## 5. Content rules (same as docs-init)

Relative links only, one Diátaxis mode per page, concise Markdown, no invented content — use `<!-- TODO: verify -->` for genuine gaps; trim verifiable stale claims on touch. Fixed section names: `usage`, `reference`, `internals`, with `tutorials`, `adrs` and `development` as the only subdirectory names the structure defines; `README.md` (never `index.md`) as directory landings; nothing in `docs/` besides `README.md`, the three sections, and `assets/`.

**One canonical home per fact** (`docs-init` §12) — every other mention links to it. An incremental run enforces this going in (§2), not by auditing the whole tree; if you notice existing duplication outside this change's scope, report it in §7 rather than fixing it here.

**Visuals follow `docs-init` §11** in full: diagram-as-code by default, diagram type chosen from the content (`flowchart` / `sequenceDiagram` / `stateDiagram-v2` / `erDiagram`), one idea per diagram, figures in `docs/assets/` named after their page's subject, real alt text on every image, and nothing drawn that you didn't trace in the code. When you add a paragraph explaining how several pieces now fit together, that's the signal to draw it instead.

**Reference pages that are generated** (`<!-- generated by: … -->` at the top) are refreshed by re-running that command, not hand-edited — `docs-init` §5.

**Writing an ADR** (`docs-init` §8 has the format). The trigger is a *decision*, not a change: this run adds an ADR when the diff shows a deliberate architectural choice — a swapped dependency or datastore, a new boundary between components, a protocol or storage-format change, an approach chosen against a visible alternative. Routine feature work, refactors and bug fixes don't earn one. When one is warranted:

- Take the next unused number, four digits, zero-padded. Status `Accepted`, dated from the change.
- Source Context and Consequences from the change itself and what the user said while making it — this is the one moment the reasoning is actually available, which is why an incremental run is a better place to capture it than a later reconcile. Don't reconstruct a rationale the change doesn't show; `<!-- TODO: verify -->` and ask in the summary.
- If it reverses an earlier decision, set the old ADR's Status to `Superseded by [NNNN](NNNN-slug.md)` and leave the rest of that file untouched — ADRs are immutable and superseded ones are never deleted.
- Add the row to `docs/internals/adrs/README.md`, and update `docs/internals/` wherever the design it describes is now different. The ADR records the decision; the internals page still has to describe the current system.

**Naming a new page** follows `docs-init` §4, and this is where it's easiest to get wrong: an incremental update sees one page at a time, so it invents a fresh name instead of extending a pattern. Before writing a new file, list the section's existing files. If any of them cover the same subject, join that group — shared `<subject>-<qualifier>.md` prefix, or the existing `<subject>/` subdirectory, whichever is already in use. If the group would reach roughly four pages, promote it to a subdirectory now (and repoint per §6). If the pattern only becomes obvious once your new page exists, rename the older siblings to match rather than shipping the odd one out. No doc-type suffixes: it's `docs/reference/api.md`, never `api-reference.md`.

## 6. Renames, moves and deletions ripple beyond docs/

If this update moves, renames, or deletes a page, follow `docs-init` §13: grep the whole repo (code docstrings, configs, CI, tests, `CLAUDE.md`/`.claude/`, and both root files) and update every reference — for a deletion that means removing the link, not repointing it — and update the site-generator nav if one exists. Then verify: resolve every relative link **and `![…]()` figure path** in the affected pages *and* in anything that linked to them, and build the site if there is one. A link check that only covers files you edited will miss the landing page that still lists a page you deleted. Moving a page between section levels changes its relative depth into `../assets/`, so figure paths break on exactly the moves where you're least looking at them — and a broken image renders as quiet alt text rather than an obvious 404.

## 7. Finish with a summary

Report which section(s)/file(s) were touched and why — naming `README.md` and `CONTRIBUTING.md` explicitly, including when you deliberately left them alone — which diagrams or figures were updated, added, or removed, whether an ADR was written (and if a decision looked ADR-worthy but you couldn't source its rationale, say so), what was deleted or renamed, any skeleton path created, and anything skipped because it seemed out of scope for this change, so the user can catch it if the scope was guessed wrong. Call out separately anything that looked stale, duplicated, or orphaned but wasn't part of this change — this skill deliberately never opens pages the change didn't touch, so it can't vouch for them — and say plainly that a full `/docs-init` reconcile is what sweeps those.
