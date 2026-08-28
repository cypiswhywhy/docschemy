# 0008. Read spend from events, not from Prometheus counters

- **Status**: Accepted
- **Date**: 2026-08-19

## Context

Claude Code reports cost twice: as a `claude_code.cost.usage` counter and as a
`cost_usd` field on every `api_request` event. Both were being collected, so the
dashboards had to pick one, and the obvious choice was the counter — cost is a
metric, metrics go in Prometheus, and Prometheus retains cheaply.

Measurement showed the counter cannot answer the question accurately. A session
that cost exactly `$0.082561` was reported by `sum(increase(...))` over the
enclosing window as `$0.108`, a 31% overstatement. The cause is inherent rather
than a misconfiguration: `increase()` extrapolates to the boundaries of its
window, which is sound for a continuous stream and wrong for a workload that is
idle most of the time and bursty in between. Nearly every window edge for Claude
Code falls inside a gap between sessions.

Prometheus offers no exact alternative. `xincrease()` belongs to other
implementations, and differencing raw counters breaks across the resets that
short-lived session processes and collector restarts produce constantly.

Events have no such problem. Each `api_request` record is an immutable statement
that one call cost one amount; summing them is arithmetic, not estimation.

## Decision

Spend, token totals and request counts on the Overview dashboard are summed from
`api_request` events in Loki. Metrics remain the source only for the signals
that have no event equivalent — sessions, active time, lines of code, commits,
pull requests and edit-tool decisions — and every panel reading them is labelled
`≈` to say so on the dashboard itself.

## Consequences

The money figure is exact and reconciles with any other per-request accounting,
which is the property that matters for a number someone might act on. Grouping
by model, project or query source stays exact, because it is the same sum
partitioned.

In exchange, cost history is bounded by Loki's retention rather than
Prometheus's, so both are set to 90 days and must be changed together to keep
the Overview dashboard coherent across its full range. Two stores must be
healthy for the dashboard to be complete, and a reader comparing an exact panel
against an `≈` one will find they disagree — which is why the marking is on the
panels and not only in the docs.

Keeping the metrics pipeline despite not trusting it for money is deliberate:
several signals exist nowhere else, and counts are a use where extrapolation
error is tolerable.
