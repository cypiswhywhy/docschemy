# 0012. Tag desktop app sessions through the app's own environment variables

- **Status**: Accepted
- **Date**: 2026-09-09

## Context

[ADR 0011](0011-leave-desktop-app-sessions-untagged.md) left desktop app
sessions without a project label, because the only mechanism found that worked
meant replacing a binary the app installs and updates. It named the condition
for revisiting: the app exposing a supported way to set resource attributes per
session.

Reading the app's spawn code and the CLI it bundles showed that condition was
already met, and also explained the earlier failures:

- The app builds the session's `OTEL_RESOURCE_ATTRIBUTES` from its own
  identity fields (`service.name`, `service.version`, `os.*`, `host.arch`) and
  then merges in whatever `OTEL_RESOURCE_ATTRIBUTES` the session's environment
  already carries, keeping any key that does not collide with those fields.
  `project` does not collide, so a user-supplied `project=<repo>` survives.
- That environment includes the variables the app lets a user set in its own
  settings, which it stores encrypted and applies at spawn. Its blocked-key list
  covers credentials, `PATH` and a few Claude Code flags;
  `OTEL_RESOURCE_ATTRIBUTES` is not on it.
- The app tells the CLI which environment keys it set, and the CLI's settings
  loader drops any `env` entry from a settings file whose key is on that list.
  This is why a project-level `.claude/settings.json` could never win — not
  precedence between two values, but a deliberate host-claimed key.

Verified on 2026-09-09: a desktop session started with
`OTEL_RESOURCE_ATTRIBUTES=project=llm-benchmark-and-evaluation` set in the
app's environment variables arrived in Loki as
`service_name=claude-code-desktop` with `project=llm-benchmark-and-evaluation`,
the first desktop events to carry a label.

## Decision

Tag desktop app sessions by setting `OTEL_RESOURCE_ATTRIBUTES=project=<repo>`
in the environment variables the desktop app itself provides for a session.
Nothing is installed into the app's directory, which keeps the property ADR 0011
chose: an app update cannot break tagging, and tagging cannot break an app
update.

The service-name half of [ADR 0010](0010-shim-the-desktop-apps-bundled-cli.md)
is unchanged: everything that reads events still matches
`service_name=~"claude-code.*"`, and `terminal_type` still separates the
launchers.

This supersedes ADR 0011's decision to leave those sessions untagged. Its
reasoning about the app's directory stands and is carried forward here.

## Consequences

The label is set by hand, per session, in the current app UI. The app's code
carries a per-folder scope for these variables as well, but that scope was not
found in the UI on the app version tested, so this record makes no claim about
it. <!-- TODO: verify whether a later app version exposes per-folder environment variables -->
A session started without the variable is recorded in full and groups under
`untagged`, exactly as before, so `make telemetry-status` still reports a
non-zero untagged count whenever a desktop session was started without it.

The two mechanisms cannot conflict. The `PATH` shim leaves a `project=` the
caller already set alone, and the app appends the user's attributes to its own
rather than replacing them, so a value set in the app reaches the collector
unchanged.

If the app later exposes the per-folder scope, the same variable set once per
folder removes the per-session step without any change to this stack.
