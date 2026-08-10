# 0003. Make diagrams-as-code the default, in every section

- **Status**: Accepted
- **Date**: 2026-07-23

## Context

Recorded retroactively from commit `7164953`, which introduced the visuals rules into both skills.

Before this, visuals were implicitly optional and, where they appeared at all, treated as decoration on architecture pages. Generated docs came out text-only by default, including for subjects — component graphs, request sequences, lifecycles, schemas — that a reader parses far faster from a picture than from a paragraph.

Two forms were available. A checked-in image (screenshot, exported diagram) can show anything, but rots invisibly: it doesn't diff, review can't see what changed inside it, and nothing fails when the system it depicts moves on. Mermaid renders on GitHub and in common site generators, diffs as text, and is reviewable line by line.

## Decision

A visual is the default for anything spatial, sequential, or stateful, in every section — not only `internals`. Mermaid is the default form; binary images are reserved for what code can't draw (real UI, dashboards, hardware).

The diagram type is selected from the content — `flowchart`, `sequenceDiagram`, `stateDiagram-v2`, `erDiagram` — rather than defaulting to `flowchart`. Figures live in a single flat `docs/assets/`, and every image carries real alt text.

Diagrams are bound to the same no-invention rule as prose, and node-by-node diagram review is an explicit step whenever something is removed.

## Consequences

- An architecture page with no diagram is treated as incomplete, so the gap is caught rather than tolerated.
- Diagrams survive review: a wrong edge shows up in a pull request as a changed line.
- A wrong diagram is more damaging than a wrong sentence, because readers trust the picture over the prose around it — which is why the no-invention rule binds harder here than anywhere else, and why an unverifiable diagram is left as a `<!-- TODO: verify -->` instead of drawn.
- Reconcile runs need a dedicated visuals pass, because docs written before this decision are text-only by default and no other check sweeps them.
- Mermaid's expressiveness now bounds what gets drawn. Subjects it renders badly are either simplified into it or left to prose.
