# docschemy

A personal collection of [Claude Code](https://claude.com/claude-code) skills, kept in one repo and symlinked into every machine's `~/.claude/skills/`. The skills it currently ships generate, maintain and search project documentation in a fixed structure.

It also ships an optional local telemetry stack, so Claude Code sessions across every project can be monitored without any data leaving the machine.

## Install

```sh
make install
```

Full instructions, including what happens when a skill name is already taken, are in [Install the skills](docs/usage/install.md).

## Usage

From a Claude Code session in any other project:

```text
/docs-init
```

See [Usage](docs/usage/README.md) for running all four skills and choosing between them.

## Telemetry

```sh
make enable-telemetry
```

Brings up a local Grafana on <http://localhost:3000> showing spend, latency, tool failures and traces for every Claude Code session on the machine, broken down by project without any per-project setup. Everything runs in Docker on loopback.

![Grafana Overview dashboard for Claude Code. Five stat panels read Spend $51.98, Tokens 71.2 million, API requests 441, Spend per request $0.1179 and Cache read share 98.3%. Below, spend over time splits by model, and a donut splits the same total across four projects: toolchemy $49.12, genealogy $2.07, docschemy $0.42 and printer $0.37.](docs/assets/telemetry-overview-spend.png)

Setting it up: [Collect telemetry from your Claude Code sessions](docs/usage/telemetry.md). A tour of every panel: [Read the telemetry dashboards](docs/usage/telemetry-dashboards.md).

## Reference

Skill catalog, `SKILL.md` frontmatter, repo layout and Makefile targets — [Reference](docs/reference/README.md).

## Internals

How skills reach Claude Code, the documentation convention they encode, and the decisions behind both, for anyone working on this repo — [Internals](docs/internals/README.md).

## Contributing

Adding or changing a skill: [CONTRIBUTING.md](CONTRIBUTING.md).
