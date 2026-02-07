# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal developer environment configuration for Linux and macOS. Unified cross-platform configs with smart platform detection. Two modes: **standard** (default, no sudo) and **dev** (full toolchain, requires sudo).

**Repository**: https://github.com/mainstreamer/config

## Quick Install

```bash
# Standard mode (default, no sudo required)
curl -fsSL https://tldr.icu/i | bash

# Developer mode (requires sudo)
curl -fsSL https://tldr.icu/i | bash -s -- --dev
```

## Modes

| | **Standard** (default) | **Dev** (`--dev`) |
|---|---|---|
| Sudo | Not required | Required |
| CLI tools | eza, bat, zoxide, fzf, fd, rg, delta, starship, lazygit, gh, atuin | Same |
| Shell | Aliases, prompt, docker helpers, cleanup, enc/key tools | Same |
| Nvim | Treesitter, telescope, file tree, git signs, basic editing | + LSP, autocomplete, formatters, harpoon, trouble, diffview |
| Languages | None | Go, Rust, PHP, Node, Python (runtimes + LSP servers) |

## Makefile Commands

```bash
# Remote install (fresh system)
make install-remote              # Standard mode
make install-remote-dev          # Dev mode

# Local development
make install                     # Full local install (auto-backup first)
make install-deps                # Packages only, no symlinks
make install-links               # Symlinks only
make install-apps                # Install apps from apps.conf
make test                        # Dry-run, show what would happen

# Backup & Rollback
make backup                      # Create backup
make rollback                    # Restore most recent backup
make rollback DATE=20260117-143052  # Restore specific backup
make list-backups                # List available backups

# Utilities
make nvim                        # Install nvim only (with backup)
make fonts                       # Install Nerd Fonts (Linux)
make guake-config                # Apply guake config (Linux)
make uninstall                   # Remove symlinks
make clean                       # Remove build artifacts

# Versioning
make version                     # Show current version
make bump-patch                  # 2.0.0 -> 2.0.1
make bump-minor                  # 2.0.0 -> 2.1.0
make bump-major                  # 2.0.0 -> 3.0.0
make deploy                      # Deploy to tldr.icu server
```

## Repository Structure

```
config/
├── install.sh              # Main installer (curl-able via tldr.icu/i)
├── Makefile                # All operations
├── latest                  # Version file for update checking
│
├── shared/                 # Cross-platform shell environment
│   ├── .bashrc             # Linux entry point
│   ├── .zshrc              # macOS entry point
│   ├── starship.toml       # Prompt config (symlinked to ~/.config/)
│   └── shared.d/           # Shared scripts (work in bash & zsh)
│       ├── aliases         # Common aliases (eza, bat, zoxide, git)
│       ├── prompt          # Starship init
│       ├── docker          # Docker helpers
│       ├── cleanup         # Media file organizer
│       ├── where           # IP geolocation
│       ├── enc             # File encryption (AES-256)
│       ├── key             # USB key management
│       ├── hidevpn         # VPN via encrypted configs
│       ├── rec             # ffmpeg recording helpers
│       ├── atuin           # History sync (disabled by default)
│       ├── depcheck        # Dependency checker
│       ├── dep.lst         # Expected tools list
│       └── unglitch        # GDM restart alias
│
├── nvim/                   # Neovim config (symlinked to ~/.config/nvim)
│   ├── init.lua            # Entry with standard/dev mode detection
│   └── lua/config/
│       ├── lazy.lua            # Dev config (LSP, autocomplete, all plugins)
│       └── lazy-standard.lua   # Standard config (basic editing)
│
├── deps/                   # Dependency lists (what to install)
│   ├── Brewfile            # Standard Homebrew packages
│   ├── Brewfile.dev        # Dev-only Homebrew packages
│   ├── apps.conf           # Custom apps (editable)
│   └── composer.json       # PHP tools (dev)
│
├── settings/               # Platform-specific app settings
│   ├── linux/guake.dconf
│   └── macos/              # iterm2 profile + keybindings
│
└── scripts/
    └── bump-version.sh     # Version bumper
```

## Where Configs Are Installed

```
~/.bashrc               → repo/shared/.bashrc          (Linux)
~/.zshrc                → repo/shared/.zshrc           (macOS)
~/.shared.d/            → repo/shared/shared.d/        (both)
~/.config/nvim/         → repo/nvim/
~/.config/starship.toml → repo/shared/starship.toml
```

**Repo location**: `~/.epicli-conf` (curl install) or wherever you clone it

**Backups**: `~/.epicli-conf-backups/YYYYMMDD-HHMMSS/`

## Shell Scripts

Scripts in `shared.d/` are sourced by both `.bashrc` and `.zshrc`. Write POSIX-compatible shell or use `$SHELL_TYPE` variable:

```bash
if [ "$SHELL_TYPE" = "zsh" ]; then
    # zsh-specific code
fi
```

To disable a script: rename to `*.archived`

### Cleanup Function

```bash
cleanup        # Organize media files from last 1 day
cleanup 7      # From last 7 days
```

Finds video/image files >512KB, moves to `~/Documents/Cleanup/YYYY-MM-DD/` folders by creation date.

## Neovim Modes

- **Dev**: LSP, autocompletion, all plugins (default when `--dev` installed)
- **Standard**: Basic editing, no LSP. Active when:
  - `NVIM_STANDARD=1 nvim`
  - File: `~/.config/nvim/.standard` (created by standard install)

## Key Bindings (Neovim)

- `<Space>` - Leader
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<C-n>` - File tree
- `ttt` - Terminal
- `gd` - Go to definition
- `<leader>tg` - Lazygit

## Version Management

```bash
epicli-conf status    # Show installed version
epicli-conf check     # Compare with remote (tldr.icu/latest)
epicli-conf update    # Update to latest
```

## Atuin (Disabled by Default)

```bash
touch ~/.config/atuin/.enabled
source ~/.bashrc
atuin register  # or: atuin login
atuin import auto
```

## Supported Platforms

| OS | Package Manager | Notes |
|----|-----------------|-------|
| Fedora | Homebrew | |
| Debian | Homebrew | |
| Ubuntu/Pop!_OS | apt + GitHub releases | |
| Arch | pacman + AUR | |
| Alpine | apk + cargo | |
| macOS | Homebrew | |

## Development Workflow

1. Make changes locally
2. `make test` - see what would happen
3. `make install` - apply changes (auto-backup)
4. If broken: `make rollback`
5. `make bump-patch` then `make deploy` to publish
