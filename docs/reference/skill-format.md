# `SKILL.md` format

A skill is a directory `skills/<skill-name>/` containing a `SKILL.md`. The file is YAML frontmatter followed by the skill's instructions in plain Markdown.

```markdown
---
name: docs-update
description: Update an existing Diátaxis-structured docs/ directory …
---

# docs-update

Incrementally updates `docs/` after a change — …
```

## Frontmatter fields

| Field | Required | Description |
|---|---|---|
| `name` | yes | Skill identifier. Matches the directory name, and is what the user types as `/<name>`. |
| `description` | yes | One-line summary. Claude Code uses this — not the body — to decide when the skill is relevant, so it should name the situations that should trigger it. |

## Directory contents

`make install` symlinks the whole `skills/<skill-name>/` directory, so any supporting files placed beside `SKILL.md` are visible to Claude Code at the same path. `SKILL.md` itself is the only file the skill must have.

Both skills in this repo are single-file; see [Skill catalog](skill-catalog.md).
