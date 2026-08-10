# 0002. Split documentation work into two skills rather than one

- **Status**: Accepted
- **Date**: 2026-07-07

## Context

Recorded retroactively from commit `b47e00d`, which introduced `docs-init` and `docs-update` together, and the rationale written up in the repo's own docs.

One documentation convention has to be applied in two situations with opposite cost profiles. Setting up or auditing a project's whole `docs/` tree means reading the entire repo and checking every page for naming, visuals and duplication — expensive, and the only thing that catches drift. Reflecting a single change means touching a few pages — cheap enough to run after every commit.

A single skill covering both has to choose a default. Running the full survey after a small change wastes the run and invites restructuring of pages that change never touched. Running the narrow path over a whole project silently under-audits it.

## Decision

Ship two skills over one convention. `docs-init` surveys the whole project and owns the naming, visuals and redundancy audits. `docs-update` is scoped to one change and never opens a page that change didn't touch.

Each skill is told to defer on the other's failure mode rather than guess: `docs-update` reports what it can't vouch for and names `/docs-init` as the sweep.

## Consequences

- The expensive audit exists and is honest, because nothing forces it to run on every commit.
- The cheap path is cheap enough to actually get run, which is what keeps docs current.
- The user has to pick, so the choice is documented as a decision tree rather than left implicit.
- The convention now lives in two files that must not drift apart. `docs-update` deliberately references `docs-init`'s numbered sections instead of restating rules, which makes the dependency explicit but means section renumbering in `docs-init` is a breaking edit for both.
