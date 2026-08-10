# 0004. Wrap Diátaxis in a fixed structural strategy

- **Status**: Accepted
- **Date**: 2026-08-10

## Context

Recorded from commit `87011bc`.

The skills laid documentation out by Diátaxis quadrant alone: `tutorials`, `how-to-guides`, `reference`, `explanation`, each starting as a flat `docs/<quadrant>.md` and promoted to a directory once it outgrew one topic, and each created only if it "earned its keep" for that project.

Two problems followed. First, the layout differed in every repo — a quadrant might be a file or a directory, present or absent — so no habit, script, or cross-project portal could rely on a path existing. Second, Diátaxis classifies pages by mode and says nothing about audience, which left contributors with no home: setting up a dev environment and submitting a change is a how-to, but filing it beside end-user recipes buries it, and there was nowhere else for it to go.

## Decision

Keep Diátaxis for pages; add a fixed structural layer for paths. Audience selects the directory, mode selects the page.

`README.md`, `CONTRIBUTING.md`, and `docs/` with `README.md`, `usage/`, `reference/`, `internals/` (containing `adrs/`), and `assets/` are created in every project, in full, whether or not a given section is thick. Sections are always directories with a `README.md` landing; the flat-file form and the promote-on-growth rule are retired. Contributor how-tos go to `CONTRIBUTING.md`, overflowing to `docs/internals/development/`. Architecture decisions get `docs/internals/adrs/`.

`docs/usage/` is held to a black-box rule: a page requiring a source checkout or knowledge of internal components belongs to the contributor or engineer audience instead.

## Consequences

- Every project reads the same way, and a path can be relied on without looking.
- Contributors and decision records have real homes, closing the two gaps Diátaxis leaves.
- Thin sections still carry a landing page, and small repos hold more directories than their content strictly needs. Accepted: predictable paths are worth more than minimal ones.
- Mode is no longer visible in the path, so "one Diátaxis mode per page" is enforced by reading rather than by directory — a weaker guarantee than the old layout gave.
- Every project already on the quadrant layout needs a migration, which is `docs-init`'s reconcile mode; the old paths break with no redirects.
- Two new duplication risks appear where none existed: `CONTRIBUTING.md` against `docs/internals/`, and `CONTRIBUTING.md` against `docs/usage/`. Both are named explicitly in the redundancy rules.
