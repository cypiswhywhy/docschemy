---
name: docs-init
description: Scaffold or reconcile a project's docs/ directory using the Diátaxis framework (Tutorials, How-To Guides, Reference, Explanation). Migrates content from the existing README, code, comments, and config into the right quadrant, adds Mermaid diagrams for architecture, and only creates the quadrants that actually make sense for the project. Use when setting up documentation for a new or undocumented project, or when updating an already-documented project to match the latest docs/ convention.
---

# docs-init

Sets up or updates a project's `docs/` directory following the Diátaxis framework. Two modes — pick based on what's already there.

**Init mode**: no `docs/` yet, or an existing `docs/` that doesn't follow this convention.
**Reconcile mode**: `docs/` already follows this convention but may be incomplete, stale, or need a flat file promoted to a directory as it's grown.

Never invent facts, features, flags, or behavior that isn't actually in the code/config. If something is genuinely unclear from the repo, write a `<!-- TODO: verify -->` marker instead of guessing.

## 1. Survey before writing anything

Read, in this order: `README.md`, any existing `docs/` or scattered `*.md` files, `package.json`/`pyproject.toml`/`Cargo.toml`/etc. for name/description/scripts, the CLI entrypoint or main API surface, `.claude/skills/*/SKILL.md` and `.claude/commands/*.md` (project-local Claude Code skills/slash commands, if the repo defines any), CI config, and code comments/docstrings that explain non-obvious behavior. Build a mental model of what the project actually does before deciding structure.

## 2. Decide which quadrants apply

Don't create all four by default. Populate a quadrant only if it earns its keep:

- **Tutorials** (`docs/tutorials/`) — only if there's a real learning-oriented onboarding path (e.g. a library/framework someone needs to learn by doing). Skip for scripts, internal pipelines, and most services.
- **How-To Guides** (`docs/how-to-guides/`) — goal-oriented recipes: install, configure, deploy, run common tasks, troubleshoot. Include if there's more than one thing a user/operator would need to *do* with this project.
- **Reference** (`docs/reference/`) — CLI flags, API endpoints, config schema, env vars, and project-local Claude Code skills/slash commands (`.claude/skills/`, `.claude/commands/`) if the repo defines any — list each with its name and what it does. Include only if there's a real, stable surface worth looking up (skip for a one-off script with no options).
- **Explanation** (`docs/explanation/`) — architecture, internals, design decisions, Mermaid diagrams. Almost always include this one unless the project is genuinely trivial (a single-file script with no interesting structure).

If it's a close call, state your reasoning briefly and ask the user to confirm rather than silently guessing.

## 3. File vs. directory per quadrant

Start flat: a single `docs/<quadrant>.md`. Only use a directory (`docs/<quadrant>/` with an `index.md` listing its contents, plus one file per distinct topic) once that quadrant genuinely has more than one topic worth separating — e.g. `docs/reference/cli.md` + `docs/reference/config.md`, or `docs/how-to-guides/deploy.md` + `docs/how-to-guides/configure-auth.md`.

In **reconcile mode**, if a flat file has accumulated multiple distinct topics, promote it to a directory: create the `index.md`, split the content into topic files by section, and preserve everything — don't drop content during the split.

Naming is fixed so a future cross-project doc portal can rely on convention: `tutorials`, `how-to-guides`, `reference`, `explanation` — always these exact names, whether flat file or directory.

## 4. Root README.md

Keep it short: one-paragraph pitch, a minimal quickstart, and a links section pointing to whichever `docs/<quadrant>.md` or `docs/<quadrant>/index.md` files exist. Don't duplicate content that belongs in `docs/` — link to it instead.

## 5. Content rules

- Plain Markdown, relative links only (never absolute URLs back to this repo — a future centralized doc portal needs to move these).
- Mermaid diagrams for architecture/flow live in `explanation.md` (or `explanation/architecture.md`).
- Clear and concise — prefer short paragraphs and bullet lists over prose. No filler.
- Don't leave placeholder/lorem-ipsum content. If a quadrant is created, it must reflect real repo content, not a stub.

## 6. Finish with a summary

At the end, report: which quadrants were created/updated, which were deliberately skipped and why, and anything marked `<!-- TODO: verify -->` that needs the user's input because it couldn't be confirmed from the repo alone.
