# Repo layout

```text
docschemy/
├── Makefile              # `make install` — see make-targets.md
├── CLAUDE.md             # repo guidance for Claude Code itself
├── README.md             # pitch + quickstart + links into docs/
├── CONTRIBUTING.md       # how to work on the skills
├── skills/
│   └── <skill-name>/
│       └── SKILL.md      # skill definition — see skill-format.md
└── docs/                 # this documentation
    ├── usage/            # installing and running the skills
    ├── reference/        # these pages
    ├── internals/        # architecture, convention, adrs/
    └── assets/           # figures (currently empty — all diagrams are inline Mermaid)
```

`skills/` is the entire payload of the repo — there is no application source, no build output, and no generated files. Every directory directly under `skills/` is treated as a skill by [`make install`](make-targets.md); nothing else in the repo is.

The skills currently shipped are listed in [Skill catalog](skill-catalog.md).

`.claude/settings.local.json` holds this repo's local Claude Code permission allowlist. It configures the tooling, not the skills, and has no effect on projects the skills run against.
