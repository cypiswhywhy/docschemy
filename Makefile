CLAUDE_SKILLS_DIR := $(HOME)/.claude/skills
REPO_SKILLS_DIR := $(CURDIR)/skills
TELEMETRY_BIN := $(CURDIR)/telemetry/bin

.PHONY: install
install:
	@mkdir -p "$(CLAUDE_SKILLS_DIR)"
	@for skill in $(REPO_SKILLS_DIR)/*/; do \
		name=$$(basename "$${skill%/}"); \
		src="$${skill%/}"; \
		target="$(CLAUDE_SKILLS_DIR)/$$name"; \
		if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$src" ]; then \
			echo "already linked: $$name"; \
		elif [ -e "$$target" ]; then \
			echo "SKIP: $$target already exists and is not linked to this repo (remove it manually to relink)"; \
		else \
			ln -s "$$src" "$$target"; \
			echo "linked: $$name -> $$target"; \
		fi; \
	done

# Local Claude Code telemetry. Brings up the observability stack and points
# every project's Claude Code at it. See docs/usage/telemetry.md.
.PHONY: enable-telemetry
enable-telemetry:
	@$(TELEMETRY_BIN)/enable.sh

# Stops the stack and removes the settings it added. Keeps collected data.
.PHONY: disable-telemetry
disable-telemetry:
	@$(TELEMETRY_BIN)/disable.sh

# Same, but also deletes the metrics, events and traces collected so far.
.PHONY: purge-telemetry
purge-telemetry:
	@$(TELEMETRY_BIN)/disable.sh --purge

# Reports whether telemetry is actually being collected, not just running.
.PHONY: telemetry-status
telemetry-status:
	@$(TELEMETRY_BIN)/status.sh
