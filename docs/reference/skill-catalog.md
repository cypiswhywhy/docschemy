# Skill catalog

The skills this repo ships. Each becomes a slash command of the same name once installed — `/docs-init`, `/docs-update`, `/docs-edit`, `/docs-search`.

All four encode one shared documentation convention: in-repo Markdown, laid out in a fixed structure (`README.md`, `CONTRIBUTING.md`, and `docs/` holding `usage/`, `reference/`, `internals/` and `assets/`) with the Diátaxis modes routed into it by audience. See [the documentation convention](../internals/documentation-convention.md) for why it's shaped that way, and [Choosing between them](../usage/documenting-a-project.md#choosing-between-them) for which one to run.

They divide the work by **what triggered it**, which also decides what each one treats as authoritative:

| Skill | Runs when | Takes its instructions from | Writes? |
|---|---|---|---|
| [`docs-init`](#docs-init) | There are no docs, or the whole tree needs auditing | The repo | yes |
| [`docs-update`](#docs-update) | The code changed | The diff | yes |
| [`docs-edit`](#docs-edit) | A person wants the docs different | The user for style, the repo for facts | yes |
| [`docs-search`](#docs-search) | A person wants to know something | The docs | **no** |

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

The cheap incremental counterpart: updates an existing tree to reflect one specific change, without re-surveying the project. Scope comes from the conversation, uncommitted changes, or a commit range you name.

Deliberately narrow — it only opens the sections the change actually touches, treats the removals in a diff as first-class scope (deleting docs for what's gone, including stale diagram nodes), and *reports* rather than fixes anything stale or duplicated outside that scope. It does reach outside `docs/` for the two governed root files, and writes an ADR when a change carries a real design decision.

Requires a tree that already follows the convention; if there isn't one, or if it still uses the older quadrant layout, it stops and points at `/docs-init`.

## `docs-edit`

Changes the docs because a person wants them different — clearer, shorter, restructured, in their own voice — with no code change behind it. The other write-skills read the repo or a diff for instructions; this one reads the user, which makes its central rule the split between the two authorities: **the user decides how the docs read, the repo decides what they say.**

Every clause of a request is sorted into one of three kinds:

| Kind | Example | Treatment |
|---|---|---|
| Style | "shorter", "use our terms", "diagram first" | The user's call — applied as asked |
| Structure | "split this page", "rename these" | Applied within the convention; a rule it would break is named and costed before the user decides |
| Fact | "mention that it retries three times" | Checked against the code first — contradicted claims are reported, not written |

It also maintains the **preferences layer** — a `## Docs preferences` block in `CLAUDE.md` that all four skills read, which is what stops the next `/docs-update` from reverting a deliberate deviation. [Recording a preference](../usage/documenting-a-project.md#recording-a-preference) shows the block and how to set one. Applying one rule across every page — "make it all consistent with this" — is a sweep, and belongs here rather than in a full reconcile.

It writes no ADRs: a decision that actually changed is `docs-update`'s job, and accepted ADRs are immutable.

## `docs-search`

Answers a question from the existing docs, and **never writes** — no edits, no new pages, which is what makes it safe to invoke in the middle of unrelated work.

It searches audience-first rather than grepping blind: the structure predicts where an answer lives, and "why" questions route to `docs/internals/adrs/`, the place nobody thinks to look. It cites the page and heading each part of the answer came from, and never cites a page it didn't open.

Every run ends in one of three outcomes, and says which:

| Outcome | What you get |
|---|---|
| The docs answer it | The answer, cited; operational claims (commands, flags, defaults) spot-checked against the code |
| The docs are silent | Said plainly, then answered from the code if possible, with the gap named |
| The docs contradict the code | Both readings, the code marked as what actually runs, and the wrong page cited |

That third outcome makes it the cheapest drift detector in the set — it reads a page against the code at the moment someone actually cares about that page. It hands off what it finds (`/docs-edit`, `/docs-update`, or a `/docs-init` reconcile) rather than fixing it.

Unlike `docs-update`, it doesn't require the convention: an older layout, someone else's structure, or a bare `README.md` all still get searched.
