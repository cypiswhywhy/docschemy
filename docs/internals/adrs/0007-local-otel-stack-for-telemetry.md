# 0007. Collect Claude Code telemetry through a local OpenTelemetry stack

- **Status**: Accepted
- **Date**: 2026-08-19

## Context

Claude Code sessions across many projects needed monitoring — spend, latency,
tool failures — under a hard constraint that no session data leave the machine.
Prompts and tool parameters are among the most sensitive things a development
machine handles, so "local" had to mean local, not "a vendor with a good privacy
policy". Running a container locally was acceptable.

Three options were available:

- **A hosted observability backend.** Claude Code exports OTLP, so any of them
  works with a token and an endpoint. Ruled out by the constraint.
- **Reading the local session transcripts.** Claude Code writes one JSONL file
  per session under `~/.claude/projects/`, and tools like `ccusage` parse them.
  Local by construction, zero infrastructure, and it can read history recorded
  before any decision was made. But transcripts carry tokens and cost only —
  no tool results, permission decisions, MCP connection failures, API errors or
  request latency.
- **A local OpenTelemetry stack.** Claude Code's OTLP export covers metrics,
  events and beta traces, which is strictly more signal than the transcripts
  hold, at the cost of running containers.

## Decision

Run an OpenTelemetry collector locally with Prometheus, Loki, Tempo and Grafana
behind it, all bound to `127.0.0.1`, and configure Claude Code through an `env`
block in `~/.claude/settings.json`.

Configuring it through the user-scope settings file, rather than per project, is
what makes one command cover every project on the machine — present and future.
Per-project identity comes from a shell wrapper that sets
`OTEL_RESOURCE_ATTRIBUTES` from the git root, which touches a different key and
so never competes with the settings file.

## Consequences

Every signal Claude Code emits is available, including the ones that only exist
as events, and the data is queryable with standard tools rather than a bespoke
parser.

The costs are real. Five containers must be running for collection to happen at
all, which is five more things that can break than a transcript parser has. The
stack only sees sessions started after it was enabled — unlike transcript
parsing, there is no history to backfill from, and the transcripts on disk
cannot be replayed into it. And telemetry configuration is read once at process
start, so enabling, disabling or repointing it never affects a running session.

Adopting OTLP also means the same configuration would point at a hosted backend
by changing one endpoint, should the constraint ever be lifted.
