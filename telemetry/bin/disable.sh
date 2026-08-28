#!/usr/bin/env bash
# Stop the stack and unhook Claude Code. Data is kept unless --purge is given.
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

step "Stopping containers"
if [ "$PURGE" = 1 ]; then
  dc down -v 2>&1 | sed 's/^/    /' || true
  ok "containers stopped and volumes deleted"
else
  dc down 2>&1 | sed 's/^/    /' || true
  ok "containers stopped, data volumes kept"
  dim "re-run 'make enable-telemetry' to pick up where you left off"
fi

step "Unhooking Claude Code"
if [ -f "$SETTINGS" ] && jq -e . "$SETTINGS" >/dev/null 2>&1; then
  keys_json="$(printf '%s\n' "${MANAGED_KEYS[@]}" | jq -R . | jq -s .)"
  merged="$(jq --argjson keys "$keys_json" '
    if .env == null then .
    else .env |= with_entries(select(.key as $k | $keys | index($k) | not))
       | if (.env | length) == 0 then del(.env) else . end
    end' "$SETTINGS")"
  if [ "$merged" = "$(cat "$SETTINGS")" ]; then
    ok "settings.json had nothing to remove"
  else
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d-%H%M%S)"
    printf '%s\n' "$merged" > "$SETTINGS"
    ok "removed the telemetry env keys from $SETTINGS"
    dim "any OTel keys you added by hand were left alone"
  fi
else
  warn "no readable $SETTINGS — nothing to unhook"
fi

if [ -f "$ZSHRC" ] && grep -qF "$WRAPPER_BEGIN" "$ZSHRC"; then
  cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d-%H%M%S)"
  awk -v b="$WRAPPER_BEGIN" -v e="$WRAPPER_END" '
    $0 == b { skip = 1 } skip != 1 { print } $0 == e { skip = 0 }' \
    "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
  ok "removed the project-tagging wrapper from $(basename "$ZSHRC")"
else
  ok "no shell wrapper to remove"
fi

step "Done"
printf '  %sRunning Claude sessions keep exporting until restarted.%s\n\n' "$C_WARN" "$C_OFF"
