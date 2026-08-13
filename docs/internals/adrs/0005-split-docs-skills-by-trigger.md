# 0005. Split the documentation skills by what triggers them, not by cost alone

- **Status**: Accepted
- **Date**: 2026-08-13

## Context

[ADR 0002](0002-split-init-and-update-into-two-skills.md) split documentation work into `docs-init` and `docs-update` along a cost axis: a whole-repo survey that catches drift, and a cheap per-change run that keeps up with commits.

Two situations that axis doesn't cover came up in use. Someone reading the docs wants an answer out of them, with no change involved at all. And someone reading the docs wants them *different* — clearer, shorter, in their own house style — with no code change behind the request.

Neither fits the existing pair. `docs-update` takes its scope from a diff and its authority from the repo; asked to act on a request instead, its whole spine is inapplicable — there are no removals to sweep and no change to route. `docs-init` covers the second case only by re-auditing the entire tree, which is the wrong price for "rewrite this page in British spelling". Folding either situation into an existing skill also means one skill with two authorities, and the failure mode is silent: an instruction from a person can assert behavior the code doesn't have, where a diff cannot.

Question-answering is different again. It needs no write access at all, and giving it any means the user cannot invoke it mid-task without risking edits they didn't ask for.

## Decision

Split by **what triggered the run**, which also fixes what the run may treat as authoritative:

| Skill | Trigger | Authority | Writes |
|---|---|---|---|
| `docs-init` | An undocumented or unswept tree | the repo | yes |
| `docs-update` | A code change | the diff | yes |
| `docs-edit` | A person wanting the docs different | the user for style, the repo for facts | yes |
| `docs-search` | A person wanting to know something | the docs | no |

`docs-edit` carries the rule the split exists to isolate — the user decides how the docs read, the repo decides what they say — and verifies every factual claim in a request before writing it. `docs-search` is read-only, and because it never writes it doesn't require the convention either, so it works on layouts the other three refuse.

Each skill's description names the siblings it defers to, so the four stay distinguishable at selection time.

## Consequences

- Each skill has one authority, so no run has to decide which of two sources wins.
- A question can be asked mid-task without risking an edit, which is what makes `docs-search` usable at all.
- `docs-search` doubles as the cheapest drift detector in the set: it reads a page against the code exactly when someone cares about that page, and reports contradictions instead of fixing them.
- Four skills whose names all start `docs-` are four chances to invoke the wrong one. Each description now has to carve out what it *isn't*, and that boundary text has to be maintained as a set.
- The convention now lives in four files. ADR 0002's warning compounds: `docs-update` and `docs-edit` both reference `docs-init`'s numbered sections rather than restating rules, so renumbering `docs-init` is a breaking edit for three files. The new pair is kept deliberately thin to limit the blast radius, but nothing enforces that.
