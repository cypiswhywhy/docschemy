# Makefile targets

There is no build, lint, or test step. `install` publishes the skills; the
`telemetry` targets manage the local monitoring stack and are independent of it.

| Target | Effect |
|---|---|
| `install` | Symlinks each `skills/<name>/` into `$HOME/.claude/skills/<name>`. Idempotent, and never clobbers a path it didn't create — see [Install the skills](../usage/install.md#what-happens-per-skill) for the three outcomes per skill. |
| `enable-telemetry` | Starts the local telemetry stack and merges its settings into `~/.claude/settings.json`. Idempotent; preflights tools, ports and disk before touching anything. |
| `disable-telemetry` | Stops the stack and removes the settings, the tagging shim and the `PATH` entries it added. Keeps collected data. |
| `purge-telemetry` | The same, and deletes the data volumes. |
| `telemetry-status` | Reports whether telemetry is being collected — endpoints, receipts, events stored and disk headroom — not just whether containers run. |

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_SKILLS_DIR` | `$(HOME)/.claude/skills` | Where symlinks are created. Created with `mkdir -p` if missing. |
| `REPO_SKILLS_DIR` | `$(CURDIR)/skills` | Where skills are read from. Resolves to an absolute path, so the symlinks it creates stay valid from any working directory. |
| `TELEMETRY_BIN` | `$(CURDIR)/telemetry/bin` | Where the telemetry targets find their scripts. |

All three are plain `make` variables and can be overridden on the command line, e.g. `make install CLAUDE_SKILLS_DIR=/tmp/skills`.

The telemetry stack takes its own settings from `telemetry/.env` rather than from `make` — see [Telemetry configuration](telemetry-configuration.md).
