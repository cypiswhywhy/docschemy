---
name: docs-init
description: Scaffold or reconcile a project's docs/ directory using the Diátaxis framework (Tutorials, How-To Guides, Reference, Explanation). Migrates content from the existing README, code, comments, config, and code-adjacent runbooks into the right quadrant, leads with diagrams and figures (Mermaid first) wherever a visual conveys structure better than prose, and only creates the quadrants that actually make sense for the project. Use when setting up documentation for a new or undocumented project, or when updating an already-documented project to match the latest docs/ convention.
---

# docs-init

Sets up or updates a project's `docs/` directory following the Diátaxis framework. Three situations — check what's already there:

**Init mode**: no `docs/` yet, or only scattered markdown.
**Reconcile mode**: `docs/` already follows this convention but may be incomplete, stale, or need a flat file promoted to a directory as it's grown.
**Adopt mode**: `docs/` follows a *different deliberate convention* (audience split, wiki export, a published site with live URLs). Don't silently restructure. Name the costs first — published URLs break (no redirects unless added), the site-generator config needs a rewrite, and the repo's own docs-style guide (if it has one) must be rewritten too — then ask the user whether to migrate to this convention or keep theirs.

Two standing rules for all content work:

- **Never invent** facts, features, flags, or behavior that isn't actually in the code/config. If something is genuinely unclear from the repo, write a `<!-- TODO: verify -->` marker instead of guessing.
- **Trim on touch**: when migrating a page, fix stale claims you can *verify against the repo* (retired hosts, references to files or build steps that no longer exist, leftover paste artifacts) instead of copying them forward. Verified cleanup yes, guessed rewrites no.
- **Delete, don't archive**: a page (or section) whose entire subject is gone from the repo gets deleted, and every link to it removed — not left in place, not moved to an `old/` folder. Git holds the history. Confirm with the user before deleting a page whose subject you merely *couldn't find* rather than confirmed removed.

## 1. Survey before writing anything

Read, in this order: `README.md`, any existing `docs/` or scattered `*.md` files, `package.json`/`pyproject.toml`/`Cargo.toml`/etc. for name/description/scripts, the CLI entrypoint or main API surface, `.claude/skills/*/SKILL.md` and `.claude/commands/*.md` (project-local Claude Code skills/slash commands, if the repo defines any), CI config, and code comments/docstrings that explain non-obvious behavior.

Also hunt for documentation hiding outside `docs/`:

- **Nested doc trees** (`<component>/docs/`) and **named runbooks next to code** (`RUN-LOCAL.md`, `DEPLOY.md`, `NOTES.md`, substantial component READMEs). These are migration material, not things to leave in place — see §5. Grep footgun: `--exclude-dir=docs` excludes *every* directory named `docs` at any depth, which is exactly how nested trees stay hidden.
- **A static-site generator config** (`mkdocs.yml`, Docusaurus, Sphinx `conf.py`). If one exists, every move must also update its nav/config, and the build must end green — and site constraints shape the layout (see `assets/` in §3).
- **Existing visuals**: Mermaid blocks, `![…]()` figures, `.png`/`.svg`/`.drawio` files anywhere near the docs you're migrating. These are the most expensive content in the repo to recreate and the easiest to drop during a move — inventory them now, carry every one into the new structure (§8), and repoint its path.

Build a mental model of what the project actually does before deciding structure.

## 2. Decide which quadrants apply

Don't create all four by default. Populate a quadrant only if it earns its keep:

- **Tutorials** (`docs/tutorials/`) — only if there's a real learning-oriented onboarding path (e.g. a library/framework someone needs to learn by doing). Skip for scripts, internal pipelines, and most services.
- **How-To Guides** (`docs/how-to-guides/`) — goal-oriented recipes: install, configure, deploy, run common tasks, troubleshoot. Include if there's more than one thing a user/operator would need to *do* with this project.
- **Reference** (`docs/reference/`) — CLI flags, API endpoints, config schema, env vars, and project-local Claude Code skills/slash commands (`.claude/skills/`, `.claude/commands/`) if the repo defines any — list each with its name and what it does. Include only if there's a real, stable surface worth looking up (skip for a one-off script with no options).
- **Explanation** (`docs/explanation/`) — architecture, internals, design decisions, and the diagrams that carry them (§8). Almost always include this one unless the project is genuinely trivial (a single-file script with no interesting structure).

If it's a close call, state your reasoning briefly and ask the user to confirm rather than silently guessing.

## 3. Layout rules

