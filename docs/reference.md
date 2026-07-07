# Reference

## Repo layout

```text
docschemy/
├── Makefile          # `make install` — symlinks skills/ into ~/.claude/skills
├── skills/
│   └── <skill-name>/
│       └── SKILL.md  # skill definition (frontmatter + instructions)
└── docs/              # this documentation
```

## `SKILL.md` frontmatter

Each skill directory needs a `SKILL.md` with YAML frontmatter:

| Field | Required | Description |
|---|---|---|
| `name` | yes | Skill identifier, matches the directory name. |
| `description` | yes | One-line summary; Claude Code uses this to decide when the skill is relevant. |

The rest of the file is the skill's instructions, in plain Markdown.

## Makefile targets

| Target | Effect |
|---|---|
| `install` | Symlinks each `skills/<name>/` into `$HOME/.claude/skills/<name>`. Skips (with a message) any target that already exists and isn't already linked to this repo. |
