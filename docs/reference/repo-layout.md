# Repo layout

```text
docschemy/
├── Makefile              # install + telemetry targets — see make-targets.md
├── CLAUDE.md             # repo guidance for Claude Code itself
├── README.md             # pitch + quickstart + links into docs/
├── CONTRIBUTING.md       # how to work on the skills
├── skills/
│   └── <skill-name>/
│       └── SKILL.md      # skill definition — see skill-format.md
├── telemetry/            # the local monitoring stack — see telemetry-configuration.md
│   ├── compose.yaml      # collector, Prometheus, Loki, Tempo, Grafana
│   ├── bin/              # enable / disable / status scripts
│   ├── grafana/          # provisioned datasources and dashboards
│   └── shell/            # the per-project tagging PATH shim
└── docs/                 # this documentation
    ├── usage/            # installing and running the skills
    ├── reference/        # these pages
    ├── internals/        # architecture, convention, adrs/
    └── assets/           # figures — dashboard screenshots; diagrams stay inline as Mermaid
```

`skills/` is the payload the repo exists to publish — no application source, no build output, no generated files. Every directory directly under `skills/` is treated as a skill by [`make install`](make-targets.md); nothing else in the repo is, `telemetry/` included.

`telemetry/` is the one part of the repo that is infrastructure rather than content. It is self-contained and optional: nothing under `skills/` reads it, and the skills work whether or not it has ever been started.

The skills currently shipped are listed in [Skill catalog](skill-catalog.md).

`.claude/settings.local.json` holds this repo's local Claude Code permission allowlist. It configures the tooling, not the skills, and has no effect on projects the skills run against.
