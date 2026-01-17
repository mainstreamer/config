# Makefile for dotfiles management
# ================================
#
# Production (fresh system):  curl install from GitHub
# Development (local):        make install, make test
# Rollback:                   make rollback

SHELL := /bin/bash
DOTFILES_DIR := $(shell pwd)
BACKUP_DIR := $(HOME)/.dotfiles-backups
TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
REPO_URL := https://raw.githubusercontent.com/mainstreamer/config/master/install.sh

# Detect platform
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
    PLATFORM := macos
else
    PLATFORM := linux
endif

.PHONY: help install install-remote install-deps install-links install-apps \
        backup rollback list-backups test uninstall clean nvim \
        pack-linux pack-mac

# =============================================================================
# HELP
# =============================================================================
help:
	@echo ""
	@echo "Dotfiles Management"
	@echo "==================="
	@echo ""
	@echo "PRODUCTION (fresh system):"
	@echo "  make install-remote       Curl and run install.sh from GitHub"
	@echo "  make install-remote-minimal  Same but with --minimal flag"
	@echo ""
	@echo "DEVELOPMENT (local testing):"
	@echo "  make install              Full local install (deps + links)"
	@echo "  make install-deps         Install packages only"
	@echo "  make install-links        Create symlinks only"
	@echo "  make install-apps         Install apps from apps.conf"
	@echo "  make test                 Dry-run, show what would happen"
	@echo ""
	@echo "BACKUP & ROLLBACK:"
	@echo "  make backup               Create backup of current config"
	@echo "  make rollback             Restore most recent backup"
	@echo "  make rollback DATE=xxx    Restore specific backup (xxx=YYYYMMDD-HHMMSS)"
	@echo "  make list-backups         List available backups"
	@echo ""
	@echo "UTILITIES:"
	@echo "  make nvim                 Install nvim config only (with backup)"
	@echo "  make uninstall            Remove all symlinks (keeps backups)"
	@echo "  make clean                Remove build artifacts"
	@echo ""
	@echo "LEGACY:"
	@echo "  make pack-linux           Archive Linux config to cfglx.tar.gz"
	@echo "  make pack-mac             Archive macOS config to cfgmc.tar.gz"
	@echo ""
	@echo "Detected platform: $(PLATFORM)"
	@echo ""

# =============================================================================
# PRODUCTION - Remote install from GitHub
# =============================================================================
install-remote:
	@echo "Installing from GitHub..."
	curl -fsSL $(REPO_URL) | bash

install-remote-minimal:
	@echo "Installing from GitHub (minimal mode)..."
	curl -fsSL $(REPO_URL) | bash -s -- --minimal

install-remote-no-sudo:
	@echo "Installing from GitHub (no-sudo mode)..."
	curl -fsSL $(REPO_URL) | bash -s -- --no-sudo

# =============================================================================
# DEVELOPMENT - Local install
# =============================================================================
install: backup
	@echo "Running local install..."
	@$(DOTFILES_DIR)/install.sh

install-deps:
	@echo "Installing dependencies only..."
	@$(DOTFILES_DIR)/install.sh --deps-only

install-links: backup
	@echo "Creating symlinks only..."
	@$(DOTFILES_DIR)/install.sh --stow-only

install-apps:
	@echo "Installing apps from apps.conf..."
	@$(MAKE) _install-apps-$(PLATFORM)

_install-apps-linux:
	@echo "Installing Linux apps..."
	@sed -n '/^\[linux\]/,/^\[/p' apps.conf | sed '1d;/^\[/d' | grep -v '^#' | grep -v '^$$' | while read app; do \
		if command -v $$app &>/dev/null; then \
			echo "  $$app: already installed"; \
		else \
			echo "  Installing $$app..."; \
			if command -v dnf &>/dev/null; then \
				sudo dnf install -y $$app 2>/dev/null || true; \
			elif command -v apt &>/dev/null; then \
				sudo apt install -y $$app 2>/dev/null || true; \
			elif command -v pacman &>/dev/null; then \
				sudo pacman -S --noconfirm $$app 2>/dev/null || true; \
			fi; \
		fi; \
	done

