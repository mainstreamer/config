# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal developer environment configuration for Linux and macOS. Unified cross-platform configs with smart platform detection. Deployable via single curl command or Makefile.

**Repository**: https://github.com/mainstreamer/config

## Quick Install

```bash
# Production: One-liner from GitHub
curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash

# With options
curl -fsSL ... | bash -s -- --minimal    # Lightweight, no dev tools
curl -fsSL ... | bash -s -- --no-sudo    # User-space only, no root
```

## Makefile Commands

```bash
# Production (fresh system)
make install-remote              # Curl and run from GitHub
make install-remote-minimal      # Minimal mode
make install-remote-no-sudo      # No root required

# Development (local testing)
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
make uninstall                   # Remove symlinks
make clean                       # Remove build artifacts
```

## Repository Structure (Unified)

```
config/
├── install.sh              # Main installer (curl-able)
├── Makefile                # All operations
├── Brewfile                # Homebrew packages
├── apps.conf               # Custom apps to install (editable)
├── CLAUDE.md               # This file
│
├── shell/                  # Cross-platform shell configs
│   ├── .bashrc             # Linux entry point
│   ├── .zshrc              # macOS entry point
│   └── .shellrc.d/         # Shared scripts (work in bash & zsh)
│       ├── aliases         # Common aliases
│       ├── prompt          # Starship init
│       ├── docker          # Docker helpers
│       ├── atuin           # History sync (disabled by default)
│       ├── depcheck        # Dependency checker
│       └── ...
│
├── nvim/                   # Neovim (unified, cross-platform)
│   ├── init.lua
│   └── lua/config/
│       ├── lazy.lua        # Full config
│       └── lazy-minimal.lua # Minimal config
│
├── starship/               # Starship prompt (cross-platform)
│   └── starship.toml
│
├── composer/               # PHP tools
│   └── composer.json
│
├── apps/                   # Platform-specific app configs
│   ├── linux/              # guake, etc.
│   └── macos/              # iterm2, etc.
│
└── lx/, mc/                # Legacy structure (still supported)
```

## Where Configs Are Installed

```
~/.bashrc           → repo/shell/.bashrc       (Linux)
~/.zshrc            → repo/shell/.zshrc        (macOS)
~/.shellrc.d/       → repo/shell/.shellrc.d/   (both)
~/.config/nvim/     → repo/nvim/
~/.config/starship.toml → repo/starship/starship.toml
```

**Repo location**: `~/.dotfiles` (curl install) or wherever you clone it

**Backups**: `~/.dotfiles-backups/YYYYMMDD-HHMMSS/`

## Custom Apps (apps.conf)

Edit `apps.conf` to customize which apps are installed:

```ini
[linux]
guake
feh
# vlc
# slack

[macos]
iterm2
# rectangle
# slack

[cli]
# Additional CLI tools
```

Run `make install-apps` to install apps from this file.

## Installation Options

| Flag | Description |
|------|-------------|
| `--minimal` | Skip LSP, compilers. Nvim loads minimal config. |
| `--no-sudo` | User-space only (~/.local/bin). No root. |
| `--deps-only` | Packages only, no symlinks. |
| `--stow-only` | Symlinks only, no packages. |
| `-h, --help` | Show full help. |

## Supported Platforms

| OS | Package Manager | Notes |
|----|-----------------|-------|
| Fedora | Homebrew | |
| Debian | Homebrew | |
| Ubuntu/Pop!_OS | apt + GitHub releases | |
| Arch | pacman + AUR | |
| Alpine | apk + cargo | Auto-minimal |
| macOS | Homebrew | |

## Shell Scripts

Scripts in `.shellrc.d/` are sourced by both `.bashrc` and `.zshrc`. Write POSIX-compatible shell or use `$SHELL_TYPE` variable:

```bash
# SHELL_TYPE is set to "bash" or "zsh"
if [ "$SHELL_TYPE" = "zsh" ]; then
    # zsh-specific code
fi
```

To disable a script: rename to `*.archived`

## Neovim Modes

- **Full**: LSP, autocompletion, all plugins
- **Minimal**: Basic editing. Triggered by:
  - `NVIM_MINIMAL=1 nvim`
  - File: `~/.config/nvim/.minimal`

## Key Bindings (Neovim)

- `<Space>` - Leader
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<C-n>` - File tree
- `ttt` - Terminal
- `gd` - Go to definition
- `<leader>tg` - Lazygit

## Atuin (Disabled by Default)

```bash
# Enable
touch ~/.config/atuin/.enabled
source ~/.bashrc

# Setup
atuin register  # or: atuin login
atuin import auto
```

## Development Workflow

1. Make changes locally
2. `make test` - see what would happen
3. `make install` - apply changes (auto-backup)
4. If broken: `make rollback`
5. When ready: push to GitHub
