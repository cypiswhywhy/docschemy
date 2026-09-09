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

For terminals and IDEs there is nothing to configure per project.
`make enable-telemetry` installs a small `claude` shim that reads the git
repository name of wherever you started and tags the session with it. That is what fills the **Project** dropdown and the
spend-by-project panel.

How a session reaches the shim depends on how it was launched:

- **Terminals** — the shim goes ahead of the real binary on `PATH`, through
  `~/.zshrc`. Run `exec zsh` once to pick it up.
- **IDE extensions, scheduled jobs** — the same `PATH` entry, through
  `~/.config/environment.d/`, which is read at login. Log out and back in once.
- **The desktop app** — the shim cannot reach it. It runs a copy of Claude Code
  it downloads itself, by absolute path, never consulting `PATH`. You set the
  label yourself, per session, in the app — see
  [Tag a desktop app session](#tag-a-desktop-app-session) below.

Until the `PATH` entries are picked up, terminal and IDE launches behave like an
untagged desktop session — everything is recorded, grouped as `untagged`.
`make telemetry-status` reports how many events in the last 24 hours arrived
untagged.

To override the name for one session — a worktree that should report as its
parent repo, say — set it yourself and the shim leaves it alone:

```sh
OTEL_RESOURCE_ATTRIBUTES=project=my-repo claude
```

### Tag a desktop app session

Before starting a session in the desktop app, open its **Environment variables**
and add one line, with the repository name you want it filed under:

```
OTEL_RESOURCE_ATTRIBUTES=project=my-repo
```

The app merges that into the attributes it sets on the session, and the session
then appears in the **Project** dropdown and in spend-by-project like any
terminal session of the same repository. Sessions started without it group under
`untagged`. In the current app version the variable is set per session, not per
folder. <!-- TODO: verify whether a later app version exposes per-folder environment variables -->
[How desktop app sessions get a project label](../internals/telemetry-desktop-sessions.md)
explains why the shim cannot do this for you.

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
