# Tags every Claude Code session with the project it runs in, so Grafana can
# break spend down per repo. Claude Code reads OTEL_RESOURCE_ATTRIBUTES from
# the environment; the shared OTLP settings live in ~/.claude/settings.json and
# never collide with this, because the two set different keys.
claude() {
  local project extra
  project="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
  extra="project=${project}"
  [[ -n "$OTEL_RESOURCE_ATTRIBUTES" ]] && extra="${OTEL_RESOURCE_ATTRIBUTES},${extra}"
  OTEL_RESOURCE_ATTRIBUTES="$extra" command claude "$@"
}
