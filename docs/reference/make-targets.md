# Makefile targets

`install` is the only target. There is no build, lint, or test step.

| Target | Effect |
|---|---|
| `install` | Symlinks each `skills/<name>/` into `$HOME/.claude/skills/<name>`. Idempotent, and never clobbers a path it didn't create — see [Install all skills](../how-to-guides.md#install-all-skills) for the three outcomes per skill. |

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_SKILLS_DIR` | `$(HOME)/.claude/skills` | Where symlinks are created. Created with `mkdir -p` if missing. |
| `REPO_SKILLS_DIR` | `$(CURDIR)/skills` | Where skills are read from. Resolves to an absolute path, so the symlinks it creates stay valid from any working directory. |

Both are plain `make` variables and can be overridden on the command line, e.g. `make install CLAUDE_SKILLS_DIR=/tmp/skills`.
