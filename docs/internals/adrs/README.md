# Architecture decision records

One file per architectural decision: what forced it, what was chosen, and what it costs. An ADR is a decision; the current design it produced is described in the [internals pages](../README.md).

ADRs are append-only. Once accepted, a record is never edited and never deleted — a decision that gets reversed earns a new ADR that supersedes it, and the old one's Status line is updated to point at the replacement. The log's value is that it is a log.

## Records

| # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-symlink-skills-instead-of-copying.md) | Symlink skills into `~/.claude/skills` instead of copying them | Accepted | 2026-07-07 |
| [0002](0002-split-init-and-update-into-two-skills.md) | Split documentation work into two skills rather than one | Accepted | 2026-07-07 |
| [0003](0003-diagrams-as-code-by-default.md) | Make diagrams-as-code the default, in every section | Accepted | 2026-07-23 |
| [0004](0004-wrap-diataxis-in-a-fixed-structure.md) | Wrap Diátaxis in a fixed structural strategy | Accepted | 2026-08-10 |

All four were reconstructed from the commits and rationale that already existed in the repo, so their dates are the dates of the decisions, not of the records.

## Adding one

Take the next unused number, zero-padded to four digits — numbers are never reused. Name the file `NNNN-<kebab-title>.md`, title it with the decision itself rather than the topic, and add a row above.

```markdown
# NNNN. Title stated as the decision

- **Status**: Proposed | Accepted | Superseded by [NNNN](NNNN-other.md)
- **Date**: YYYY-MM-DD

## Context
What forced a decision. Constraints, and what was true at the time.

## Decision
What was chosen, in the active voice.

## Consequences
What this makes easy, what it makes hard, and what it rules out.
```
