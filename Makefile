.PHONY: help install install-minimal update stow unstow restow backup clean test

# Default target
help:
	@echo "Dotfiles Management Commands:"
	@echo ""
	@echo "  make install         - Run full interactive installation"
	@echo "  make install-minimal - Install only required components"
	@echo "  make update          - Update all components"
	@echo "  make stow            - Stow all dotfiles packages"
	@echo "  make unstow          - Unstow all dotfiles packages"
	@echo "  make restow          - Re-stow all packages (refresh)"
	@echo "  make backup          - Create manual backup"
	@echo "  make clean           - Remove old backups"
	@echo "  make test            - Test installation scripts"
	@echo "  make log             - View installation log"
	@echo ""

# Run full installation
install:
	@echo "Starting full installation..."
	@./install.sh

# Run minimal installation
install-minimal:
	@echo "Starting minimal installation..."
	@./install.sh --skip-optional

# Update everything
update:
	@echo "Updating dotfiles repository..."
	@git pull origin main
	@echo ""
	@echo "Updating system packages..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		brew update && brew upgrade; \
	else \
		sudo apt update && sudo apt upgrade -y; \
	fi
	@echo ""
	@echo "Re-stowing dotfiles..."
	@stow --restow */
	@echo ""
	@echo "✓ Update complete!"

# Stow all packages
stow:
	@echo "Stowing all packages..."
	@stow --verbose=1 */
	@echo "✓ All packages stowed"

# Unstow all packages
unstow:
	@echo "Unstowing all packages..."
	@stow -D --verbose=1 */
	@echo "✓ All packages unstowed"

# Re-stow all packages
restow:
	@echo "Re-stowing all packages..."
	@stow --restow --verbose=1 */
	@echo "✓ All packages re-stowed"

# Create manual backup
backup:
	@BACKUP_DIR="$$HOME/.dotfiles_backup_$$(date +%Y%m%d_%H%M%S)_manual"; \
	mkdir -p "$$BACKUP_DIR"; \
	echo "Creating backup in $$BACKUP_DIR..."; \
	for file in .zshrc .bashrc .profile .gitconfig .tmux.conf; do \
		if [ -e "$$HOME/$$file" ] && [ ! -L "$$HOME/$$file" ]; then \
			cp "$$HOME/$$file" "$$BACKUP_DIR/"; \
			echo "  Backed up: $$file"; \
		fi; \
	done; \
	if [ -d "$$HOME/.config" ] && [ ! -L "$$HOME/.config" ]; then \
		cp -r "$$HOME/.config" "$$BACKUP_DIR/"; \
		echo "  Backed up: .config/"; \
	fi; \
	echo "✓ Backup complete: $$BACKUP_DIR"

# Clean old backups
clean:
	@echo "Cleaning old backups..."
	@OLD_BACKUPS=$$(find "$$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" | sort); \
	COUNT=$$(echo "$$OLD_BACKUPS" | grep -c .); \
	if [ $$COUNT -gt 3 ]; then \
		echo "Found $$COUNT backups. Keeping 3 most recent..."; \
		echo "$$OLD_BACKUPS" | head -n -3 | while read backup; do \
			echo "  Removing: $$(basename $$backup)"; \
			rm -rf "$$backup"; \
		done; \
		echo "✓ Old backups cleaned"; \
	else \
		echo "Only $$COUNT backups found. Nothing to clean."; \
	fi

# Test scripts
test:
	@echo "Testing installation scripts..."
	@echo ""
	@for script in scripts/install-*.sh scripts/setup-*.sh; do \
		echo "Checking $$script..."; \
		bash -n "$$script" && echo "  ✓ Syntax OK" || echo "  ✗ Syntax Error"; \
	done
	@echo ""
	@echo "✓ All scripts checked"

# View log
log:
	@if [ -f .install.log ]; then \
		less .install.log; \
	else \
		echo "No installation log found. Run 'make install' first."; \
	fi

# Quick status check
status:
	@echo "Dotfiles Status:"
	@echo ""
	@echo "Repository:"
	@git status --short
	@echo ""
	@echo "Installed Tools:"
	@command -v nvim >/dev/null 2>&1 && echo "  ✓ neovim" || echo "  ✗ neovim"
	@command -v tmux >/dev/null 2>&1 && echo "  ✓ tmux" || echo "  ✗ tmux"
	@command -v starship >/dev/null 2>&1 && echo "  ✓ starship" || echo "  ✗ starship"
	@command -v docker >/dev/null 2>&1 && echo "  ✓ docker" || echo "  ✗ docker"
	@command -v node >/dev/null 2>&1 && echo "  ✓ node" || echo "  ✗ node"
	@command -v python3 >/dev/null 2>&1 && echo "  ✓ python3" || echo "  ✗ python3"
	@command -v claude >/dev/null 2>&1 && echo "  ✓ claude" || echo "  ✗ claude"
	@echo ""
	@echo "Shell:"
	@echo "  Current: $$SHELL"
	@echo "  Default: $$(getent passwd $$USER | cut -d: -f7)"
	@echo ""
	@echo "Backups:"
	@ls -d $$HOME/.dotfiles_backup_* 2>/dev/null | wc -l | xargs echo "  Count:"
	@ls -dt $$HOME/.dotfiles_backup_* 2>/dev/null | head -1 | xargs -I {} sh -c 'echo "  Latest: $$(basename {})"'