_install-apps-macos:
	@echo "Installing macOS apps..."
	@sed -n '/^\[macos\]/,/^\[/p' apps.conf | sed '1d;/^\[/d' | grep -v '^#' | grep -v '^$$' | while read app; do \
		if brew list $$app &>/dev/null || brew list --cask $$app &>/dev/null; then \
			echo "  $$app: already installed"; \
		else \
			echo "  Installing $$app..."; \
			brew install --cask $$app 2>/dev/null || brew install $$app 2>/dev/null || true; \
		fi; \
	done

# =============================================================================
# TESTING
# =============================================================================
test:
	@echo ""
	@echo "=== DRY RUN - What would happen ==="
	@echo ""
	@echo "Platform: $(PLATFORM)"
	@echo "Dotfiles dir: $(DOTFILES_DIR)"
	@echo ""
	@echo "Symlinks to create:"
	@echo "  ~/.bashrc -> $(DOTFILES_DIR)/shell/.bashrc"
	@echo "  ~/.zshrc -> $(DOTFILES_DIR)/shell/.zshrc"
	@echo "  ~/.shellrc.d -> $(DOTFILES_DIR)/shell/.shellrc.d"
	@echo "  ~/.config/nvim -> $(DOTFILES_DIR)/nvim"
	@echo "  ~/.config/starship.toml -> $(DOTFILES_DIR)/starship/starship.toml"
	@echo ""
	@echo "Current state:"
	@[ -L ~/.bashrc ] && echo "  ~/.bashrc is a symlink -> $$(readlink ~/.bashrc)" || echo "  ~/.bashrc is a regular file (will be backed up)"
	@[ -L ~/.config/nvim ] && echo "  ~/.config/nvim is a symlink -> $$(readlink ~/.config/nvim)" || echo "  ~/.config/nvim is a regular dir (will be backed up)"
	@echo ""
	@echo "Apps from apps.conf [$(PLATFORM)]:"
	@sed -n '/^\[$(PLATFORM)\]/,/^\[/p' apps.conf 2>/dev/null | sed '1d;/^\[/d' | grep -v '^#' | grep -v '^$$' | head -10 | while read app; do \
		if command -v $$app &>/dev/null; then \
			echo "  $$app (installed)"; \
		else \
			echo "  $$app (will install)"; \
		fi; \
	done || echo "  (none configured)"
	@echo ""

# =============================================================================
# BACKUP & ROLLBACK
# =============================================================================
backup:
	@mkdir -p $(BACKUP_DIR)
	@echo "Creating backup at $(BACKUP_DIR)/$(TIMESTAMP)..."
	@mkdir -p $(BACKUP_DIR)/$(TIMESTAMP)
	@[ -f ~/.bashrc ] && [ ! -L ~/.bashrc ] && cp ~/.bashrc $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -f ~/.zshrc ] && [ ! -L ~/.zshrc ] && cp ~/.zshrc $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -d ~/.bashrc.d ] && [ ! -L ~/.bashrc.d ] && cp -r ~/.bashrc.d $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -d ~/.zshrc.d ] && [ ! -L ~/.zshrc.d ] && cp -r ~/.zshrc.d $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -d ~/.shellrc.d ] && [ ! -L ~/.shellrc.d ] && cp -r ~/.shellrc.d $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -d ~/.config/nvim ] && [ ! -L ~/.config/nvim ] && cp -r ~/.config/nvim $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -f ~/.config/starship.toml ] && [ ! -L ~/.config/starship.toml ] && cp ~/.config/starship.toml $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@echo "Backup complete: $(BACKUP_DIR)/$(TIMESTAMP)"
	@# Save timestamp for easy rollback
	@echo "$(TIMESTAMP)" > $(BACKUP_DIR)/.latest

