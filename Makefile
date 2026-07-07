CLAUDE_SKILLS_DIR := $(HOME)/.claude/skills
REPO_SKILLS_DIR := $(CURDIR)/skills

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
