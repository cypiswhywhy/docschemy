# Skill catalog

The skills this repo ships. Each becomes a slash command of the same name once installed — `/docs-init`, `/docs-update`.

Both encode one shared documentation convention: docs live in-repo as Markdown under `docs/`, split into the [Diátaxis](https://diataxis.fr/) quadrants `tutorials`, `how-to-guides`, `reference`, `explanation`, with diagrams-as-code as the default way to show anything structural. See [Explanation](../explanation.md) for why the convention is shaped that way, and [Choose between `docs-init` and `docs-update`](../how-to-guides.md#choose-between-docs-init-and-docs-update) for which one to run.

## `docs-init`

Scaffolds or reconciles a project's whole `docs/` directory. Surveys the repo (README, existing Markdown, manifests, CLI surface, project-local `.claude/` skills, CI config), decides which quadrants earn their keep, migrates code-adjacent runbooks into them, and runs dedicated audit passes over page naming, visuals, and cross-page redundancy.

Operates in one of three modes, selected from what's already in the repo:

| Mode | When | Behavior |
|---|---|---|
| Init | No `docs/`, or only scattered Markdown | Creates the quadrants that apply and migrates existing content into them |
| Reconcile | `docs/` already follows this convention | Fills gaps, promotes outgrown flat files to directories, and runs the naming / visuals / redundancy audits |
| Adopt | `docs/` follows a *different* deliberate convention | Names the migration costs and asks before restructuring |

## `docs-update`

The cheap incremental counterpart: updates an existing `docs/` tree to reflect one specific change, without re-surveying the project. Scope comes from the conversation, uncommitted changes, or a commit range the user names.

Deliberately narrow — it only opens the quadrants the change actually touches, treats the removals in a diff as first-class scope (deleting docs for what's gone, including stale diagram nodes), and *reports* rather than fixes anything stale or duplicated outside that scope.

Requires a `docs/` that already follows the convention; if there isn't one, it stops and points at `/docs-init`.