- **Start flat**: a single `docs/<quadrant>.md`. Only use a directory (`docs/<quadrant>/` with a `README.md` landing page listing its contents, plus one file per distinct topic) once that quadrant genuinely has more than one topic worth separating — e.g. `docs/reference/cli.md` + `docs/reference/config.md`.
- **Landing pages are `README.md`, not `index.md`** — GitHub renders `README.md` when someone browses the folder, and site generators (MkDocs et al.) accept it as the section index. Never put both `README.md` and `index.md` in one folder; generators treat both as the index and they collide.
- In **reconcile mode**, if a flat file has accumulated multiple distinct topics, promote it to a directory: create the `README.md` landing, split the content into topic files by section, and preserve everything — don't drop content during the split.
- **`docs/` contains the quadrant entries, a `README.md` router, and `docs/assets/` — nothing else** (the router earns its keep once quadrants become directories). `assets/` is a single flat directory holding every figure the docs reference: images, screenshots, and diagram sources that can't be inlined as Mermaid (§8). With a static-site generator it also holds site infrastructure (logo, favicon, CSS), because generators only serve files inside the docs dir; theme overrides/templates live *outside* `docs/` with the tooling. Don't scatter per-quadrant `images/` folders — one `assets/` keeps figure paths stable when a page moves between quadrants. Planning notes, ADR archives, and other historical material live outside `docs/` entirely.
- When one component accumulates several pages within a quadrant, sub-namespace by **topic** (`docs/how-to-guides/knowhow/…`), never by code path (`docs/how-to-guides/tools/mcp-server/…`) — doc URLs should survive code reorganizations.
- Naming is fixed so a future cross-project doc portal can rely on convention: `tutorials`, `how-to-guides`, `reference`, `explanation` — always these exact names, whether flat file or directory.

## 4. File naming: related pages must be recognizable as related

A quadrant's file listing is its table of contents. Someone scanning `docs/how-to-guides/` should see at a glance which pages cover the same subject — that only works if names are derived by rule, not chosen per page.

- **Lowercase kebab-case, named after the subject** — `install.md`, `deploy-staging.md`. No doc-type suffixes (`-guide`, `-docs`, `-reference`, `-howto`): the quadrant already says what kind of page it is.
- **Subject first, qualifier second.** `install-docker.md`, never `docker-install.md`; `deploy-staging.md`, never `staging-deploy.md`. Alphabetical order is the only sort a reader gets, so the subject has to be the part that sorts.
- **Before creating a page, list the quadrant's existing files** and reuse the pattern already established there. Never introduce a second naming style alongside an existing one.
- **When two or more pages cover one subject, group them by exactly one mechanism:**
  - **Shared prefix** — `install.md`, `install-docker.md`, `install-advanced.md` — for two or three pages.
  - **Subdirectory** `<subject>/` with a `README.md` landing — `install/README.md`, `install/docker.md`, `install/advanced.md` — once the subject reaches roughly four pages, or its pages have their own sub-subjects. Inside the subdirectory the prefix is dropped; the directory carries it.

  Never both for the same subject: `install/` and a sibling `install-advanced.md` is the failure mode this rule exists to prevent.
- **A new page that breaks the pattern means renaming the old ones, not naming the new one badly.** If a third page joins `install.md` + `install-advanced.md` under a name like `getting-started-on-macos.md`, the fix is `install-macos.md` — or promoting all three to `install/`. Renames follow §10 (repoint the whole repo).
- **In reconcile mode, audit naming as its own pass**: for each quadrant, group the existing pages by subject and check that every group uses one mechanism consistently. Off-pattern names that are genuinely about the same subject get renamed; report each rename in the summary, since the user may have had a reason for the old name.

## 5. Code-adjacent docs: `README.md` is the only exception

All documentation lives under `docs/`. A `README.md` may sit next to the code it documents, but only as a **lean pointer** — a sentence or two on what this directory is, plus links into `docs/` — never a docs home. Left ungoverned, code-adjacent runbooks grow into shadow doc trees with their own ad-hoc conventions.

So during init/adopt: migrate runbooks and nested doc trees into the quadrants, and leave a lean pointer `README.md` behind where a reader would expect one.

## 6. Root README.md

Keep it short: one-paragraph pitch, a minimal quickstart, and a links section pointing to whichever `docs/<quadrant>.md` or `docs/<quadrant>/README.md` files exist. Don't duplicate content that belongs in `docs/` — link to it instead.

## 7. Content rules

- Plain Markdown, relative links only (never absolute URLs back to this repo — a future centralized doc portal needs to move these). Figure paths are relative too.
- **Lead with the visual where one applies** — see §8, which is a content rule of equal weight to these, not a garnish.
- **One Diátaxis mode per page.** Split a page that mixes modes (e.g. "how the bridge works" + "how to set the bridge up" becomes an explanation page and a how-to page), preserving all content.
- **Quadrant is the primary split; audience is secondary but real.** Keep a plain-language guide and its engineer-facing counterpart as separate pages within the same quadrant (e.g. `install.md` and `install-advanced.md`, per §4) rather than merging them because they share a topic.
- Clear and concise — prefer short paragraphs and bullet lists over prose. No filler.
- Don't leave placeholder/lorem-ipsum content. If a quadrant is created, it must reflect real repo content, not a stub.

