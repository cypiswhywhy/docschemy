---
name: docs-init
description: Scaffold or reconcile a project's docs/ directory using the Diátaxis framework (Tutorials, How-To Guides, Reference, Explanation). Migrates content from the existing README, code, comments, config, and code-adjacent runbooks into the right quadrant, adds Mermaid diagrams for architecture, and only creates the quadrants that actually make sense for the project. Use when setting up documentation for a new or undocumented project, or when updating an already-documented project to match the latest docs/ convention.
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
- **A static-site generator config** (`mkdocs.yml`, Docusaurus, Sphinx `conf.py`). If one exists, every move must also update its nav/config, and the build must end green — and site constraints shape the layout (see the `assets/` exception in §3).

Build a mental model of what the project actually does before deciding structure.

## 2. Decide which quadrants apply

Don't create all four by default. Populate a quadrant only if it earns its keep:

- **Tutorials** (`docs/tutorials/`) — only if there's a real learning-oriented onboarding path (e.g. a library/framework someone needs to learn by doing). Skip for scripts, internal pipelines, and most services.
- **How-To Guides** (`docs/how-to-guides/`) — goal-oriented recipes: install, configure, deploy, run common tasks, troubleshoot. Include if there's more than one thing a user/operator would need to *do* with this project.
- **Reference** (`docs/reference/`) — CLI flags, API endpoints, config schema, env vars, and project-local Claude Code skills/slash commands (`.claude/skills/`, `.claude/commands/`) if the repo defines any — list each with its name and what it does. Include only if there's a real, stable surface worth looking up (skip for a one-off script with no options).
- **Explanation** (`docs/explanation/`) — architecture, internals, design decisions, Mermaid diagrams. Almost always include this one unless the project is genuinely trivial (a single-file script with no interesting structure).

If it's a close call, state your reasoning briefly and ask the user to confirm rather than silently guessing.

## 3. Layout rules

- **Start flat**: a single `docs/<quadrant>.md`. Only use a directory (`docs/<quadrant>/` with a `README.md` landing page listing its contents, plus one file per distinct topic) once that quadrant genuinely has more than one topic worth separating — e.g. `docs/reference/cli.md` + `docs/reference/config.md`.
- **Landing pages are `README.md`, not `index.md`** — GitHub renders `README.md` when someone browses the folder, and site generators (MkDocs et al.) accept it as the section index. Never put both `README.md` and `index.md` in one folder; generators treat both as the index and they collide.
- In **reconcile mode**, if a flat file has accumulated multiple distinct topics, promote it to a directory: create the `README.md` landing, split the content into topic files by section, and preserve everything — don't drop content during the split.
- **`docs/` contains only the quadrant entries plus a `README.md` router** (the router earns its keep once quadrants become directories). One pragmatic exception: with a static-site generator, a single `docs/assets/` may hold site infrastructure (logo, favicon, CSS) because generators only serve files inside the docs dir; theme overrides/templates live *outside* `docs/` with the tooling. Planning notes, ADR archives, and other historical material live outside `docs/` entirely.
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
- **A new page that breaks the pattern means renaming the old ones, not naming the new one badly.** If a third page joins `install.md` + `install-advanced.md` under a name like `getting-started-on-macos.md`, the fix is `install-macos.md` — or promoting all three to `install/`. Renames follow §8 (repoint the whole repo).
- **In reconcile mode, audit naming as its own pass**: for each quadrant, group the existing pages by subject and check that every group uses one mechanism consistently. Off-pattern names that are genuinely about the same subject get renamed; report each rename in the summary, since the user may have had a reason for the old name.

## 5. Code-adjacent docs: `README.md` is the only exception

All documentation lives under `docs/`. A `README.md` may sit next to the code it documents, but only as a **lean pointer** — a sentence or two on what this directory is, plus links into `docs/` — never a docs home. Left ungoverned, code-adjacent runbooks grow into shadow doc trees with their own ad-hoc conventions.

So during init/adopt: migrate runbooks and nested doc trees into the quadrants, and leave a lean pointer `README.md` behind where a reader would expect one.

## 6. Root README.md

Keep it short: one-paragraph pitch, a minimal quickstart, and a links section pointing to whichever `docs/<quadrant>.md` or `docs/<quadrant>/README.md` files exist. Don't duplicate content that belongs in `docs/` — link to it instead.

## 7. Content rules

- Plain Markdown, relative links only (never absolute URLs back to this repo — a future centralized doc portal needs to move these).
- Mermaid diagrams for architecture/flow live in `explanation.md` (or `explanation/architecture.md`).
- **One Diátaxis mode per page.** Split a page that mixes modes (e.g. "how the bridge works" + "how to set the bridge up" becomes an explanation page and a how-to page), preserving all content.
- **Quadrant is the primary split; audience is secondary but real.** Keep a plain-language guide and its engineer-facing counterpart as separate pages within the same quadrant (e.g. `install.md` and `install-advanced.md`, per §4) rather than merging them because they share a topic.
- Clear and concise — prefer short paragraphs and bullet lists over prose. No filler.
- Don't leave placeholder/lorem-ipsum content. If a quadrant is created, it must reflect real repo content, not a stub.

## 8. Moving a doc means repointing the repo

Doc paths leak far beyond `docs/`: code docstrings, JSON-schema descriptions, config examples, CI comments, agent instructions (`CLAUDE.md`, `.claude/`), and sometimes **tests that assert on doc paths**. When a page moves or is renamed, grep the whole repo and repoint every reference — no redirects, no stale paths left behind. Frozen historical material (old design docs, archived specs) is the one place stale paths may stay as written.

## 9. Verify before summarizing

- Resolve every relative link under `docs/` against the filesystem (script it — don't eyeball); fix all breakage.
- Grep the repo for the old paths; require zero hits outside deliberately-frozen historical material.
- List each quadrant's files and re-read them as a set: every group of same-subject pages uses one grouping mechanism (§4), and each quadrant landing `README.md` lists exactly the files that are actually there.
- If a site generator exists, build it and require zero warnings.
- If doc paths appear in tests, run the test suite.

## 10. Finish with a summary

At the end, report: which quadrants were created/updated, which were deliberately skipped and why, any pages renamed or deleted (with the reason), the verification results (link check, build, tests), and anything marked `<!-- TODO: verify -->` that needs the user's input because it couldn't be confirmed from the repo alone.
