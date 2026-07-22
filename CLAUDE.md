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

The two skills currently in this repo (`docs-init`, `docs-update`) implement a documentation convention this user applies across *other* projects — worth understanding since it's the repo's reason for existing, and since this repo's own `docs/` follows the same convention:

- Docs live in-repo, in Markdown, structured per the [Diátaxis](https://diataxis.fr/) framework: `tutorials`, `how-to-guides`, `reference`, `explanation` — always these exact quadrant names.
- Each quadrant is either a flat `docs/<quadrant>.md` or, once it outgrows one topic, a directory `docs/<quadrant>/` with a `README.md` landing page + one file per topic (`README.md`, never `index.md` — GitHub renders it when browsing, site generators accept it as the section index, and having both collides). Promote flat→directory only when content genuinely warrants it; never drop content in the process.
- `docs/` contains only the quadrant entries plus a `README.md` router — the sole extra allowed is a single `assets/` when a static-site generator requires site infrastructure inside the docs dir. Planning notes and historical material live outside `docs/`.
- All docs live under `docs/`; the one exception is a code-adjacent `README.md`, which is a lean pointer (what this directory is + links into `docs/`), never a docs home.
- Page names are derived by rule, not chosen per page: lowercase kebab-case, subject first and qualifier second (`install-docker.md`, never `docker-install.md`), no doc-type suffixes. Pages on the same subject are grouped by exactly one mechanism — a shared `<subject>-` prefix for two or three, a `<subject>/` subdirectory beyond that — never both at once. A new page that doesn't fit the pattern means renaming the old ones.
- Docs for things that no longer exist get deleted, along with every link to them; `docs-update` treats the removals in a diff as first-class scope, not just the additions.
- Only create a quadrant if it earns its keep for that project (e.g. skip `tutorials` for a script with no onboarding path); `explanation` is nearly always worth having.
- Mermaid diagrams for architecture/flow belong in `explanation`; one Diátaxis mode per page — split pages that mix explanation with how-to.
- Relative links only — never absolute URLs back to a repo — so docs can later be pulled into a centralized cross-project doc portal. When a doc moves, grep the whole repo (code, tests, CI, `CLAUDE.md`) and repoint every reference; no redirects.
- Never invent facts, flags, or behavior not actually present in the code/config; mark genuine gaps with `<!-- TODO: verify -->`. Stale claims that *can* be verified against the repo get fixed on touch, not copied forward.
- `docs-init` surveys a whole project and creates/reconciles all quadrants (and asks before restructuring a repo that follows a different deliberate convention); `docs-update` is the cheap incremental variant, run after a specific change (or against a diff/commit range) to update only the quadrants that change actually touches.
