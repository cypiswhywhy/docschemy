---
name: docs-init
description: Scaffold or reconcile a project's documentation into the standard structure — root README.md and CONTRIBUTING.md, plus docs/usage (end users), docs/reference (lookup), and docs/internals (engineers, including ADRs) — with Diátaxis modes routed into those fixed locations. Migrates content from the existing README, code, comments, config, and code-adjacent runbooks into the right section, leads with diagrams and figures (Mermaid first) wherever a visual conveys structure better than prose. Use when setting up documentation for a new or undocumented project, or when updating an already-documented project to match the latest docs/ convention.
---

# docs-init

Sets up or updates a project's documentation using a fixed **structural strategy**: an identical directory layout in every project, with the Diátaxis modes routed into audience-named sections. Three situations — check what's already there:

**Init mode**: no `docs/` yet, or only scattered markdown.
**Reconcile mode**: docs already follow this convention, or the older Diátaxis-only version of it (`docs/tutorials`, `docs/how-to-guides`, `docs/explanation` at the top level), but may be incomplete, stale, or unmigrated. §3 has the migration mapping.
**Adopt mode**: docs follow a *different deliberate convention* (audience split of another shape, wiki export, a published site with live URLs). Don't silently restructure. Name the costs first — published URLs break (no redirects unless added), the site-generator config needs a rewrite, and the repo's own docs-style guide (if it has one) must be rewritten too — then ask the user whether to migrate to this convention or keep theirs.

Three standing rules for all content work:

- **Never invent** facts, features, flags, or behavior that isn't actually in the code/config. If something is genuinely unclear from the repo, write a `<!-- TODO: verify -->` marker instead of guessing. This binds hardest on `CONTRIBUTING.md` (§7) and ADRs (§8), which are the easiest files to fill with plausible boilerplate that was never true of this repo.
- **Trim on touch**: when migrating a page, fix stale claims you can *verify against the repo* (retired hosts, references to files or build steps that no longer exist, leftover paste artifacts) instead of copying them forward. Verified cleanup yes, guessed rewrites no.
- **Delete, don't archive**: a page (or section) whose entire subject is gone from the repo gets deleted, and every link to it removed — not left in place, not moved to an `old/` folder. Git holds the history. Confirm with the user before deleting a page whose subject you merely *couldn't find* rather than confirmed removed. ADRs are the one exception (§8): superseded decisions stay.

## 1. Survey before writing anything

Read, in this order: `README.md`, `CONTRIBUTING.md`, any existing `docs/` or scattered `*.md` files, `package.json`/`pyproject.toml`/`Cargo.toml`/etc. for name/description/scripts, the CLI entrypoint or main API surface, `.claude/skills/*/SKILL.md` and `.claude/commands/*.md` (project-local Claude Code skills/slash commands, if the repo defines any), CI config, and code comments/docstrings that explain non-obvious behavior.

**Survey the contributor surface too** — it is a first-class audience here, and it is not visible from the README. Read the `Makefile`/task runner, package scripts, CI workflows, lockfiles and tool-version pins (`.nvmrc`, `.python-version`, `rust-toolchain.toml`), linter/formatter/pre-commit config, `.github/` templates, and any `CODEOWNERS`. These are what §7 is written from; nothing goes in `CONTRIBUTING.md` that can't be traced to one of them.

Also hunt for documentation hiding outside `docs/`:

- **Nested doc trees** (`<component>/docs/`) and **named runbooks next to code** (`RUN-LOCAL.md`, `DEPLOY.md`, `NOTES.md`, substantial component READMEs). These are migration material, not things to leave in place — see §9. Grep footgun: `--exclude-dir=docs` excludes *every* directory named `docs` at any depth, which is exactly how nested trees stay hidden.
- **Decision material**: design docs, RFCs, `adr/` or `decisions/` folders, long "why we did it this way" commit messages and code comments. This is ADR input (§8).
- **A static-site generator config** (`mkdocs.yml`, Docusaurus, Sphinx `conf.py`). If one exists, every move must also update its nav/config, and the build must end green — and site constraints shape the layout (see `assets/` in §3).
- **Existing visuals**: Mermaid blocks, `![…]()` figures, `.png`/`.svg`/`.drawio` files anywhere near the docs you're migrating. These are the most expensive content in the repo to recreate and the easiest to drop during a move — inventory them now, carry every one into the new structure (§11), and repoint its path.

