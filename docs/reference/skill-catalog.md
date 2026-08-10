# Skill catalog

The skills this repo ships. Each becomes a slash command of the same name once installed — `/docs-init`, `/docs-update`.

Both encode one shared documentation convention: in-repo Markdown, laid out in a fixed structure (`README.md`, `CONTRIBUTING.md`, and `docs/` holding `usage/`, `reference/`, `internals/` and `assets/`) with the Diátaxis modes routed into it by audience. See [the documentation convention](../internals/documentation-convention.md) for why it's shaped that way, and [Choosing between them](../usage/documenting-a-project.md#choosing-between-them) for which one to run.

## `docs-init`

Scaffolds or reconciles a project's whole documentation tree. Surveys the repo (README, existing Markdown, manifests, CLI surface, project-local `.claude/` skills, task runner, CI config), creates the full skeleton, migrates code-adjacent runbooks into it, and runs dedicated audit passes over page naming, visuals, and cross-page redundancy.

Operates in one of three modes, selected from what's already in the repo:

| Mode | When | Behavior |
|---|---|---|
| Init | No docs, or only scattered Markdown | Scaffolds the skeleton and migrates existing content into it |
| Reconcile | Docs already follow this convention, or the older Diátaxis-only layout | Fills gaps, migrates old quadrant paths into the sections, and runs the naming / visuals / redundancy audits |
| Adopt | Docs follow a *different* deliberate convention | Names the migration costs and asks before restructuring |

It also writes `README.md` and `CONTRIBUTING.md` to a fixed set of sections, and maintains `docs/internals/adrs/`.

## `docs-update`

The cheap incremental counterpart: updates an existing tree to reflect one specific change, without re-surveying the project. Scope comes from the conversation, uncommitted changes, or a commit range the user names.

Deliberately narrow — it only opens the sections the change actually touches, treats the removals in a diff as first-class scope (deleting docs for what's gone, including stale diagram nodes), and *reports* rather than fixes anything stale or duplicated outside that scope. It does reach outside `docs/` for the two governed root files, and writes an ADR when a change carries a real design decision.

Requires a tree that already follows the convention; if there isn't one, or if it still uses the older quadrant layout, it stops and points at `/docs-init`.
