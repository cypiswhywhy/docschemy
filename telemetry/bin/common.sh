# Shared helpers. Sourced, not executed.
set -euo pipefail

TELEMETRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
ZSHRC="${CLAUDE_TELEMETRY_RC:-$HOME/.zshrc}"
SHIM_DIR="${CLAUDE_SHIM_DIR:-$HOME/.claude/shims}"
ENV_D="${CLAUDE_ENV_D:-$HOME/.config/environment.d}"
# The desktop app never consults PATH: it execs a CLI it downloads itself, at
# an absolute, version-pinned path. Tagging those sessions means shimming that
# path directly -- see desktop_shim_apply.
DESKTOP_CLI_ROOT="${CLAUDE_DESKTOP_CLI_ROOT:-$HOME/.config/Claude/claude-code}"
ENV_D_FILE="$ENV_D/10-docschemy-claude-telemetry.conf"
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

# Delete the marked block from a shell rc, if present. Returns 0 when it
# removed something, 1 when there was nothing there. Used both to install a
# newer block over an older one and to uninstall.
rc_block_remove() {
  local file="$1"
  [ -f "$file" ] || return 1
  grep -qF "$WRAPPER_BEGIN" "$file" || return 1
  cp "$file" "$file.bak.$(date +%Y%m%d-%H%M%S)"
  awk -v b="$WRAPPER_BEGIN" -v e="$WRAPPER_END" '
    $0 == b { skip = 1 } skip != 1 { print } $0 == e { skip = 0 }' \
    "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# --- desktop app CLI shim -----------------------------------------------
# The app keeps one directory per CLI version and execs <version>/claude with
# the session's project as its working directory. Installing a shim there is
# the only way a desktop session can carry a project label: settings.json env
# loses to the OTEL_RESOURCE_ATTRIBUTES the app injects at spawn, and no event
# carries a path the collector could derive one from.
#
# What goes in the version directory is a generated wrapper, not a symlink to
# shell/claude-shim. An app update that writes its new binary to that path
# would follow a symlink and overwrite the shim in this repo -- breaking
# tagging everywhere, including terminals. A copy absorbs that hit alone.
#
# The other cost is that a CLI update landing in a *new* version directory
# arrives unshimmed and tagging stops silently. Nothing here can prevent that;
# desktop_shim_state is what turns it into a visible warning in
# 'make telemetry-status', and re-running enable re-applies it.
DESKTOP_SHIM_MARKER="# docschemy-claude-telemetry desktop shim"

# Print every version directory holding a CLI, in name order. Silent -- and
# successful -- when the desktop app isn't installed, since callers run under
# `set -e` and a missing desktop app is not an error.
desktop_cli_dirs() {
  [ -d "$DESKTOP_CLI_ROOT" ] || return 0
  local d
  for d in "$DESKTOP_CLI_ROOT"/*/; do
    d="${d%/}"
    [ -e "$d/claude" ] || [ -e "$d/claude.real" ] || continue
    printf '%s\n' "$d"
  done
  return 0
}

# shimmed | unshimmed | broken. `broken` means our wrapper is in place but the
# binary it hands off to is not -- that directory would fail to launch, so it
# is an error, not a nudge.
desktop_shim_state() {
  local dir="$1" link real
  link="$dir/claude"; real="$dir/claude.real"
  if [ -f "$link" ] && ! [ -L "$link" ] \
     && head -c 400 "$link" 2>/dev/null | grep -qF "$DESKTOP_SHIM_MARKER"; then
    [ -x "$real" ] && printf 'shimmed' || printf 'broken'
  else
    printf 'unshimmed'
  fi
}

# Move the real binary aside and take its place. Idempotent. Re-running after
# the app has replaced the binary in an existing directory re-shims it, and the
# fresh binary correctly overwrites the stale claude.real.
desktop_shim_apply() {
  local dir="$1" link real
  link="$dir/claude"; real="$dir/claude.real"
  case "$(desktop_shim_state "$dir")" in
    shimmed) return 0 ;;
    broken)  rm -f "$link" ;;
  esac
  [ -f "$link" ] && ! [ -L "$link" ] || return 1
  mv -f "$link" "$real" || return 1
  cat > "$link" <<EOF || return 1
#!/bin/sh
$DESKTOP_SHIM_MARKER
# Generated by 'make enable-telemetry'; removed by 'make disable-telemetry'.
# The desktop app execs this path directly, so PATH never comes into it. Hand
# off to the shared shim, naming the binary this app version expects -- a PATH
# scan would find the terminal's separately-updated copy instead.
CLAUDE_REAL_BIN="$real" exec "$TELEMETRY_DIR/shell/claude-shim" "\$@"
EOF
  chmod +x "$link"
}

# Put the real binary back. Leaves a directory we did not shim untouched.
desktop_shim_remove() {
  local dir="$1" link real
  link="$dir/claude"; real="$dir/claude.real"
  [ "$(desktop_shim_state "$dir")" = "unshimmed" ] && return 1
  [ -e "$real" ] || return 1
  rm -f "$link"
  mv -f "$real" "$link"
}