## 8. Visuals: show the shape, then explain it

A diagram conveys structure, sequence, and state faster than any paragraph, and it's what a reader looks at first. Treat a visual as the **default** for anything spatial, sequential, or stateful; let the prose explain what the picture can't say. Never caption-narrate — don't describe in text what the diagram already shows.

**Diagrams as code (Mermaid) are the default form.** They render on GitHub and in every common site generator, they diff reviewably, and they don't rot silently the way a screenshot does. Reach for a binary image only when the subject genuinely can't be drawn as code.

**Every quadrant earns visuals — not just `explanation`:**

- `explanation` — architecture, component boundaries, data flow, state machines. **An architecture page with no diagram is incomplete**; add one before calling the quadrant done.
- `how-to-guides` — the pipeline or sequence the recipe drives; a decision tree for troubleshooting ("symptom → check → fix").
- `reference` — entity/schema relationships, lifecycle states, the shape of a config tree.
- `tutorials` — the end state the reader is building, shown up front, and where they are in a multi-step path.

**Pick the diagram type from the content**, rather than defaulting everything to `flowchart`:

| Content | Mermaid type |
| --- | --- |
| Components, dependencies, data flow | `flowchart` |
| Interaction over time, request/response, protocols | `sequenceDiagram` |
| Lifecycle, allowed transitions, status fields | `stateDiagram-v2` |
| Data model, entities, relationships | `erDiagram` |
| Class/type hierarchies | `classDiagram` |
| Phases, roadmaps, rollout order | `gantt` |

Keep one idea per diagram and roughly a dozen nodes — split a bigger one rather than shrinking labels. Label edges with what actually flows (`writes batch`, `polls every 30s`), not bare arrows.

**Screenshots and other binary images** are for what code can't draw: real UI, a rendered dashboard, a hardware/wiring photo. They rot faster than anything else in `docs/`, so — crop to the region that matters; never let an image carry information that isn't also in text (a reader can't grep a picture, and it won't survive a restyle); and never screenshot terminal output, logs, or code, which belong in fenced blocks.

**Figure files live in `docs/assets/`** (§3), named by the same rule as pages (§4) — kebab-case, subject first, tied to the page that uses them: `install-docker-network.png`, `architecture-request-flow.svg`. Reference them relatively (`../assets/…` from inside a quadrant directory). If a diagram has an editable source (`.drawio`, `.excalidraw`), commit it next to the exported image under the same stem so the next person can edit rather than redraw.

**Always write real alt text** — `![Request flow from CLI through the queue to the worker](../assets/architecture-request-flow.svg)`. It's what a screen reader announces, what shows when the load fails, and what a grep finds. "Diagram", "screenshot", and "image" are not alt text.

**Never fabricate a visual.** The no-invention rule binds hardest here: a diagram asserts relationships as fact and reads as authoritative even when it's wrong. Draw only what you traced in the code, and never produce or describe a screenshot of a UI you haven't actually seen — leave a `<!-- TODO: verify -->` naming what the figure should show instead.

**In reconcile mode, audit visuals as its own pass** — the same way §4 audits naming. Docs written before this rule existed are text-only by default, and nothing else in this skill will sweep them: the §11 checks only catch a diagram-less `explanation` page, so `how-to-guides`, `reference`, and `tutorials` go unexamined unless you look on purpose. Walk every page in every quadrant once and ask, in order:

1. **Does the page describe something with a shape** — components, an ordering, a lifecycle, a data model, a UI? If yes and it has no visual, that's the omission this pass exists to find. Add the diagram, typed per the table above.
2. **Is an existing diagram still true?** Trace it against the code as you would a prose claim. Stale nodes and dropped edges are the trim-on-touch standing rule applied to pictures.
3. **Is a long paragraph doing a diagram's job?** Prose that enumerates what talks to what, or walks through an ordered exchange step by step, is a diagram written out longhand. Replace it — don't keep both.
4. **Are figures in the right place with the right names?** Stray images beside pages or in per-quadrant folders move to `docs/assets/` and get renamed per §4; every reference to them gets repointed (§10).
5. **Does every image have real alt text?** Add it where it's missing or where it's a placeholder like "diagram".
6. **Is anything a screenshot that shouldn't be?** Terminal output, logs, and code become fenced blocks; delete the image.

