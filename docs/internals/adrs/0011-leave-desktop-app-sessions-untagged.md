# 0011. Leave desktop app sessions untagged rather than replace a file the app manages

- **Status**: Accepted
- **Date**: 2026-09-08

## Context

[ADR 0010](0010-shim-the-desktop-apps-bundled-cli.md) chose to tag desktop app
sessions by installing a wrapper at
`~/.config/Claude/claude-code/<version>/claude`, moving the real binary aside to
`claude.real`. It was built and verified end to end: a desktop-launched session
reported `project=docschemy` alongside `service_name=claude-code-desktop`.

What it did not settle is whether the project label is worth the price of the
install. That price is not a technical risk that better engineering removes — the
binary is moved intact and restored on disable — it is that the stack writes into
a directory another application owns, installs into, and updates.

The alternatives were re-examined and none avoids it:

- **A wrapper in `~/bin/claude`, or any other `PATH` entry.** The desktop app
  never resolves `claude` through `PATH`; it `exec`s an absolute path. A wrapper
  there is shadowed by the existing `~/.claude/shims/claude` and reaches nothing
  new.
- **A project-level `.claude/settings.json` `env` block.** Loses to the
  `OTEL_RESOURCE_ATTRIBUTES` the app injects at spawn, tested both ways.
- **Deriving the label in the collector.** No event type carries a working
  directory, a workspace, or a session id to join a hook against.
- **A single static `project=desktop` for every desktop session**, through the
  `environment.d` entry the app's spawn code merges rather than discards.
  Non-invasive, but it answers "which repo did this spend come from?" with
  "a desktop one", which is not the question the label exists to answer.

## Decision

Do not install anything into the desktop app's directory. Desktop sessions are
collected in full and group under an empty project label.

Keep the service-name half of ADR 0010, which is unaffected: everything that
reads events matches `service_name=~"claude-code.*"`, so desktop sessions appear
on every dashboard and in `make telemetry-status` — they are unattributed, not
invisible, and the distinction is the whole point.

`make telemetry-status` still reports how many events arrived untagged, and now
says why that count is permanently non-zero for anyone using the app, so the
number reads as a known limit rather than a fault to chase.

## Consequences

Spend-by-project understates every repository by whatever share of the work
happens in the desktop app, and the Project dropdown cannot filter it. On a
machine where most sessions are desktop sessions, that is most of the spend —
the honest reading of those panels is "spend by project, among sessions started
from a terminal or an IDE".

In exchange, nothing this repo installs can be broken by an app update, and
nothing it installs can break an app update. The `PATH` shim from ADR 0009
remains the whole mechanism, with the property that made it worth choosing:
it never touches a file Claude Code owns.

If the app later exposes a supported way to set resource attributes per session,
or emits an event carrying the working directory, this becomes a decision worth
revisiting — both would make the label available without the install.
