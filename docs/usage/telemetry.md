# Collect telemetry from your Claude Code sessions

`make enable-telemetry` brings up a local observability stack and points every
Claude Code session on the machine at it — across all your projects, not just
this one. Nothing leaves the machine: the collector, the three stores and the
dashboards all run in Docker on `127.0.0.1`.

## Before you start

- Docker with the Compose plugin, plus `jq` and `curl`.
- Roughly 1 GB of free disk to start with, and headroom afterwards — Loki stops
  accepting events when its disk crosses a threshold. The command checks this
  and warns you.
- Ports `4317`, `4318`, `3000` and `9090` free, or changed in `telemetry/.env`.

## Turn it on

```sh
make enable-telemetry
```

The command is idempotent — re-running it re-checks everything and reports what
was already in place.

```mermaid
flowchart TD
    A["make enable-telemetry"] --> B["preflight<br/>tools, ports, disk headroom"]
    B --> C["docker compose up"]
    C --> D["wait until all five<br/>containers answer as ready"]
    D --> E["merge the OTLP env block<br/>into ~/.claude/settings.json"]
    E --> F["install the tagging shim<br/>for every launcher"]
    F --> G(["Grafana on :3000"])
```

Both files it edits are backed up first, with a timestamp in the name.

**Sessions already running keep sending nothing.** Claude Code reads its
telemetry configuration once at startup, so restart any open session before
expecting data. New sessions are collected automatically.

## Look at the data

Open <http://localhost:3000> — no login — and pick the **Claude Code** folder.
It holds two dashboards: **Overview** for spend, and **Deep Dive** for latency,
tools and failures.

[Read the telemetry dashboards](telemetry-dashboards.md) walks through every
panel on both, with screenshots.

## Per-project breakdowns

Nothing to configure per project. `make enable-telemetry` installs a small
`claude` shim that reads the git repository name of wherever you started and
tags the session with it. That is what fills the **Project** dropdown and the
spend-by-project panel.

How a session reaches the shim depends on how it was launched:

- **Terminals** — the shim goes ahead of the real binary on `PATH`, through
  `~/.zshrc`. Run `exec zsh` once to pick it up.
- **IDE extensions, scheduled jobs** — the same `PATH` entry, through
  `~/.config/environment.d/`, which is read at login. Log out and back in once.
- **The desktop app** — it never consults `PATH`, so neither entry reaches it.
  It runs a copy of Claude Code it downloads itself, and the installer puts a
  wrapper at that path directly. Nothing for you to do at install time.

**Re-run `make enable-telemetry` after the desktop app updates Claude Code.**
Each update installs into a new directory, which arrives without the wrapper,
and tagging stops with no error anywhere. `make telemetry-status` is what
surfaces it:

```
  ! desktop CLI 2.1.263 not shimmed — those sessions carry no project label
    the app installed a CLI update; 'make enable-telemetry' re-applies the shim
```

Until every launcher you use is covered, the ones that are not still record
everything else; they just group under an empty project label.
`make telemetry-status` reports how many events in the last 24 hours arrived
untagged.

To override the name for one session — a worktree that should report as its
parent repo, say — set it yourself and the shim leaves it alone:

```sh
OTEL_RESOURCE_ATTRIBUTES=project=my-repo claude
```

## Check it is working

```sh
make telemetry-status
```

This goes past "are the containers up" — it reports whether the collector has
received anything, how many events were stored in the last 24 hours, what they
cost, and whether the disk is close to the threshold at which events start
being dropped.

## Turn it off

```sh
make disable-telemetry   # stops the stack, keeps the data
make purge-telemetry     # stops the stack, deletes the data
```

Both remove the settings block, the tagging shim and the `PATH` entries the
installer added, leaving any OTel settings you added yourself alone. After
`make disable-telemetry`, running `make enable-telemetry` again picks up where
you left off.

## Related

- [Telemetry configuration](../reference/telemetry-configuration.md) — every knob, port and settings key
- [The telemetry pipeline](../internals/telemetry-pipeline.md) — how the pieces fit and why
