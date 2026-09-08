# 0009. Derive the project label with a PATH shim, not a shell function

- **Status**: Accepted
- **Date**: 2026-09-08

## Context

[ADR 0007](0007-local-otel-stack-for-telemetry.md) settled that per-project
identity comes from `OTEL_RESOURCE_ATTRIBUTES`, derived from the git root rather
than configured per project. The mechanism it shipped with was a `claude` shell
function appended to `~/.zshrc`.

A shell function only exists inside an interactive shell that read that file.
Every other way a session starts — the desktop app, an IDE extension, a
scheduled job, a non-zsh shell — bypasses it and arrives with no project label.
Those sessions are not visibly broken: they record everything else and quietly
group under an empty label, so the gap shows up as a dashboard that under-counts
rather than as an error.

Three mechanisms could close it:

- **Keep the function, add one per shell.** Cheap, but it still cannot reach
  anything that is not a shell, which is the actual gap.
- **Replace `~/.local/bin/claude`.** Reaches everything, and the Claude Code
  installer overwrites it on the next upgrade.
- **A shim earlier on `PATH`.** Reaches every `exec` that resolves `claude`
  through `PATH`, and leaves the installed binary alone.

## Decision

Install `telemetry/shell/claude-shim` as `~/.claude/shims/claude` and put that
directory ahead of the real binary on `PATH` — through `~/.zshrc` for terminals,
and through `~/.config/environment.d/` for the graphical session that the
desktop app and IDE extensions inherit from.

The shim finds the real binary by rescanning `PATH` with its own directory
skipped, so it does not need to know where Claude Code is installed and survives
version upgrades. A `project=` the caller already set is passed through
untouched, which keeps the documented per-session override working.

## Consequences

Every launch that resolves `claude` through `PATH` is tagged, including the ones
no shell rc can reach. `make telemetry-status` reports the events that still
arrive untagged, so the remaining gap is visible rather than inferred.

The costs are the two install points. `environment.d` is read at login, so the
desktop app keeps the old `PATH` until the user logs out — the one step of this
stack that a re-run of `make enable-telemetry` cannot complete for them. A shim
on `PATH` is also a more invasive thing to leave behind than a line in an rc
file, so `make disable-telemetry` removes the link, the rc block and the
`environment.d` file, and refuses to delete a `~/.claude/shims/claude` it did
not create.

This supersedes the mechanism described in ADR 0007, not its decision: the
project label still comes from the git root, through the same environment
variable, and still never competes with `settings.json`.