Restraint applies: don't add a visual to a page that has no shape to show, and don't bulk-generate diagrams to hit a quota — an invented diagram is worse than the text-only page it replaced. Where a page clearly warrants a visual but the repo doesn't tell you enough to draw it accurately, leave a `<!-- TODO: verify -->` describing the diagram it needs, and list those in the §12 summary so the user can fill the gaps. Report the pass per quadrant: diagrams added, diagrams corrected, figures relocated, screenshots retired.

## 9. Redundancy: one canonical home per fact

Every fact — a command, a flag's meaning, a prerequisite, an architectural claim — lives on exactly **one** page. Every other place that needs it links there. This is what keeps docs maintainable: duplicated content doesn't stay duplicated, it *drifts*, and a reader who finds the stale copy has no way to know which one is current.

Duplication is not the same failure as a page mixing Diátaxis modes (§7). A mixed page has two kinds of content that should be split apart; duplication is the *same* content existing twice and needing to become one copy plus a link.

**Where it accumulates:**

- **Root `README.md` restating a quadrant** — §6 already forbids this; it's the most common instance.
- **A how-to restating its explanation** — a recipe that opens by re-deriving how the system works instead of linking to the page that explains it. Keep the one-line orientation, link for the rest.
- **A quadrant landing `README.md` summarizing its pages** instead of indexing them. The landing says what's in the directory and links; it doesn't teach the material.
- **Two pages on the same subject that both went long** — usually a sign they should be one page, or that §4's grouping rules apply and the boundary between them needs to be stated in each.
- **A code-adjacent `README.md` that grew past a pointer** (§5).

**Shared setup steps are the honest exception.** When three how-tos genuinely need the same prerequisite block, extract it to its own page and link from all three — don't inline it three times, and don't force an artificial merge of three distinct recipes.

**In reconcile mode, audit redundancy as its own pass**, alongside naming (§4) and visuals (§8). Read each quadrant's pages as a set rather than one at a time — duplication is invisible from inside a single page, which is exactly why it survives. For each subject covered in more than one place: pick the canonical page (the one whose quadrant matches the content's Diátaxis mode), keep the fullest correct version there, and replace every other copy with a link. Where the copies disagree, the repo decides which is right — not the longer or newer copy.

Deleting the duplicate is the point; leaving both with a "see also" is not a fix. But don't strip context so aggressively that a page stops standing on its own: a sentence of orientation plus a link is right, a bare link with no indication of why you'd follow it is not.

## 10. Moving a doc means repointing the repo

Doc paths leak far beyond `docs/`: code docstrings, JSON-schema descriptions, config examples, CI comments, agent instructions (`CLAUDE.md`, `.claude/`), and sometimes **tests that assert on doc paths**. When a page moves or is renamed, grep the whole repo and repoint every reference — including its figures, whose relative depth into `../assets/` changes whenever a page moves between a flat file and a directory — no redirects, no stale paths left behind. Frozen historical material (old design docs, archived specs) is the one place stale paths may stay as written.

## 11. Verify before summarizing

- Resolve every relative link **and every `![…]()` figure path** under `docs/` against the filesystem (script it — don't eyeball); fix all breakage. A broken image renders as silent alt text, so it survives review far longer than a broken link.
- Check `docs/assets/` both ways: no figure referenced by a page is missing, and no file in `assets/` is unreferenced by any page. Wire up orphans or delete them.
- Confirm every Mermaid block opens with a valid diagram type and has a balanced fence — a typo'd block renders as raw text on GitHub.
- Grep the repo for the old paths; require zero hits outside deliberately-frozen historical material.
- List each quadrant's files and re-read them as a set: every group of same-subject pages uses one grouping mechanism (§4), and each quadrant landing `README.md` lists exactly the files that are actually there.
- Re-read the `explanation` pages: if one describes architecture or a flow and has no diagram (§8), it isn't finished.
- Check for orphan pages the same way you checked orphan assets: every page under `docs/` should be reachable from the `docs/README.md` router or a quadrant landing. An unreachable page is either missing from a landing listing or is content nobody kept — resolve which, don't leave it dangling.
- If a site generator exists, build it and require zero warnings.
- If doc paths appear in tests, run the test suite.

## 12. Finish with a summary

At the end, report: which quadrants were created/updated, which were deliberately skipped and why, any pages renamed or deleted (with the reason), the results of the visuals pass (§8) — diagrams added, diagrams corrected, figures relocated, screenshots retired — the results of the redundancy pass (§9), naming each subject that was consolidated and which page became canonical, the verification results (link/figure check, orphan check, build, tests), and anything marked `<!-- TODO: verify -->` that needs the user's input because it couldn't be confirmed from the repo alone.
