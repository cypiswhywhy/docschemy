# The telemetry pipeline

How a Claude Code session's telemetry reaches a dashboard, and why the stack has
the shape it does. To turn it on, see
[Collect telemetry from your Claude Code sessions](../usage/telemetry.md); for
the knobs, see [Telemetry configuration](../reference/telemetry-configuration.md).

## Shape

Claude Code speaks OpenTelemetry natively — it needs no plugin, only environment
variables, which is why a single `env` block in `~/.claude/settings.json`
configures every project on the machine at once.

```mermaid
flowchart LR
    CC["Claude Code<br/>any project"] -->|"OTLP/gRPC :4317"| OC["otelcol"]
    OC -->|"delta → cumulative,<br/>scraped :8889"| PR["Prometheus<br/>counters"]
    OC -->|"OTLP/HTTP"| LO["Loki<br/>events"]
    OC -->|"OTLP/gRPC"| TE["Tempo<br/>spans"]
    PR --> GR["Grafana"]
    LO --> GR
    TE --> GR
```

The collector exists because the three signals want three different transports
and Prometheus pulls where Claude Code pushes. It also does the two
transformations the stores need: converting delta counters to cumulative ones,
and promoting resource attributes — notably `project` — to labels that can be
queried.

## Two stores, two kinds of answer

The same session produces both a `claude_code.cost.usage` counter and one
`api_request` event per model call, each carrying `cost_usd`. They do not give
the same answer, and the difference is not small.

Prometheus counters are read with `increase()`, which extrapolates to the edges
of its window. For a steady stream that is accurate enough; for Claude Code it
is not, because sessions are short and sporadic, so almost every window edge
falls inside a gap. Measured against a session that cost exactly `$0.082561`,
`increase()` over the enclosing window reported `$0.108` — a 31% overstatement.

So the split is:

- **Spend, tokens and request counts come from events.** Summing `cost_usd`
  across `api_request` records is exact arithmetic over immutable per-request
  facts, with no rate estimation involved.
- **Sessions, active time, lines of code, commits, pull requests and edit
  decisions come from metrics**, because Claude Code emits no event equivalent
  for them. These are the panels marked `≈`, and the marking is literal.

[ADR 0008](adrs/0008-read-spend-from-events-not-counters.md) records the
decision and what it costs.

Two collector settings follow from the same short-session shape. The Prometheus
exporter expires a series it has not seen for `metric_expiration` — five minutes
by default, which is shorter than the gap between sessions, so series would
vanish and reappear; it is set to 24 hours. And `deltatocumulative` is what lets
a counter survive the process that produced it, since Claude Code exports delta
temporality and the emitting process exits when the session ends.

## Events carry more than metrics

Events are the richer signal in practice. Each `api_request` record carries the
model, cost, duration, all four token counts, the query source, and a `trace_id`
linking it to the span tree in Tempo. Tool calls, permission decisions, MCP
connection failures and API errors exist only as events. This is why the Deep
Dive dashboard is almost entirely Loki.

Only `service_name` and `project` are stream labels; everything else is
structured metadata. That keeps the number of streams tiny — one per project —
while leaving every field filterable.

## One CLI, three launchers

The same Claude Code binary is started in ways that differ enough to change what
reaches the pipeline. Two of them resolve `claude` through `PATH`, so a shim
placed earlier on `PATH` catches them ([ADR 0009](adrs/0009-tag-projects-with-a-path-shim.md)).
The desktop app does not: it `exec`s a build it downloads and version-pins
itself, by absolute path, and injects its own OTel environment at spawn.

```mermaid
flowchart LR
    T["terminal"] -->|"PATH, via ~/.zshrc"| S
    I["IDE extension,<br/>systemd user unit"] -->|"PATH, via environment.d"| S
    D["desktop app"] -->|"absolute path to its<br/>own pinned CLI build"| W["generated wrapper in the<br/>version directory"]
    W --> S["claude-shim<br/>appends project=&lt;git root&gt;"]
    S --> CC["claude"]
    CC -->|"service_name=claude-code<br/>or claude-code-desktop"| OC["otelcol"]
```

That injection has two consequences the rest of the stack has to absorb.

The first is the name. The app sets `OTEL_SERVICE_NAME=claude-code-desktop`, so
its sessions do not answer to `service_name="claude-code"` — a query pinned to
that string silently returns nothing for them, however much they produced.
Everything that reads events matches `service_name=~"claude-code.*"` instead,
which keeps the two launchers distinguishable rather than flattening them.

The second is that the project label had nowhere else to come from. The app also
injects `OTEL_RESOURCE_ATTRIBUTES`, and Claude Code does not let a `settings.json`
`env` entry override a variable the process already has, so per-project settings
cannot supply it. Deriving it in the collector needs a path on the events, and no
event type carries a working directory, a workspace or a session id to join on.
What does hold is that the app spawns its CLI with the session's project as the
working directory — the same thing the `PATH` shim reads — so a wrapper at that
path derives the same name. [ADR 0010](adrs/0010-shim-the-desktop-apps-bundled-cli.md)
records the choice and what it costs.

## Failure modes worth knowing

**Loki stops accepting writes when its disk fills.** The guard trips at
`LOKI_WAL_DISK_THRESHOLD`, and when it does, metrics keep working while events
silently stop — the worst possible failure, since dashboards still render.
`make enable-telemetry` checks the disk before starting and
`make telemetry-status` reports it afterwards.

That check computes disk use as `used / total`, the way Loki does, rather than
reading `df`'s `Use%` column, which divides by `used + available` and so excludes
the root-reserved blocks. On a large filesystem the two differ by several
points — enough to raise an alarm about a threshold that is not actually close.

**Configuration changes need the right restart.** Files mounted into a container
are not part of the Compose config hash, so editing `otelcol/config.yaml` or
`loki/loki.yaml` needs an explicit `docker compose restart <service>`; `up -d`
alone will report the container as already up to date.

**A desktop app CLI update silently drops project tagging.** The app installs
each update into a new version directory, which arrives without the wrapper.
Sessions keep recording; they just group under an empty project label again.
Nothing in the install can prevent that, so `make telemetry-status` inspects
every version directory it finds and names any that is unshimmed.

**Running sessions never pick telemetry up.** It is read once at startup. Every
enable and disable path says so, because it is the one part of the flow no
script can fix.

## Why local, and why this stack

The requirement was that no session data leave the machine, which rules out the
hosted backends and leaves a container stack. Reading the local session
transcripts instead — as `ccusage` and similar tools do — stays local too, but
sees only tokens and cost: no tool results, permission decisions, MCP failures,
API errors or latency. [ADR 0007](adrs/0007-local-otel-stack-for-telemetry.md)
records that choice.
