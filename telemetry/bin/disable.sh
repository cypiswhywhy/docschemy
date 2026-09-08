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

step "Removing per-project tagging"
if rc_block_remove "$ZSHRC"; then
  ok "removed the PATH block from $(basename "$ZSHRC")"
else
  ok "no PATH block in $(basename "$ZSHRC")"
fi

if [ -L "$SHIM_DIR/claude" ]; then
  rm -f "$SHIM_DIR/claude"
  rmdir "$SHIM_DIR" 2>/dev/null || true
  ok "removed the claude shim from $SHIM_DIR"
elif [ -e "$SHIM_DIR/claude" ]; then
  warn "$SHIM_DIR/claude is not our symlink — left in place"
else
  ok "no claude shim to remove"
fi

restored=0
while IFS= read -r cli_dir; do
  if desktop_shim_remove "$cli_dir"; then
    restored=$((restored + 1))
  elif [ "$(desktop_shim_state "$cli_dir")" = "broken" ]; then
    err "$cli_dir/claude is our shim but claude.real is gone — reinstall the desktop app"
  fi
done < <(desktop_cli_dirs)
if [ "$restored" -gt 0 ]; then
  ok "restored $restored desktop CLI $([ "$restored" = 1 ] && echo binary || echo binaries)"
else
  ok "no shimmed desktop CLI to restore"
fi

if [ -f "$ENV_D_FILE" ]; then
  rm -f "$ENV_D_FILE"
  ok "removed $(basename "$ENV_D_FILE")"
  dim "graphical sessions keep the old PATH until you log out"
else
  ok "no environment.d file to remove"
fi

step "Done"
printf '  %sRunning Claude sessions keep exporting until restarted.%s\n\n' "$C_WARN" "$C_OFF"
