# Telemetry configuration

Everything the local telemetry stack reads and writes. To turn it on, see
[Collect telemetry from your Claude Code sessions](../usage/telemetry.md); for
why it is built this way, see [The telemetry pipeline](../internals/telemetry-pipeline.md).

## Settings written to `~/.claude/settings.json`

`make enable-telemetry` merges these into the `env` block, leaving every other
key in the file untouched. `make disable-telemetry` removes exactly these keys
and no others.

| Key | Value | Effect |
|---|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | Master switch. Nothing is exported without it. |
| `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA` | `1` | Enables the beta trace spans that Tempo stores. |
| `OTEL_METRICS_EXPORTER` | `otlp` | Counters to the collector. |
| `OTEL_LOGS_EXPORTER` | `otlp` | Events to the collector. |
| `OTEL_TRACES_EXPORTER` | `otlp` | Spans to the collector. |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `grpc` | Transport for all three signals. |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4317` | Follows `OTLP_GRPC_PORT`. |
| `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` | `delta` | Required by the collector's delta-to-cumulative step. |
| `OTEL_METRICS_INCLUDE_SESSION_ID` | `false` | Keeps one Prometheus series per label set instead of one per session. |
| `OTEL_METRIC_EXPORT_INTERVAL` | `10000` | Metric flush, in milliseconds. |
| `OTEL_LOGS_EXPORT_INTERVAL` | `5000` | Event flush, in milliseconds. |
| `OTEL_LOG_USER_PROMPTS` | `1` | Stores prompt text in Loki. |
| `OTEL_LOG_TOOL_DETAILS` | `1` | Stores tool names, parameters and error messages. |

Three further content switches are deliberately left off, because each one
multiplies stored volume: `OTEL_LOG_ASSISTANT_RESPONSES`, `OTEL_LOG_TOOL_CONTENT`
(full file contents read and written) and `OTEL_LOG_RAW_API_BODIES`. Add them to
the same `env` block by hand if you want them; `make disable-telemetry` will
leave them in place.

Everything captured stays in the local Loki volume, prompt and tool text
included. Anything a session reads — credentials in a file, secrets in a
command — can land there, so treat the volume like shell history.

## `telemetry/.env`

Copied from `.env.example` on first run, and git-ignored. Change a value and
re-run `make enable-telemetry`.

| Variable | Default | Meaning |
|---|---|---|
| `OTLP_GRPC_PORT` | `4317` | Where Claude Code pushes telemetry. The settings endpoint follows it. |
| `OTLP_HTTP_PORT` | `4318` | OTLP over HTTP, for anything preferring `http/protobuf`. |
| `GRAFANA_PORT` | `3000` | Dashboard UI. |
| `PROMETHEUS_PORT` | `9090` | Exposed for querying metrics directly. |
| `PROMETHEUS_RETENTION` | `90d` | Age cap on metrics. |
| `PROMETHEUS_RETENTION_SIZE` | `4GB` | Size cap on metrics, whichever hits first. |
| `LOKI_WAL_DISK_THRESHOLD` | `0.95` | Fraction of the disk at which Loki stops accepting events. `0` disables the guard. |

Every port binds to `127.0.0.1` only. Loki's retention is set separately in
`telemetry/loki/loki.yaml` (`limits_config.retention_period`, default `2160h`
= 90 days, matching Prometheus).

## Containers and versions

| Service | Image | Role |
|---|---|---|
| `otelcol` | `otel/opentelemetry-collector-contrib:0.159.0` | Receives OTLP, fans out to the three stores |
| `prometheus` | `prom/prometheus:v3.14.0` | Metrics |
| `loki` | `grafana/loki:3.7.6` | Events |
| `tempo` | `grafana/tempo:3.0.0` | Traces |
| `grafana` | `grafana/grafana:13.2.0` | Dashboards, anonymous admin on loopback |

Data lives in four named Docker volumes prefixed `docschemy-telemetry_`.
`make disable-telemetry` keeps them; `make purge-telemetry` deletes them.

## Dashboards

Provisioned from `telemetry/grafana/dashboards/` into the **Claude Code**
folder, and re-read every 30 seconds — edit the JSON and the change appears
without a restart. Edits made in the Grafana UI are allowed but are overwritten
by the files on the next reload.

| Dashboard | UID | Source of its numbers |
|---|---|---|
| Claude Code — Overview | `claude-code-overview` | Loki for spend, tokens and requests; Prometheus for session, commit, PR and line counts |
| Claude Code — Deep Dive | `claude-code-deep-dive` | Loki for latency, tools, permissions and errors; Tempo for traces |

## The tagging shim

`telemetry/shell/claude-shim` is a `sh` script that sets
`OTEL_RESOURCE_ATTRIBUTES=project=<repo>` from the current git root and then
`exec`s the real binary, which it finds by rescanning `PATH` with its own
directory skipped. `CLAUDE_REAL_BIN` overrides that search. A `project=` the
caller already set is left alone, so a per-session override still wins; an
`OTEL_RESOURCE_ATTRIBUTES` set by the launcher is appended to, not replaced.

`make enable-telemetry` installs it in three places; `make disable-telemetry`
removes all three.

| What | Path | Covers |
|---|---|---|
| The shim | `~/.claude/shims/claude` → this repo | — |
| `PATH` for terminals | a marked block in `~/.zshrc` | sessions started from a shell |
| `PATH` for everything else | `~/.config/environment.d/10-docschemy-claude-telemetry.conf` | IDE extensions, systemd user units |

The shim is symlinked rather than copied, so editing it here takes effect on the
next launch. The `environment.d` file is read at login, so graphical sessions
pick it up only after a re-login.

All three are the same mechanism — get the shim onto `PATH` ahead of the real
binary — which is why the desktop app is not among them. It `exec`s a Claude
Code build it downloads itself, at
`~/.config/Claude/claude-code/<version>/claude`, and never resolves the name
through `PATH`, so its sessions arrive with no project label. See
[ADR 0011](../internals/adrs/0011-leave-desktop-app-sessions-untagged.md) for
why nothing is installed there.

It sets a different key from anything in `settings.json`, so the two never
compete: shared transport settings come from the settings file, per-session
identity from the environment.

## Querying without Grafana

Prometheus is on `http://localhost:9090`. Loki and Tempo are not published;
reach them through Grafana's datasource proxy, which is what
`make telemetry-status` does:

```sh
curl -sG http://localhost:3000/api/datasources/proxy/uid/claude-loki/loki/api/v1/query \
  --data-urlencode 'query=sum(sum_over_time({service_name=~"claude-code.*"} | event_name="api_request" | unwrap cost_usd [24h]))'
```

Events carry `project` and `service_name` as stream labels; every other field
(`model`, `cost_usd`, `duration_ms`, `tool_name`, `trace_id`, …) is structured
metadata, filtered with `| key="value"` and summed with `| unwrap key`.

`service_name` depends on the launcher: sessions started from a shell or an IDE
report as `claude-code`, and the desktop app spawns its CLI with
`OTEL_SERVICE_NAME=claude-code-desktop`. Match both with
`service_name=~"claude-code.*"`, which is what the dashboards and
`make telemetry-status` do; `terminal_type` still tells the two apart.
