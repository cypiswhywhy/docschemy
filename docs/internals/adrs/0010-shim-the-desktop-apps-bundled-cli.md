# 0010. Shim the desktop app's own CLI, and match both service names

- **Status**: Superseded by [0011](0011-leave-desktop-app-sessions-untagged.md)
- **Date**: 2026-09-08

## Context

[ADR 0009](0009-tag-projects-with-a-path-shim.md) put the tagging shim ahead of
the real binary on `PATH`, through `~/.zshrc` for terminals and
`~/.config/environment.d/` for the graphical session, on the assumption that the
second entry covered the desktop app. It does not. The desktop app never
resolves `claude` through `PATH`: it `exec`s a Claude Code build it downloads and
version-pins itself, at `~/.config/Claude/claude-code/<version>/claude`, and
injects its own OTel environment at spawn.

Two things followed from that, both of which hid rather than announced
themselves.

The app sets `OTEL_SERVICE_NAME=claude-code-desktop`, so its sessions never
matched the `service_name="claude-code"` stream selector every dashboard panel
and status query was pinned to. In a measured 24-hour window that was 4256
events against 8 from terminal sessions — the Deep Dive dashboard read "No Data"
over any recent range while the Overview's Prometheus panels, which carry no
service filter, looked healthy.

And because the app also injects `OTEL_RESOURCE_ATTRIBUTES`, its sessions had no
project label. Three ways to supply one were tried:

- **A project-level `.claude/settings.json` `env` block.** Verified working when
  the variable is unset, and verified losing when it is: an inherited value wins,
  and the app always sets one.
- **Deriving it in the collector.** Needs a path on the events. No event type
  emits a working directory, a workspace, or a session id that a hook could be
  joined on.
- **A wrapper at the path the app actually `exec`s.** The app spawns its CLI with
  the session's project as the working directory — the same input the `PATH` shim
  reads — so the existing shim works there unchanged.

## Decision

Match both service names with `service_name=~"claude-code.*"` everywhere events
are read — both dashboards and `make telemetry-status` — rather than forcing the
desktop app to report as `claude-code`. It applies to the events already stored,
and `terminal_type` still separates the launchers when that distinction matters.

Install a wrapper at `~/.config/Claude/claude-code/<version>/claude`, moving the
real binary aside to `claude.real` in the same directory. The wrapper is a
generated copy, not a symlink to `telemetry/shell/claude-shim`: an app update
writing its new binary to that path would follow a symlink and overwrite the
shim in this repo, breaking tagging for every launcher at once — which happened
once while testing this. It names `claude.real` through `CLAUDE_REAL_BIN`,
because a `PATH` scan from there would find the terminal's separately-updated
Claude Code, generally a different version than the app expects to speak to.

## Consequences

Desktop sessions now carry the same `project` label as terminal ones, from the
same git root, through the same shim.

The cost is that the install is version-pinned to a directory the app owns. A
CLI update lands in a new directory without the wrapper and tagging stops with
no error anywhere — the same silent-undercount failure ADR 0009 set out to fix,
returning through a different door. Nothing in the install can prevent it, so
`make telemetry-status` reports the state of every version directory it finds:
shimmed, unshimmed (a warning naming the version, pointing at
`make enable-telemetry`), or a wrapper whose `claude.real` is missing, which is
an error because that directory would fail to launch at all.

Replacing a file the app manages is also unsupported by that app, and
`make disable-telemetry` has to put the binaries back. Both are accepted
knowingly: the alternative is desktop sessions that cost real money and cannot
be attributed to anything.

This does not supersede ADR 0009. The `PATH` shim remains the mechanism for
every launcher that resolves `claude` through `PATH`; this adds the one that
does not, and corrects that record's claim that `environment.d` covered the
desktop app.
