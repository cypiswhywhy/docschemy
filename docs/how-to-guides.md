# How-To Guides

## Install all skills

Symlinks every directory under `skills/` into `~/.claude/skills/`, so edits in this repo take effect immediately without reinstalling:

```sh
make install
```

If a target already exists at `~/.claude/skills/<name>` and isn't a symlink back to this repo, the install is skipped for that skill with a warning — remove the conflicting file/directory manually and re-run `make install` to link it.

## Add a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`) followed by the skill's instructions. See `skills/docs-init/SKILL.md` for an example.
2. Run `make install` to symlink it into `~/.claude/skills/`.
3. Restart or reload Claude Code so it picks up the new skill.

## Update an existing skill

Edit the `SKILL.md` (or supporting files) directly under `skills/<skill-name>/` — because `make install` uses symlinks, changes are picked up without reinstalling.
