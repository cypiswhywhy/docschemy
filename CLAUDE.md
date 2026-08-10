# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`docschemy` is the single source of truth for the user's personal Claude Code skills, shared across many unrelated projects. Each skill lives once under `skills/<name>/SKILL.md` and is symlinked (not copied) into `~/.claude/skills/<name>`, so editing a skill here immediately affects every project that uses it — no reinstall step.

There is no application source code here; this repo *is* the skills + their docs.

## Commands

```sh
make install
```

The only command. It symlinks every directory under `skills/` into `~/.claude/skills/`. It's idempotent: already-linked skills are reported as such, and it never clobbers a pre-existing non-symlinked path (skips with a warning instead — the conflict must be resolved manually).

There is no build, lint, or test step.

## Working on skills

- A skill is a directory `skills/<skill-name>/` containing `SKILL.md` with YAML frontmatter (`name`, `description`) followed by plain-Markdown instructions. `description` is what Claude Code uses to decide when the skill is relevant, so keep it specific.
- Adding a new skill: create the directory + `SKILL.md`, then `make install`, then restart/reload Claude Code to pick it up.
- Editing an existing skill: just edit `skills/<skill-name>/SKILL.md` directly — because it's symlinked, no reinstall is needed.

## The docs-init / docs-update skills

The two skills currently in this repo (`docs-init`, `docs-update`) implement a documentation convention this user applies across *other* projects — worth understanding since it's the repo's reason for existing, and since this repo's own docs are meant to follow the same convention (they still use the older Diátaxis-only layout and need a `docs-init` reconcile to migrate):

- Docs live in-repo, in Markdown. [Diátaxis](https://diataxis.fr/) governs *pages*; a fixed **structural strategy** governs *paths*, so every project has an identical layout and the audiences Diátaxis leaves out (contributors above all) get a home:

  ```
  README.md            standard entry point: title, description, install, usage/reference/internals/contributing links
  CONTRIBUTING.md      contributor entry point: prerequisites, setup, tests, PR flow, release
  docs/
    README.md          router
    usage/             end users — the project as a black box. How-to pages at this level; tutorials/ below it.
    reference/         factual lookup, often generated — cli.md, http-api.md, configuration.md, skills.md, …
    internals/         engineers — architecture and design. adrs/ always; development/ when CONTRIBUTING.md overflows.
    assets/            every figure, flat
  ```

- **The skeleton is always created in full**, even when a section is thin — that guarantee is the point, so a reader or a script can rely on the path existing. A thin section gets a real landing that says what belongs there. Only a genuinely trivial repo (single-file script, no options, no build) may stop at `README.md`.
- Routing is **audience first, then Diátaxis mode**: tutorials → `usage/tutorials/`, how-tos → `usage/`, reference → `reference/`, explanation → `internals/`, decision records → `internals/adrs/`, contributor procedures → `CONTRIBUTING.md` (overflow to `internals/development/`). The `usage/` boundary is strict: anything needing a source checkout or internal component knowledge isn't a usage page.
- Sections are always directories with a `README.md` landing (never `index.md`, never both, never a flat `docs/<section>.md`). A landing indexes its pages; it doesn't teach them.
- `docs/` contains exactly `README.md`, the three sections, and a single flat `assets/` holding every figure the docs reference (plus site infrastructure when a static-site generator requires it inside the docs dir). No per-section `images/` folders. Planning notes and historical material live outside `docs/`.
- All docs live under `docs/` apart from the two governed root files; the one further exception is a code-adjacent `README.md`, which is a lean pointer (what this directory is + links into `docs/`), never a docs home.
- Page names are derived by rule, not chosen per page: lowercase kebab-case, subject first and qualifier second (`install-docker.md`, never `docker-install.md`), no doc-type suffixes (`reference/api.md`, never `api-reference.md`). Pages on the same subject are grouped by exactly one mechanism — a shared `<subject>-` prefix for two or three, a `<subject>/` subdirectory beyond that — never both at once. A new page that doesn't fit the pattern means renaming the old ones. ADRs are the exception: `NNNN-<slug>.md`, numbered.
- **ADRs are immutable and append-only** — a reversed decision gets a new ADR that supersedes the old one, whose Status line is updated; superseded records are never deleted. They're written only where the repo actually evidences a decision; a manufactured decision history is the no-invention rule's worst failure. Otherwise, docs for things that no longer exist get deleted along with every link to them, and `docs-update` treats the removals in a diff as first-class scope, not just the additions.
- **A visual is the default for anything spatial, sequential, or stateful, in every section** — not a garnish on `internals`. Diagrams-as-code (Mermaid) are the default form because they render on GitHub, diff reviewably, and don't rot silently; the diagram type is picked from the content (`flowchart` / `sequenceDiagram` / `stateDiagram-v2` / `erDiagram`), not defaulted to `flowchart`. An architecture page with no diagram is incomplete. Screenshots are reserved for what code can't draw (real UI, dashboards, hardware) — never for terminal output or code — and every image carries real alt text. Diagrams are held to the same no-invention rule as prose, more strictly: a wrong diagram reads as authoritative.
- One Diátaxis mode per page — split pages that mix explanation with how-to. The section names no longer encode the mode, so this is enforced by reading, not by the path.
- **One canonical home per fact**: a command, flag, prerequisite, or architectural claim lives on exactly one page; everywhere else links to it. Duplicated content drifts, and the reader who finds the stale copy can't tell. Shared setup steps extracted to their own linked page are the honest exception, as is the single quickstart line the root `README.md` is allowed to carry. The pairs that duplicate hardest under this structure are `CONTRIBUTING.md` vs `internals/` (instruct vs explain) and `CONTRIBUTING.md` vs `usage/` (set up to develop vs install to use). Deleting the duplicate is the fix — not a "see also" beside it.
- Relative links only — never absolute URLs back to a repo — so docs can later be pulled into a centralized cross-project doc portal. When a doc moves, grep the whole repo (code, tests, CI, `CLAUDE.md`) and repoint every reference; no redirects.
- Never invent facts, flags, or behavior not actually present in the code/config; mark genuine gaps with `<!-- TODO: verify -->`. Stale claims that *can* be verified against the repo get fixed on touch, not copied forward.
- `docs-init` surveys a whole project, scaffolds the skeleton, and creates/reconciles every section (and asks before restructuring a repo that follows a different deliberate convention); `docs-update` is the cheap incremental variant, run after a specific change (or against a diff/commit range) to update only the sections that change actually touches — including `README.md` and `CONTRIBUTING.md`, which sit outside `docs/` and so go stale unnoticed. Retrofitting an already-documented project to a newer version of this convention — including migrating the older Diátaxis-only layout (`docs/tutorials`, `docs/how-to-guides`, `docs/explanation` at top level) into `usage`/`reference`/`internals` — is `docs-init`'s reconcile mode, not `docs-update`. Reconcile runs dedicated audit passes over naming, visuals, and redundancy across every page; `docs-update` only ever touches what the change touched, and reports rather than fixes anything stale or duplicated outside that scope.