rollback:
	@if [ -n "$(DATE)" ]; then \
		RESTORE_DIR="$(BACKUP_DIR)/$(DATE)"; \
	elif [ -f $(BACKUP_DIR)/.latest ]; then \
		RESTORE_DIR="$(BACKUP_DIR)/$$(cat $(BACKUP_DIR)/.latest)"; \
	else \
		echo "No backup found. Use 'make list-backups' to see available backups."; \
		exit 1; \
	fi; \
	echo "Restoring from $$RESTORE_DIR..."; \
	[ -f "$$RESTORE_DIR/.bashrc" ] && rm -f ~/.bashrc && cp "$$RESTORE_DIR/.bashrc" ~/ && echo "  Restored .bashrc"; \
	[ -f "$$RESTORE_DIR/.zshrc" ] && rm -f ~/.zshrc && cp "$$RESTORE_DIR/.zshrc" ~/ && echo "  Restored .zshrc"; \
	[ -d "$$RESTORE_DIR/.bashrc.d" ] && rm -rf ~/.bashrc.d && cp -r "$$RESTORE_DIR/.bashrc.d" ~/ && echo "  Restored .bashrc.d"; \
	[ -d "$$RESTORE_DIR/.shellrc.d" ] && rm -rf ~/.shellrc.d && cp -r "$$RESTORE_DIR/.shellrc.d" ~/ && echo "  Restored .shellrc.d"; \
	[ -d "$$RESTORE_DIR/nvim" ] && rm -rf ~/.config/nvim && cp -r "$$RESTORE_DIR/nvim" ~/.config/ && echo "  Restored nvim"; \
	[ -f "$$RESTORE_DIR/starship.toml" ] && rm -f ~/.config/starship.toml && cp "$$RESTORE_DIR/starship.toml" ~/.config/ && echo "  Restored starship.toml"; \
	echo "Rollback complete."

list-backups:
	@echo "Available backups in $(BACKUP_DIR):"
	@ls -1 $(BACKUP_DIR) 2>/dev/null | grep -v '.latest' | sort -r || echo "  (none)"
	@echo ""
	@[ -f $(BACKUP_DIR)/.latest ] && echo "Latest: $$(cat $(BACKUP_DIR)/.latest)" || true

# =============================================================================
# NVIM ONLY
# =============================================================================
nvim:
	@echo "Installing nvim config..."
	@mkdir -p $(HOME)/.config/nvim.bkp
	@[ -d $(HOME)/.config/nvim ] && tar -cjf $(HOME)/.config/nvim.bkp/nvim_$(TIMESTAMP).tar.bz2 -C $(HOME)/.config nvim && echo "Backup saved: nvim.bkp/nvim_$(TIMESTAMP).tar.bz2" || true
	@rm -rf $(HOME)/.config/nvim
	@ln -sf $(DOTFILES_DIR)/nvim $(HOME)/.config/nvim
	@echo "nvim config installed (symlinked)"

# =============================================================================
# UNINSTALL
# =============================================================================
uninstall:
	@echo "Removing symlinks..."
	@[ -L ~/.bashrc ] && rm ~/.bashrc && echo "  Removed ~/.bashrc" || true
	@[ -L ~/.zshrc ] && rm ~/.zshrc && echo "  Removed ~/.zshrc" || true
	@[ -L ~/.shellrc.d ] && rm ~/.shellrc.d && echo "  Removed ~/.shellrc.d" || true
	@[ -L ~/.bashrc.d ] && rm ~/.bashrc.d && echo "  Removed ~/.bashrc.d" || true
	@[ -L ~/.config/nvim ] && rm ~/.config/nvim && echo "  Removed ~/.config/nvim" || true
	@[ -L ~/.config/starship.toml ] && rm ~/.config/starship.toml && echo "  Removed ~/.config/starship.toml" || true
	@echo "Done. Run 'make rollback' to restore previous config."

# =============================================================================
# LEGACY - Pack archives (for manual deployment)
# =============================================================================
pack-linux:
	@echo "Building Linux config archive..."
	@cd shell && tar -cvzf ../cfglx.tar.gz .bashrc .shellrc.d/
	@echo "Created cfglx.tar.gz"

pack-mac:
	@echo "Building macOS config archive..."
	@cd shell && tar -cvzf ../cfgmc.tar.gz .zshrc .shellrc.d/
	@echo "Created cfgmc.tar.gz"

# =============================================================================
# CLEAN
# =============================================================================
clean:
	@rm -f cfglx.tar.gz cfgmc.tar.gz
	@echo "Cleaned build artifacts"
