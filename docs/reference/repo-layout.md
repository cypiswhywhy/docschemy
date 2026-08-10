# Repo layout

```text
docschemy/
├── Makefile              # `make install` — see make-targets.md
├── CLAUDE.md             # repo guidance for Claude Code itself
├── README.md             # pitch + quickstart + links into docs/
├── skills/
│   └── <skill-name>/
│       └── SKILL.md      # skill definition — see skill-format.md
└── docs/                 # this documentation
```

`skills/` is the entire payload of the repo — there is no application source, no build output, and no generated files. Every directory directly under `skills/` is treated as a skill by [`make install`](make-targets.md); nothing else in the repo is.

The skills currently shipped are listed in [Skill catalog](skill-catalog.md).