Build a mental model of what the project actually does before deciding structure.

## 2. The structure is fixed — scaffold it first

Unlike a plain Diátaxis setup, the layout is not decided per project. Create every path below (checking first — never clobber what's there), then fill it:

```
README.md                     project entry point       — §6
CONTRIBUTING.md               contributor entry point   — §7
docs/
  README.md                   router: the three doors and who each is for
  usage/                      AUDIENCE: end users. The project as a black box.
    README.md                 landing: lists the pages below it
    <task>.md                 how-to guides live at this level
    tutorials/                only when a real learning path exists
      README.md
      <tutorial>.md
  reference/                  AUDIENCE: anyone. Factual lookup, often generated.
    README.md
    <surface>.md              cli.md, http-api.md, configuration.md, …
  internals/                  AUDIENCE: engineers and contributors.
    README.md
    architecture.md           explanation pages live at this level
    <topic>.md
    adrs/                     always present — §8
      README.md               index + how to add one
      NNNN-<slug>.md
    development/              only when contributor procedures outgrow CONTRIBUTING.md
      README.md
      <topic>.md
  assets/                     every figure the docs reference, flat — §3
```

**All three sections are always created**, along with `docs/README.md`, `docs/assets/`, `docs/internals/adrs/`, `README.md`, and `CONTRIBUTING.md`. That guarantee is the point of the strategy: a reader, a script, or a future cross-project portal can rely on the path existing. A section that is genuinely thin still gets a real landing page saying what belongs there and linking onward — but a section with *nothing* true to say is a signal you under-surveyed (§1), not a reason to skip it.

The only escape hatch: a genuinely trivial repo (a single-file script, no options, no build, no contributors) may stop at `README.md` — say so explicitly in the summary rather than half-building the tree.

Optional paths — `usage/tutorials/` and `internals/development/` — are created only when they have real content, and the rule for each is in its section below.

### Routing table

Decide a page's home by asking **who it's for**, then **which Diátaxis mode it is**:

| Content | Diátaxis mode | Audience | Home |
| --- | --- | --- | --- |
| Learn the project by doing | Tutorial | end user | `docs/usage/tutorials/` |
| Accomplish a task: install, configure, deploy, troubleshoot | How-to | end user / operator | `docs/usage/` |
| CLI flags, endpoints, config keys, env vars, schemas, skill/command catalogs | Reference | anyone | `docs/reference/` |
| Architecture, data flow, internals, why it works this way | Explanation | engineer | `docs/internals/` |
| A specific design decision, with its context and consequences | (decision record) | engineer | `docs/internals/adrs/` |
| Set up a dev env, run tests, submit a PR, cut a release | How-to | contributor | `CONTRIBUTING.md`, overflowing to `docs/internals/development/` |

**The `usage/` boundary is strict**: it documents the project as a black box. If understanding a page requires a source checkout or knowledge of internal components, it isn't a usage page — it belongs in `internals/` (if it explains) or `CONTRIBUTING.md` / `internals/development/` (if it instructs). Installing a released artifact is usage; building from source to hack on it is contributor material.

Diátaxis modes still govern *pages* even though their names no longer appear in paths: **one mode per page**, always (§10). A `docs/usage/` page that starts explaining how the system works internally is two pages.

## 3. Layout rules

- **Sections are always directories** with a `README.md` landing, never a flat `docs/<section>.md`. The older convention started flat and promoted on growth; that variability is exactly what this strategy removes. In reconcile mode, a flat `docs/explanation.md` (etc.) is migrated per the table below — split by section into topic files, preserving everything.
- **Landing pages are `README.md`, not `index.md`** — GitHub renders `README.md` when someone browses the folder, and site generators (MkDocs et al.) accept it as the section index. Never put both `README.md` and `index.md` in one folder; generators treat both as the index and they collide.
- **A landing page indexes, it doesn't teach**: one line on who the section is for, then a list of its pages with a phrase each. `docs/README.md` does the same for the three sections.
- **`docs/` contains exactly `README.md`, `usage/`, `reference/`, `internals/`, and `assets/` — nothing else.** `assets/` is a single flat directory holding every figure the docs reference: images, screenshots, and diagram sources that can't be inlined as Mermaid (§11). With a static-site generator it also holds site infrastructure (logo, favicon, CSS), because generators only serve files inside the docs dir; theme overrides/templates live *outside* `docs/` with the tooling. Don't scatter per-section `images/` folders — one `assets/` keeps figure paths stable when a page moves between sections. Planning notes and other historical material live outside `docs/` entirely.
- When one component accumulates several pages within a section, sub-namespace by **topic** (`docs/usage/knowhow/…`), never by code path (`docs/usage/tools/mcp-server/…`) — doc URLs should survive code reorganizations.
- Section names are fixed so a future cross-project doc portal can rely on convention: `usage`, `reference`, `internals` — always these exact names, plus `tutorials`, `adrs`, `development` for the subdirectories.

**Migration mapping** (reconcile mode, from the older Diátaxis-only layout):

| Old path | New path |
| --- | --- |
| `docs/tutorials.md` | `docs/usage/tutorials/` — split into pages, or a single page + landing |
| `docs/tutorials/` | `docs/usage/tutorials/` — landing and pages move as-is |
| `docs/how-to-guides.md` | `docs/usage/` — split into one page per recipe |
| `docs/how-to-guides/` | `docs/usage/` — pages move up; its landing content merges into `docs/usage/README.md` |
| `docs/explanation.md` | `docs/internals/` — split into topic pages (`architecture.md` + others) |
| `docs/explanation/` | `docs/internals/` — pages move up; its landing merges into `docs/internals/README.md` |
| `docs/reference{.md,/}` | `docs/reference/` — promote a flat file to a directory, otherwise unchanged |
| `docs/assets/` | unchanged |

Every one of these moves changes a page's depth relative to `../assets/`, so figure paths break on exactly the moves where you're least looking at them. §13 repointing applies to all of it.

## 4. File naming: related pages must be recognizable as related

A section's file listing is its table of contents. Someone scanning `docs/usage/` should see at a glance which pages cover the same subject — that only works if names are derived by rule, not chosen per page.

- **Lowercase kebab-case, named after the subject** — `install.md`, `deploy-staging.md`. No doc-type suffixes (`-guide`, `-docs`, `-reference`, `-howto`): the section already says what kind of page it is. `docs/reference/api-reference.md` is the canonical mistake — it's `docs/reference/api.md`.
- **Subject first, qualifier second.** `install-docker.md`, never `docker-install.md`; `deploy-staging.md`, never `staging-deploy.md`. Alphabetical order is the only sort a reader gets, so the subject has to be the part that sorts.
- **Before creating a page, list the section's existing files** and reuse the pattern already established there. Never introduce a second naming style alongside an existing one.
- **When two or more pages cover one subject, group them by exactly one mechanism:**
  - **Shared prefix** — `install.md`, `install-docker.md`, `install-advanced.md` — for two or three pages.
  - **Subdirectory** `<subject>/` with a `README.md` landing — `install/README.md`, `install/docker.md`, `install/advanced.md` — once the subject reaches roughly four pages, or its pages have their own sub-subjects. Inside the subdirectory the prefix is dropped; the directory carries it.

  Never both for the same subject: `install/` and a sibling `install-advanced.md` is the failure mode this rule exists to prevent.
- **A new page that breaks the pattern means renaming the old ones, not naming the new one badly.** If a third page joins `install.md` + `install-advanced.md` under a name like `getting-started-on-macos.md`, the fix is `install-macos.md` — or promoting all three to `install/`. Renames follow §13 (repoint the whole repo).
- **ADRs are the exception**: they are numbered, not subject-sorted (§8).
- **In reconcile mode, audit naming as its own pass**: for each section, group the existing pages by subject and check that every group uses one mechanism consistently. Off-pattern names that are genuinely about the same subject get renamed; report each rename in the summary, since the user may have had a reason for the old name.

## 5. `docs/reference/`: pick the pages from the project type

Reference is factual, lookup-shaped, and often generatable. Create the pages the project's actual surface justifies:

| Project type | Typical pages |
| --- | --- |
| CLI tool | `cli.md` (commands and flags), `configuration.md` |
| HTTP service / API | `http-api.md` (or a generated OpenAPI page), `configuration.md`, `environment.md` |
| Library / SDK | `api.md` — public surface by module/class |
| Claude Code skills, commands or plugin repo | `skills.md`, `commands.md`, `plugin-schema.md` |
| Data pipeline / job | `configuration.md`, `schemas.md` (with an `erDiagram`) |
| Infrastructure / IaC | `variables.md`, `modules.md` |
| Anything with a task runner | `make-targets.md` or `scripts.md` |
| Anything reading env vars | `environment.md` |

Pick by surface, not by label — a repo with no CLI gets no `cli.md`. Where the project type isn't in the table, name the page after the surface it documents, per §4.

- **Never ship an empty stub.** A reference page is created by *enumerating the real surface* from the code/config. If a surface genuinely exists but can't be enumerated from the repo alone, create the page with a `<!-- TODO: verify -->` block naming exactly what should be listed and where it comes from — then list it in the summary (§15). A file containing only a heading is worse than no file: it looks answered.
- **Mark generated pages as generated.** If a page is produced by a command (`openapi.json` → Markdown, `--help` dumps, schema exports), put the command in an HTML comment at the top — `<!-- generated by: make docs-api — do not edit by hand -->` — and don't hand-edit it afterwards. Wire it into the task runner if one exists.
- Project-local Claude Code skills and slash commands (`.claude/skills/`, `.claude/commands/`) are a documented surface like any other: list each with its name and what it does.

## 6. Root `README.md`: the standard entry point

The README is generated to a fixed shape so every project reads the same way. Sections, in order:

1. **Title** — the project name.
2. **Description** — one paragraph: what it is and who it's for. No history, no roadmap.
3. **Install** — the single most common install command, nothing else.
4. **Usage** — the shortest command or snippet that shows the project doing its job, then a link to `docs/usage/`.
5. **Reference** — one line plus a link to `docs/reference/`.
6. **Internals** — one line plus a link to `docs/internals/` (say it's for engineers).
7. **Contributing** — one line plus a link to `CONTRIBUTING.md`.
8. **License** — only if the repo has one; link the file.

Badges, if the repo already has them, sit under the title. Keep everything else out.

**The README links, it doesn't restate** (§12). The sanctioned exception is the single quickstart line under Install and Usage: the full install matrix, the options, the platform variants and the troubleshooting all live in `docs/usage/`, and the README points there. When the README already contains real content that belongs in a section, *move* it and leave the link — don't copy it.

## 7. `CONTRIBUTING.md`: the contributor entry point

Diátaxis has no home for "how do I work on this project" — that gap is why this file is part of the fixed structure. It is written entirely from what §1 found in the Makefile, scripts, CI, and tooling config. Sections, in order, dropping any the repo genuinely doesn't have:

1. **Prerequisites** — languages, runtimes and tools, with the versions the repo actually pins.
2. **Set up** — clone, install dependencies, build. Exact commands.
3. **Run tests, lint, format** — the exact commands, and which of them CI enforces.
4. **Project layout** — a short paragraph, then a link to `docs/internals/architecture.md`. Not a directory tree dump.
5. **Making a change** — branch naming, commit message convention, PR expectations, what CI runs. Derive from `.github/` templates, CI config and recent git history; don't import a convention the repo doesn't follow.
6. **Design decisions** — when a change needs an ADR, linking to `docs/internals/adrs/README.md` (§8).
7. **Documentation** — that changes update the docs, with a link to `docs/README.md`.
8. **Release** — only if the repo actually publishes something; the real process, from CI/release config.

**Every command in this file must be traceable to a file in the repo.** A test command you can't find is a `<!-- TODO: verify -->`, not a guess at the ecosystem default — a `CONTRIBUTING.md` full of plausible-but-wrong commands costs a new contributor more than an empty one.

`CONTRIBUTING.md` stays a single page. When one of its procedures genuinely outgrows a section — a multi-stage release, a local environment matrix, a debugging setup with real depth — move that procedure to `docs/internals/development/<topic>.md` and leave a one-line link. Create `development/` only at that point.

## 8. `docs/internals/adrs/`: the decision log

An ADR records one architectural decision: the context that forced it, what was decided, and what it costs. It's the audience-facing counterpart to explanation pages — `internals/architecture.md` says how the system *is*, an ADR says why it became that way and what else was on the table.

`docs/internals/adrs/README.md` always exists. It carries a one-paragraph description of the process, the template, and a table of the ADRs with their number, title, status and date.

**File format** — `NNNN-<kebab-title>.md`, zero-padded to four digits, sequential, numbers never reused:

```markdown
# NNNN. Title stated as the decision

- **Status**: Proposed | Accepted | Superseded by [NNNN](NNNN-other.md)
- **Date**: YYYY-MM-DD

## Context
What forced a decision. Constraints, and what was true at the time.

## Decision
What was chosen, in the active voice.

## Consequences
What this makes easy, what it makes hard, and what it rules out.
```

**Rules:**

- **ADRs are immutable once accepted.** A decision that gets reversed is not edited — a new ADR supersedes it, and the old one's Status line is updated to point at the new one. This is the sanctioned exception to *delete, don't archive*: superseded ADRs stay, forever, because the log's value is that it's a log.
- **Only write ADRs you can source.** In init mode, an ADR is warranted where the repo *evidences* a real decision: a design doc, a long "why" comment, an explicit trade-off in a commit message, a dependency chosen against an obvious alternative. Do not manufacture a decision history — inventing three plausible ADRs for a project that never made those decisions is exactly the failure the no-invention rule exists to prevent. If nothing is sourceable, `adrs/README.md` ships with the process and template and an empty table; that is the one landing page allowed to list nothing.
- **Date from evidence** — the commit, the file, the design doc — not from today. If the date can't be established, write `<!-- TODO: verify -->` rather than a plausible one.
- Backfilled ADRs say so in Context, in one sentence: recorded retroactively from *(the source)*.
- An ADR is a decision, not a topic. "Why we use Postgres" is an ADR; "how the storage layer works" is `internals/storage.md`.

## 9. Code-adjacent docs: `README.md` is the only exception

All documentation lives under `docs/`, except the two governed root files (§6, §7). A `README.md` may sit next to the code it documents, but only as a **lean pointer** — a sentence or two on what this directory is, plus links into `docs/` — never a docs home. Left ungoverned, code-adjacent runbooks grow into shadow doc trees with their own ad-hoc conventions.

So during init/adopt: migrate runbooks and nested doc trees into the sections per the §2 routing table, and leave a lean pointer `README.md` behind where a reader would expect one. Contributor-facing runbooks (`RUN-LOCAL.md`, `RELEASING.md`) route to `CONTRIBUTING.md` or `internals/development/`, not to `usage/`.

## 10. Content rules

- Plain Markdown, relative links only (never absolute URLs back to this repo — a future centralized doc portal needs to move these). Figure paths are relative too.
- **Lead with the visual where one applies** — see §11, which is a content rule of equal weight to these, not a garnish.
- **One Diátaxis mode per page.** Split a page that mixes modes (e.g. "how the bridge works" + "how to set the bridge up" becomes an `internals/` page and a `usage/` page), preserving all content. The section names no longer encode the mode, so this rule is enforced by reading, not by the path.
- **Audience is the section, mode is the page.** Where a subject has both a plain-language and an engineer-facing treatment, they are usually two pages in *different* sections (`usage/install.md` and `internals/architecture.md`), not two halves of one page. Where both belong to the same audience, keep them as sibling pages per §4 (`install.md`, `install-advanced.md`) rather than merging them.
- Clear and concise — prefer short paragraphs and bullet lists over prose. No filler.
- Don't leave placeholder/lorem-ipsum content. Every page must reflect real repo content, not a stub.

## 11. Visuals: show the shape, then explain it

A diagram conveys structure, sequence, and state faster than any paragraph, and it's what a reader looks at first. Treat a visual as the **default** for anything spatial, sequential, or stateful; let the prose explain what the picture can't say. Never caption-narrate — don't describe in text what the diagram already shows.

**Diagrams as code (Mermaid) are the default form.** They render on GitHub and in every common site generator, they diff reviewably, and they don't rot silently the way a screenshot does. Reach for a binary image only when the subject genuinely can't be drawn as code.

**Every section earns visuals — not just `internals`:**

- `internals` — architecture, component boundaries, data flow, state machines. **An architecture page with no diagram is incomplete**; add one before calling the section done.
- `usage` — the pipeline or sequence the recipe drives; a decision tree for troubleshooting ("symptom → check → fix"); the end state a tutorial is building, shown up front.
- `reference` — entity/schema relationships, lifecycle states, the shape of a config tree.
- `CONTRIBUTING.md` — the change lifecycle (branch → test → PR → CI → merge) when it's non-obvious.

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

**Figure files live in `docs/assets/`** (§3), named by the same rule as pages (§4) — kebab-case, subject first, tied to the page that uses them: `install-docker-network.png`, `architecture-request-flow.svg`. Reference them relatively (`../assets/…` from inside a section, `../../assets/…` from `usage/tutorials/` or `internals/adrs/`). If a diagram has an editable source (`.drawio`, `.excalidraw`), commit it next to the exported image under the same stem so the next person can edit rather than redraw.

**Always write real alt text** — `![Request flow from CLI through the queue to the worker](../assets/architecture-request-flow.svg)`. It's what a screen reader announces, what shows when the load fails, and what a grep finds. "Diagram", "screenshot", and "image" are not alt text.

**Never fabricate a visual.** The no-invention rule binds hardest here: a diagram asserts relationships as fact and reads as authoritative even when it's wrong. Draw only what you traced in the code, and never produce or describe a screenshot of a UI you haven't actually seen — leave a `<!-- TODO: verify -->` naming what the figure should show instead.

**In reconcile mode, audit visuals as its own pass** — the same way §4 audits naming. Docs written before this rule existed are text-only by default, and nothing else in this skill will sweep them: the §14 checks only catch a diagram-less architecture page, so `usage`, `reference` and `CONTRIBUTING.md` go unexamined unless you look on purpose. Walk every page in every section once and ask, in order:

1. **Does the page describe something with a shape** — components, an ordering, a lifecycle, a data model, a UI? If yes and it has no visual, that's the omission this pass exists to find. Add the diagram, typed per the table above.
2. **Is an existing diagram still true?** Trace it against the code as you would a prose claim. Stale nodes and dropped edges are the trim-on-touch standing rule applied to pictures.
3. **Is a long paragraph doing a diagram's job?** Prose that enumerates what talks to what, or walks through an ordered exchange step by step, is a diagram written out longhand. Replace it — don't keep both.
4. **Are figures in the right place with the right names?** Stray images beside pages or in per-section folders move to `docs/assets/` and get renamed per §4; every reference to them gets repointed (§13).
5. **Does every image have real alt text?** Add it where it's missing or where it's a placeholder like "diagram".
6. **Is anything a screenshot that shouldn't be?** Terminal output, logs, and code become fenced blocks; delete the image.

Restraint applies: don't add a visual to a page that has no shape to show, and don't bulk-generate diagrams to hit a quota — an invented diagram is worse than the text-only page it replaced. Where a page clearly warrants a visual but the repo doesn't tell you enough to draw it accurately, leave a `<!-- TODO: verify -->` describing the diagram it needs, and list those in the §15 summary so the user can fill the gaps. Report the pass per section: diagrams added, diagrams corrected, figures relocated, screenshots retired.

## 12. Redundancy: one canonical home per fact

Every fact — a command, a flag's meaning, a prerequisite, an architectural claim — lives on exactly **one** page. Every other place that needs it links there. This is what keeps docs maintainable: duplicated content doesn't stay duplicated, it *drifts*, and a reader who finds the stale copy has no way to know which one is current.

Duplication is not the same failure as a page mixing Diátaxis modes (§10). A mixed page has two kinds of content that should be split apart; duplication is the *same* content existing twice and needing to become one copy plus a link.

**Where it accumulates:**

- **Root `README.md` restating a section** — §6 already forbids this beyond the quickstart line; it's the most common instance.
- **`CONTRIBUTING.md` and `docs/internals/` restating each other** — the new instance this structure introduces. `CONTRIBUTING.md` instructs (run this command); `internals/` explains (this is why the pipeline has three stages). Where CONTRIBUTING starts explaining architecture, cut it to a link.
- **`CONTRIBUTING.md` and `docs/usage/` restating each other** — installing to use it and setting up to develop it are different procedures with overlapping commands. State each once, in its own audience's home; where they genuinely share a prerequisite, extract it.
- **A usage page restating its internals page** — a recipe that opens by re-deriving how the system works instead of linking to the page that explains it. Keep the one-line orientation, link for the rest.
- **An ADR restating an explanation page** — the ADR holds the decision and its consequences; the explanation page holds the current design. Neither reproduces the other.
- **A section landing `README.md` summarizing its pages** instead of indexing them. The landing says what's in the directory and links; it doesn't teach the material.
- **Two pages on the same subject that both went long** — usually a sign they should be one page, or that §4's grouping rules apply and the boundary between them needs to be stated in each.
- **A code-adjacent `README.md` that grew past a pointer** (§9).

**Shared setup steps are the honest exception.** When three usage pages genuinely need the same prerequisite block, extract it to its own page and link from all three — don't inline it three times, and don't force an artificial merge of three distinct recipes.

**In reconcile mode, audit redundancy as its own pass**, alongside naming (§4) and visuals (§11). Read each section's pages as a set rather than one at a time — duplication is invisible from inside a single page, which is exactly why it survives. For each subject covered in more than one place: pick the canonical page (the one whose section matches the audience and whose mode matches the content), keep the fullest correct version there, and replace every other copy with a link. Where the copies disagree, the repo decides which is right — not the longer or newer copy.

Deleting the duplicate is the point; leaving both with a "see also" is not a fix. But don't strip context so aggressively that a page stops standing on its own: a sentence of orientation plus a link is right, a bare link with no indication of why you'd follow it is not.

## 13. Moving a doc means repointing the repo

Doc paths leak far beyond `docs/`: code docstrings, JSON-schema descriptions, config examples, CI comments, agent instructions (`CLAUDE.md`, `.claude/`), and sometimes **tests that assert on doc paths**. When a page moves or is renamed, grep the whole repo and repoint every reference — including its figures, whose relative depth into `../assets/` changes on every move in the §3 migration table — no redirects, no stale paths left behind. Frozen historical material (old design docs, archived specs) is the one place stale paths may stay as written.

## 14. Verify before summarizing

- **Check the skeleton exists**: `README.md`, `CONTRIBUTING.md`, `docs/README.md`, `docs/usage/README.md`, `docs/reference/README.md`, `docs/internals/README.md`, `docs/internals/adrs/README.md`, `docs/assets/`. Script it.
- **Check nothing unexpected sits in `docs/`** — only `README.md`, the three sections, and `assets/`.
- Resolve every relative link **and every `![…]()` figure path** under `docs/`, plus the links in `README.md` and `CONTRIBUTING.md`, against the filesystem (script it — don't eyeball); fix all breakage. A broken image renders as silent alt text, so it survives review far longer than a broken link.
- Confirm the root `README.md` has every §6 section and that each one links to a path that exists.
- Check `docs/assets/` both ways: no figure referenced by a page is missing, and no file in `assets/` is unreferenced by any page. Wire up orphans or delete them.
- Confirm every Mermaid block opens with a valid diagram type and has a balanced fence — a typo'd block renders as raw text on GitHub.
- Check the ADR set: numbers are sequential with no duplicates, every file has a Status line, every "Superseded by" points at an ADR that exists, and `adrs/README.md`'s table matches the files on disk.
- Grep the repo for the old paths; require zero hits outside deliberately-frozen historical material.
- List each section's files and re-read them as a set: every group of same-subject pages uses one grouping mechanism (§4), and each section landing `README.md` lists exactly the files that are actually there.
- Re-read the `internals` pages: if one describes architecture or a flow and has no diagram (§11), it isn't finished.
- Check for orphan pages the same way you checked orphan assets: every page under `docs/` should be reachable from the `docs/README.md` router or a section landing. An unreachable page is either missing from a landing listing or is content nobody kept — resolve which, don't leave it dangling.
- Confirm the `usage/` boundary held: grep its pages for source-checkout instructions, internal component names, and build steps. Anything that turns up belongs in `CONTRIBUTING.md` or `internals/`.
- If a site generator exists, build it and require zero warnings.
- If doc paths appear in tests, run the test suite.

## 15. Finish with a summary

At the end, report: which parts of the skeleton were created versus already present; what content landed in each section and why; anything migrated from the older layout, with the old path → new path; pages renamed or deleted (with the reason); what went into `README.md` and `CONTRIBUTING.md`, and which of their sections were dropped because the repo doesn't have them; which ADRs were written and what evidence each came from (and say plainly if none were, because none were sourceable); the results of the visuals pass (§11) — diagrams added, diagrams corrected, figures relocated, screenshots retired; the results of the redundancy pass (§12), naming each subject that was consolidated and which page became canonical; the verification results (skeleton check, link/figure check, orphan check, ADR check, build, tests); and everything marked `<!-- TODO: verify -->` that needs the user's input because it couldn't be confirmed from the repo alone.
