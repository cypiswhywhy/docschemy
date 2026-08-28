# Shared helpers. Sourced, not executed.
set -euo pipefail

TELEMETRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
ZSHRC="${CLAUDE_TELEMETRY_RC:-$HOME/.zshrc}"
WRAPPER_BEGIN="# >>> docschemy claude telemetry >>>"
WRAPPER_END="# <<< docschemy claude telemetry <<<"

# Every settings key this stack owns. disable removes exactly these and
# nothing else, so hand-added OTel settings survive a disable.
MANAGED_KEYS=(
  CLAUDE_CODE_ENABLE_TELEMETRY
  CLAUDE_CODE_ENHANCED_TELEMETRY_BETA
  OTEL_METRICS_EXPORTER
  OTEL_LOGS_EXPORTER
  OTEL_TRACES_EXPORTER
  OTEL_EXPORTER_OTLP_PROTOCOL
  OTEL_EXPORTER_OTLP_ENDPOINT
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE
  OTEL_METRICS_INCLUDE_SESSION_ID
  OTEL_METRIC_EXPORT_INTERVAL
  OTEL_LOGS_EXPORT_INTERVAL
  OTEL_LOG_USER_PROMPTS
  OTEL_LOG_TOOL_DETAILS
)

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_OK=; C_WARN=; C_ERR=; C_DIM=; C_OFF=
fi

ok()   { printf '  %s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$*"; }
err()  { printf '  %s✗%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; }
dim()  { printf '    %s%s%s\n' "$C_DIM" "$*" "$C_OFF"; }
step() { printf '\n%s\n' "$*"; }

dc() { docker compose --project-directory "$TELEMETRY_DIR" -f "$TELEMETRY_DIR/compose.yaml" "$@"; }

# Read a key from .env, falling back to .env.example, then to a default.
envval() {
  local key="$1" default="${2:-}" val=""
  for f in "$TELEMETRY_DIR/.env" "$TELEMETRY_DIR/.env.example"; do
    [ -f "$f" ] || continue
    val="$(grep -E "^${key}=" "$f" 2>/dev/null | tail -1 | cut -d= -f2- || true)"
    [ -n "$val" ] && { printf '%s' "$val"; return; }
  done
  printf '%s' "$default"
}

# Poll an HTTP endpoint inside the compose network until it returns 200.
wait_http() {
  local name="$1" url="$2" timeout="${3:-90}" waited=0 code=""
  while [ "$waited" -lt "$timeout" ]; do
    code="$(dc exec -T grafana curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" 2>/dev/null || true)"
    [ "$code" = "200" ] && { ok "$name ready"; return 0; }
    dc exec -T grafana sh -c 'sleep 3' >/dev/null 2>&1 || sleep 3
    waited=$((waited + 3))
  done
  err "$name not ready after ${timeout}s (last HTTP ${code:-none})"
  return 1
}

port_busy() { ss -ltn 2>/dev/null | grep -qE "[:.]$1[[:space:]]"; }

# Percent-used of the filesystem backing Docker's data root, computed the way
# Loki's WAL guard computes it: used/total. df's own Use% column divides by
# (used + available) and so excludes the root-reserved blocks, reading several
# points higher -- comparing that against the Loki threshold gives false alarms.
docker_disk_pct() {
  local root; root="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)"
  df -k --output=size,used "$root" 2>/dev/null | tail -1 \
    | awk '{ if ($1 > 0) printf "%d", ($2 * 100) / $1 }'
}
