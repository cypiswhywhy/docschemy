#!/usr/bin/env bash
# Answer "is it actually collecting?" -- not just "are containers up?".
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
set +e

GRAFANA_PORT="$(envval GRAFANA_PORT 3000)"
DISK_THRESHOLD="$(envval LOKI_WAL_DISK_THRESHOLD 0.95)"

step "Containers"
if ! docker info >/dev/null 2>&1; then
  err "Docker daemon unreachable"; exit 1
fi
out="$(dc ps --format '{{.Service}}\t{{.Status}}' 2>/dev/null)"
if [ -z "$out" ]; then
  warn "stack is not running — 'make enable-telemetry' to start it"; exit 0
fi
printf '%s\n' "$out" | while IFS=$'\t' read -r svc st; do
  case "$st" in Up*) ok "$(printf '%-11s %s' "$svc" "$st")" ;; *) err "$(printf '%-11s %s' "$svc" "$st")" ;; esac
done

step "Endpoints"
for spec in "Grafana|http://localhost:3000/api/health" "Prometheus|http://prometheus:9090/-/ready" \
            "Loki|http://loki:3100/ready" "Tempo|http://tempo:3200/ready" "Collector|http://otelcol:8888/metrics"; do
  name="${spec%%|*}"; url="${spec#*|}"
  code="$(dc exec -T grafana curl -s -o /dev/null -w '%{http_code}' --max-time 4 "$url" 2>/dev/null)"
  [ "$code" = "200" ] && ok "$(printf '%-11s %s' "$name" "ready")" || err "$(printf '%-11s HTTP %s' "$name" "${code:-unreachable}")"
done

step "Claude Code wiring"
if [ -f "$SETTINGS" ] && jq -e '.env.CLAUDE_CODE_ENABLE_TELEMETRY == "1"' "$SETTINGS" >/dev/null 2>&1; then
  ok "telemetry enabled in $(basename "$SETTINGS")"
  dim "endpoint $(jq -r '.env.OTEL_EXPORTER_OTLP_ENDPOINT // "unset"' "$SETTINGS")"
else
  warn "not enabled in $SETTINGS — run 'make enable-telemetry'"
fi
if [ -L "$SHIM_DIR/claude" ]; then
  ok "claude shim linked in $SHIM_DIR"
else
  warn "no claude shim — sessions will not carry a project label"
fi
if [ -f "$ZSHRC" ] && grep -qF "$WRAPPER_BEGIN" "$ZSHRC"; then
  ok "shim on PATH for terminals (via $(basename "$ZSHRC"))"
else
  warn "$SHIM_DIR not added to PATH by $(basename "$ZSHRC")"
fi
if [ -f "$ENV_D_FILE" ]; then
  ok "shim on PATH for the desktop app and IDEs (via environment.d)"
else
  warn "no environment.d entry — only terminal sessions get tagged"
fi
untagged="$(dc exec -T grafana curl -s --max-time 6 -G 'http://loki:3100/loki/api/v1/query' \
        --data-urlencode 'query=sum(count_over_time({service_name=~"claude-code.*"} | project="" [24h]))' 2>/dev/null \
        | jq -r '.data.result[0].value[1] // "0"')"
[ "${untagged:-0}" = "0" ] && ok "every event in the last 24h carries a project" \
  || warn "$untagged events in the last 24h have no project label"

step "Data arriving"
recv="$(dc exec -T grafana curl -s --max-time 4 http://otelcol:8888/metrics 2>/dev/null \
        | grep -E '^otelcol_receiver_accepted_(log_records|metric_points|spans)' | grep -v '^#')"
if [ -z "$recv" ]; then
  warn "collector has received nothing since it started"
else
  printf '%s\n' "$recv" | sed -E 's/^otelcol_receiver_accepted_([a-z_]+)\{[^}]*\} */\1 /' \
    | while read -r kind n; do
        [ "${n%%.*}" = "0" ] && warn "$(printf '%-14s %s' "$kind" "$n")" || ok "$(printf '%-14s %s' "$kind" "$n")"
      done
fi

last="$(dc exec -T grafana curl -s --max-time 6 -G 'http://loki:3100/loki/api/v1/query' \
        --data-urlencode 'query=sum(count_over_time({service_name=~"claude-code.*"}[24h]))' 2>/dev/null \
        | jq -r '.data.result[0].value[1] // "0"')"
[ "${last:-0}" != "0" ] && ok "$last events stored in the last 24h" || warn "no events stored in the last 24h"

spend="$(dc exec -T grafana curl -s --max-time 6 -G 'http://loki:3100/loki/api/v1/query' \
        --data-urlencode 'query=sum(sum_over_time({service_name=~"claude-code.*"} | event_name="api_request" | unwrap cost_usd [24h]))' 2>/dev/null \
        | jq -r '.data.result[0].value[1] // "0"')"
printf '    %sspend, last 24h: $%s%s\n' "$C_DIM" "$(printf '%.4f' "${spend:-0}" 2>/dev/null || echo "$spend")" "$C_OFF"

step "Disk"
pct="$(docker_disk_pct)"
thresh_pct="$(awk -v t="$DISK_THRESHOLD" 'BEGIN{printf "%d", t*100}')"
root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)"
if [ -n "$pct" ] && [ "$pct" -ge "$thresh_pct" ] 2>/dev/null; then
  err "${pct}% used on the volume holding $root — Loki drops events above ${thresh_pct}%"
else
  ok "${pct}% used on the volume holding $root (threshold ${thresh_pct}%)"
fi
du_out="$(docker system df -v 2>/dev/null \
  | awk '/^docschemy-telemetry_/ { sub(/^docschemy-telemetry_/, "", $1); printf "%s %s  ", $1, $3 }')"
[ -n "$du_out" ] && dim "stored: $du_out"

printf '\n  Grafana: http://localhost:%s\n\n' "$GRAFANA_PORT"
