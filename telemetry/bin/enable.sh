#!/usr/bin/env bash
# Bring up the local telemetry stack and point Claude Code at it.
# Idempotent: safe to re-run, reports what was already in place.
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"

GRAFANA_PORT="$(envval GRAFANA_PORT 3000)"
OTLP_GRPC_PORT="$(envval OTLP_GRPC_PORT 4317)"
OTLP_HTTP_PORT="$(envval OTLP_HTTP_PORT 4318)"
PROMETHEUS_PORT="$(envval PROMETHEUS_PORT 9090)"
DISK_THRESHOLD="$(envval LOKI_WAL_DISK_THRESHOLD 0.95)"
INSTALL_WRAPPER="${INSTALL_SHELL_WRAPPER:-1}"

step "Preflight"
fail=0
for t in docker jq curl; do
  command -v "$t" >/dev/null 2>&1 || { err "$t is required but not on PATH"; fail=1; }
done
docker compose version >/dev/null 2>&1 || { err "the docker compose plugin is required"; fail=1; }
docker info >/dev/null 2>&1 || { err "cannot reach the Docker daemon — is it running?"; fail=1; }
[ "$fail" = 0 ] || exit 1
ok "docker, compose, jq, curl present"

# A port we already own is not a conflict.
running="$(dc ps --services --filter status=running 2>/dev/null | tr '\n' ' ' || true)"
for spec in "$GRAFANA_PORT:Grafana" "$OTLP_GRPC_PORT:OTLP gRPC" "$OTLP_HTTP_PORT:OTLP HTTP" "$PROMETHEUS_PORT:Prometheus"; do
  p="${spec%%:*}"; label="${spec#*:}"
  if port_busy "$p" && [ -z "$running" ]; then
    err "port $p ($label) is already in use by another process"
    dim "change it in telemetry/.env, then re-run"
    fail=1
  fi
done
[ "$fail" = 0 ] || exit 1
ok "ports $OTLP_GRPC_PORT, $OTLP_HTTP_PORT, $GRAFANA_PORT, $PROMETHEUS_PORT available"

# Loki refuses writes above its disk threshold, which would silently drop
# every event while metrics kept working. Catch it here, not in a dashboard.
pct="$(docker_disk_pct || echo 0)"
thresh_pct="$(awk -v t="$DISK_THRESHOLD" 'BEGIN{printf "%d", t*100}')"
if [ -n "$pct" ] && [ "$pct" -ge "$thresh_pct" ] 2>/dev/null; then
  warn "Docker's disk is ${pct}% full; Loki throttles writes at ${thresh_pct}%"
  dim "events will not be stored until you free space or raise"
  dim "LOKI_WAL_DISK_THRESHOLD in telemetry/.env (metrics are unaffected)"
elif [ -n "$pct" ]; then
  ok "disk ${pct}% used, below the ${thresh_pct}% write threshold"
fi

step "Starting containers"
[ -f "$TELEMETRY_DIR/.env" ] || { cp "$TELEMETRY_DIR/.env.example" "$TELEMETRY_DIR/.env"; ok "created telemetry/.env from the example"; }
dc up -d --quiet-pull 2>&1 | sed 's/^/    /' || { err "docker compose up failed"; exit 1; }
ok "5 containers up"

step "Waiting for readiness"
wait_http "Grafana"    "http://localhost:3000/api/health" 120 || exit 1
wait_http "Prometheus" "http://prometheus:9090/-/ready"   90  || exit 1
wait_http "Loki"       "http://loki:3100/ready"           120 || exit 1
wait_http "Tempo"      "http://tempo:3200/ready"          90  || exit 1
wait_http "Collector"  "http://otelcol:8888/metrics"      60  || exit 1

step "Pointing Claude Code at the collector"
mkdir -p "$(dirname "$SETTINGS")"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq -e . "$SETTINGS" >/dev/null 2>&1 || { err "$SETTINGS is not valid JSON — fix it and re-run"; exit 1; }

new_env="$(jq -n --arg ep "http://localhost:${OTLP_GRPC_PORT}" '{
  CLAUDE_CODE_ENABLE_TELEMETRY: "1",
  CLAUDE_CODE_ENHANCED_TELEMETRY_BETA: "1",
  OTEL_METRICS_EXPORTER: "otlp",
  OTEL_LOGS_EXPORTER: "otlp",
  OTEL_TRACES_EXPORTER: "otlp",
  OTEL_EXPORTER_OTLP_PROTOCOL: "grpc",
  OTEL_EXPORTER_OTLP_ENDPOINT: $ep,
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE: "delta",
  OTEL_METRICS_INCLUDE_SESSION_ID: "false",
  OTEL_METRIC_EXPORT_INTERVAL: "10000",
  OTEL_LOGS_EXPORT_INTERVAL: "5000",
  OTEL_LOG_USER_PROMPTS: "1",
  OTEL_LOG_TOOL_DETAILS: "1"
}')"

merged="$(jq --argjson add "$new_env" '.env = ((.env // {}) + $add)' "$SETTINGS")"
if [ "$merged" = "$(cat "$SETTINGS")" ]; then
  ok "settings.json already configured"
else
  backup="$SETTINGS.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$SETTINGS" "$backup"
  printf '%s\n' "$merged" > "$SETTINGS"
  ok "merged the telemetry env block into $SETTINGS"
  dim "previous file saved as $(basename "$backup")"
fi

if [ "$INSTALL_WRAPPER" = "1" ]; then
  step "Per-project tagging"
  if [ -f "$ZSHRC" ] && grep -qF "$WRAPPER_BEGIN" "$ZSHRC"; then
    ok "shell wrapper already installed in $(basename "$ZSHRC")"
  elif [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d-%H%M%S)"
    { printf '\n%s\n' "$WRAPPER_BEGIN"; cat "$TELEMETRY_DIR/shell/claude-project-tag.zsh"; printf '%s\n' "$WRAPPER_END"; } >> "$ZSHRC"
    ok "added the project-tagging wrapper to $(basename "$ZSHRC")"
    dim "tags each session with its git repo name; run 'exec zsh' to load it"
  else
    warn "no $ZSHRC found — skipping the wrapper"
    dim "source telemetry/shell/claude-project-tag.zsh from your shell rc by hand"
  fi
fi

step "Done"
ok "Grafana: http://localhost:${GRAFANA_PORT}  (folder: Claude Code)"
printf '\n  %sTelemetry is read at startup, so already-running Claude sessions%s\n' "$C_WARN" "$C_OFF"
printf '  %sare not sending anything. Restart them to begin collecting.%s\n\n' "$C_WARN" "$C_OFF"
