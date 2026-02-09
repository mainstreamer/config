# Makefile for epicli management
# ================================
#
# Standard (default):  curl -fsSL https://tldr.icu/i | bash
# Developer:           curl -fsSL https://tldr.icu/i | bash -s -- --dev
# Local dev:           make install, make test

SHELL := /bin/bash
DOTFILES_DIR := $(shell pwd)
BACKUP_DIR := $(HOME)/.epicli-backups
TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)

# Detect platform
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
    PLATFORM := macos
else
    PLATFORM := linux
endif

.PHONY: help install install-remote install-remote-dev install-deps install-links install-apps \
        backup rollback list-backups test uninstall clean nvim \
        starship-preset fonts guake-config \
        bump-patch bump-minor bump-major deploy archive

# Colors
CYAN := \033[1;36m
GREEN := \033[1;32m
YELLOW := \033[1;33m
MAGENTA := \033[1;35m
WHITE := \033[1;37m
DIM := \033[2m
RESET := \033[0m

# =============================================================================
# HELP
# =============================================================================
help:
	@printf "\n"
	@printf "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"
	@printf "$(WHITE)  epicli$(RESET)  $(DIM)platform: $(PLATFORM)$(RESET)\n"
	@printf "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)\n"
	@printf "\n"
	@printf "$(YELLOW)INSTALL:$(RESET) $(GREEN)curl -fsSL https://tldr.icu/i | bash$(RESET)\n"
	@printf "$(YELLOW)REMOTE$(RESET) $(DIM)(fresh system)$(RESET)\n"
	@printf "  $(GREEN)make install-remote$(RESET)          Standard mode (no sudo required)\n"
	@printf "  $(GREEN)make install-remote-dev$(RESET)      Dev mode (requires sudo)\n"
	@printf "\n"
	@printf "$(YELLOW)LOCAL$(RESET) $(DIM)(development)$(RESET)\n"
	@printf "  $(GREEN)make install$(RESET)                 Full local install (deps + links)\n"
	@printf "  $(GREEN)make install-deps$(RESET)            Install packages only\n"
	@printf "  $(GREEN)make install-links$(RESET)           Create symlinks only\n"
	@printf "  $(GREEN)make install-apps$(RESET)            Install apps from deps/apps.conf\n"
	@printf "  $(GREEN)make test$(RESET)                    Dry-run, show what would happen\n"
	@printf "\n"
	@printf "$(YELLOW)BACKUP & ROLLBACK$(RESET)\n"
	@printf "  $(GREEN)make backup$(RESET)                  Create backup of current config\n"
	@printf "  $(GREEN)make rollback$(RESET)                Restore most recent backup\n"
	@printf "  $(GREEN)make rollback DATE=xxx$(RESET)       Restore specific backup\n"
	@printf "  $(GREEN)make list-backups$(RESET)            List available backups\n"
	@printf "\n"
	@printf "$(YELLOW)CUSTOMIZATION$(RESET)\n"
	@printf "  $(GREEN)make starship-preset$(RESET)         Install starship theme\n"
	@printf "  $(DIM)  PRESET=gruvbox-rainbow      (default)$(RESET)\n"
	@printf "  $(DIM)  PRESET=tokyo-night          Popular presets: pastel-powerline,$(RESET)\n"
	@printf "  $(DIM)                              nerd-font-symbols, pure-preset$(RESET)\n"
	@printf "\n"
	@printf "$(YELLOW)UTILITIES$(RESET)\n"
	@printf "  $(GREEN)make nvim$(RESET)                    Install nvim config only\n"
	@printf "  $(GREEN)make fonts$(RESET)                   Install Nerd Fonts (Linux)\n"
	@printf "  $(GREEN)make guake-config$(RESET)            Apply guake config (Linux)\n"
	@printf "  $(GREEN)make uninstall$(RESET)               Remove all symlinks\n"
	@printf "  $(GREEN)make clean$(RESET)                   Remove build artifacts\n"
	@printf "\n"
	@printf "$(YELLOW)VERSIONING$(RESET)\n"
	@printf "  $(GREEN)make version$(RESET)                 Show current version\n"
	@printf "  $(GREEN)make bump-patch$(RESET)              Bump patch (2.0.0 -> 2.0.1)\n"
	@printf "  $(GREEN)make bump-minor$(RESET)              Bump minor (2.0.0 -> 2.1.0)\n"
	@printf "  $(GREEN)make bump-major$(RESET)              Bump major (2.0.0 -> 3.0.0)\n"
	@printf "  $(GREEN)make archive$(RESET)                 Create master.tar.gz\n"
	@printf "  $(GREEN)make deploy$(RESET)                  Deploy to server (script + archive)\n"
	@printf "  $(DIM)  SERVER=tldr.icu DEPLOY_PATH=/srv/dotfiles$(RESET)\n"
	@printf "\n"

# =============================================================================
# REMOTE - Install from GitHub
# =============================================================================
install-remote:
	@echo "Installing from GitHub (standard mode)..."
	curl -fsSL https://tldr.icu/i | bash

install-remote-dev:
	@echo "Installing from GitHub (dev mode)..."
	curl -fsSL https://tldr.icu/i | bash -s -- --dev

# =============================================================================
# LOCAL - Development install
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
	@echo "Installing apps from deps/apps.conf..."
	@$(MAKE) _install-apps-$(PLATFORM)

_install-apps-linux:
	@echo "Installing Linux apps..."
	@sed -n '/^\[linux\]/,/^\[/p' deps/apps.conf | sed '1d;/^\[/d' | grep -v '^#' | grep -v '^$$' | while read app; do \
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
	@sed -n '/^\[macos\]/,/^\[/p' deps/apps.conf | sed '1d;/^\[/d' | grep -v '^#' | grep -v '^$$' | while read app; do \
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
	@echo "Config dir: $(DOTFILES_DIR)"
	@echo ""
	@echo "Symlinks to create:"
	@echo "  ~/.bashrc -> $(DOTFILES_DIR)/shared/.bashrc"
	@echo "  ~/.zshrc -> $(DOTFILES_DIR)/shared/.zshrc"
	@echo "  ~/.shared.d -> $(DOTFILES_DIR)/shared/shared.d"
	@echo "  ~/.config/nvim -> $(DOTFILES_DIR)/nvim"
	@echo "  ~/.config/starship.toml -> $(DOTFILES_DIR)/shared/starship.toml"
	@echo ""
	@echo "Current state:"
	@[ -L ~/.bashrc ] && echo "  ~/.bashrc is a symlink -> $$(readlink ~/.bashrc)" || echo "  ~/.bashrc is a regular file (will be backed up)"
	@[ -L ~/.config/nvim ] && echo "  ~/.config/nvim is a symlink -> $$(readlink ~/.config/nvim)" || echo "  ~/.config/nvim is a regular dir (will be backed up)"
	@echo ""
	@echo "Apps from deps/apps.conf [$(PLATFORM)]:"
	@sed -n '/^\[$(PLATFORM)\]/,/^\[/p' deps/apps.conf 2>/dev/null | sed '1d;/^\[/d' | grep -v '^#' | grep -v '^$$' | head -10 | while read app; do \
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
	@[ -d ~/.shared.d ] && [ ! -L ~/.shared.d ] && cp -r ~/.shared.d $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -d ~/.config/nvim ] && [ ! -L ~/.config/nvim ] && cp -r ~/.config/nvim $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@[ -f ~/.config/starship.toml ] && [ ! -L ~/.config/starship.toml ] && cp ~/.config/starship.toml $(BACKUP_DIR)/$(TIMESTAMP)/ || true
	@echo "Backup complete: $(BACKUP_DIR)/$(TIMESTAMP)"
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
	[ -d "$$RESTORE_DIR/.shared.d" ] && rm -rf ~/.shared.d && cp -r "$$RESTORE_DIR/.shared.d" ~/ && echo "  Restored .shared.d"; \
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
# FONTS (Linux)
# =============================================================================
fonts:
ifeq ($(PLATFORM),linux)
	@echo "Installing Hack Nerd Font..."
	@mkdir -p $(HOME)/.local/share/fonts
	@if fc-list 2>/dev/null | grep -qi "Hack.*Nerd"; then \
		echo "Hack Nerd Font already installed"; \
	else \
		curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -o /tmp/Hack-nerd-font.zip && \
		unzip -o /tmp/Hack-nerd-font.zip -d $(HOME)/.local/share/fonts/HackNerdFont 2>/dev/null && \
		rm -f /tmp/Hack-nerd-font.zip && \
		fc-cache -fv $(HOME)/.local/share/fonts 2>/dev/null && \
		echo "Hack Nerd Font installed"; \
	fi
else
	@echo "Nerd Fonts on macOS: brew install --cask font-hack-nerd-font"
endif

# =============================================================================
# GUAKE CONFIG (Linux)
# =============================================================================
guake-config:
ifeq ($(PLATFORM),linux)
	@if command -v guake &>/dev/null; then \
		if command -v dconf &>/dev/null; then \
			echo "Applying guake configuration..."; \
			dconf load /apps/guake/ < $(DOTFILES_DIR)/settings/linux/guake.dconf && \
			echo "Guake config applied"; \
		else \
			echo "dconf not found - install with: sudo apt install dconf-cli"; \
		fi; \
	else \
		echo "guake not installed"; \
	fi
else
	@echo "guake-config is Linux only"
endif

# =============================================================================
# UNINSTALL
# =============================================================================
uninstall:
	@echo "Removing symlinks..."
	@[ -L ~/.bashrc ] && rm ~/.bashrc && echo "  Removed ~/.bashrc" || true
	@[ -L ~/.zshrc ] && rm ~/.zshrc && echo "  Removed ~/.zshrc" || true
	@[ -L ~/.shared.d ] && rm ~/.shared.d && echo "  Removed ~/.shared.d" || true
	@[ -L ~/.shellrc.d ] && rm ~/.shellrc.d && echo "  Removed ~/.shellrc.d" || true
	@[ -L ~/.bashrc.d ] && rm ~/.bashrc.d && echo "  Removed ~/.bashrc.d" || true
	@[ -L ~/.config/nvim ] && rm ~/.config/nvim && echo "  Removed ~/.config/nvim" || true
	@[ -L ~/.config/starship.toml ] && rm ~/.config/starship.toml && echo "  Removed ~/.config/starship.toml" || true
	@echo "Done. Run 'make rollback' to restore previous config."

# =============================================================================
# STARSHIP PRESET
# =============================================================================
PRESET ?= gruvbox-rainbow

starship-preset:
	@printf "$(CYAN)Installing starship preset: $(YELLOW)$(PRESET)$(RESET)\n"
	@starship preset $(PRESET) -o $(DOTFILES_DIR)/shared/starship.toml
	@printf "$(GREEN)Done!$(RESET) Theme applied to shared/starship.toml\n"
	@printf "$(DIM)Browse presets: https://starship.rs/presets/$(RESET)\n"

# =============================================================================
# CLEAN
# =============================================================================
clean:
	@rm -f *.tar.gz
	@echo "Cleaned build artifacts"

# =============================================================================
# VERSION MANAGEMENT
# =============================================================================
VERSION := $(shell grep '^VERSION=' install.sh | cut -d'"' -f2)

version:
	@echo "Current version: $(VERSION)"

patch:
	@./scripts/bump-version.sh patch

minor:
	@./scripts/bump-version.sh minor

major:
	@./scripts/bump-version.sh major

# Deploy to server
SERVER ?= tldr.icu
DEPLOY_PATH ?= /srv/dotfiles
ARCHIVE_NAME ?= master.tar.gz

deploy: archive
	@echo "Deploying v$(VERSION) to $(SERVER):$(DEPLOY_PATH)..."
	@scp install.sh latest $(ARCHIVE_NAME) root@do:$(DEPLOY_PATH)/
	@rm -f $(ARCHIVE_NAME)
	@echo "Done. Live at: https://$(SERVER)/i"

archive:
	@echo "Creating $(ARCHIVE_NAME)..."
	@mkdir -p /tmp/config-master
	@rsync -a --exclude='.git' --exclude='*.tar.gz' --exclude='.DS_Store' . /tmp/config-master/
	@tar -czf $(ARCHIVE_NAME) -C /tmp config-master
	@rm -rf /tmp/config-master
	@echo "Created $(ARCHIVE_NAME) ($(shell du -h $(ARCHIVE_NAME) | cut -f1))"
