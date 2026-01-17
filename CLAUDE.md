# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal developer environment configuration for Linux and macOS. Manages shell profiles, Neovim IDE, CLI tools, and utility scripts. Deployable via single curl command.

**Repository**: https://github.com/mainstreamer/config

## Quick Install

```bash
# One-liner (clones repo, installs everything)
curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash

# With options
curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash -s -- --minimal
curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash -s -- --no-sudo
```

## Installation Options

| Flag | Description |
|------|-------------|
| `--minimal` | Skip LSP, compilers, dev tools. Good for servers. |
| `--no-sudo` | User-space only (~/.local/bin). No root required. |
| `--deps-only` | Install packages only, skip symlinks. |
| `--stow-only` | Create symlinks only, skip packages. |
| `-h, --help` | Show full help with examples. |

## Where Configs Go

When installed via curl, the repo is cloned to `~/.dotfiles` (configurable via `DOTFILES_TARGET` env var).

**Symlinks created:**
```
~/.bashrc           → ~/.dotfiles/lx/bash/.bashrc
~/.bashrc.d/        → ~/.dotfiles/lx/bash/.bashrc.d/
~/.config/nvim/     → ~/.dotfiles/lx/nvim/
~/.config/starship.toml → ~/.dotfiles/lx/starship/starship.toml
```

**Backup:** Existing non-symlink configs are moved to `~/.dotfiles-backup-YYYYMMDD-HHMMSS/`

## Repository Structure

```
install.sh              # Main installer (curl-able, multi-distro)
Brewfile                # Homebrew dependencies (Fedora/Debian/macOS)
CLAUDE.md               # This file

lx/                     # Linux configurations
├── bash/
│   ├── .bashrc         # Main profile (sources .bashrc.d/*)
│   └── .bashrc.d/      # Modular scripts
│       ├── prompt      # Starship initialization
│       ├── shell       # Aliases and shell config
│       ├── docker      # Docker helpers
│       ├── atuin       # Shell history sync (disabled by default)
│       ├── dep.lst     # Dependency list (not sourced)
│       └── *.archived  # Deprecated scripts (not sourced)
├── nvim/
│   ├── init.lua        # Entry point (supports minimal mode)
│   └── lua/
│       ├── config/lazy.lua         # Full plugin config
│       └── config/lazy-minimal.lua # Minimal plugin config
├── starship/
│   └── starship.toml   # Cross-platform prompt config
└── composer/
    └── composer.json   # PHP global packages

mc/                     # macOS configurations
├── zsh/                # Zsh shell config
├── nvim/               # macOS nvim (if different)
└── iterm2/             # iTerm2 settings
```

## Supported Distros

| Distro | Package Manager | Notes |
|--------|-----------------|-------|
| Fedora | Homebrew | Primary dev platform |
| Debian | Homebrew | |
| Ubuntu | apt + GitHub releases | fd-find/batcat naming quirks handled |
| Pop!_OS | apt + GitHub releases | Same as Ubuntu |
| Arch | pacman + AUR | yay/paru detected automatically |
| Alpine | apk + cargo | Auto-enables --minimal |
| macOS | Homebrew | |

## Shell Configuration

### Modular .bashrc.d Pattern
`.bashrc` sources all files from `~/.bashrc.d/` except:
- Files in `EXCLUDE_FILES` array
- Files ending in `.archived`

### Prompt (Starship)
Cross-platform prompt configured in `lx/starship/starship.toml`. Shows:
- Directory, git branch/status
- Language versions (PHP, Python, Rust, Go, Node) only in relevant projects
- Command duration (if > 2s)
- Time on right side

### Atuin (Disabled by Default)
Shell history sync. To enable:
```bash
touch ~/.config/atuin/.enabled
source ~/.bashrc
atuin register  # or: atuin login
```

## Neovim Configuration

### Modes
- **Full mode**: LSP, autocompletion, language servers, all plugins
- **Minimal mode**: Basic editing, no LSP. Triggered by:
  - `NVIM_MINIMAL=1 nvim`
  - File exists: `~/.config/nvim/.minimal`

### Key Bindings
- `<Space>` - Leader key
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep
- `<C-n>` - Toggle file tree
- `ttt` - Toggle terminal
- `Tab/S-Tab` - Cycle buffers
- `gd` - Go to definition
- `gr` - Find references
- `<leader>gs/gr/gp` - Git stage/reset/preview hunk
- `<leader>tg` - Lazygit in floating terminal

### LSP Servers (Full Mode)
- PHP: phpactor
- TypeScript/JS: ts_ls + eslint
- Go: gopls
- Python: pyright
- Rust: rust-analyzer

## What Gets Installed

### Core CLI Tools (Always)
git, curl, wget, jq, fzf, ripgrep, fd, bat, eza, zoxide, tree, neovim, stow, starship, lazygit, delta, gh, htop, btop, atuin

### Development Tools (Full Mode)
- Node.js, npm, TypeScript, typescript-language-server
- PHP, Composer, phpactor, phpcs, php-cs-fixer
- Python 3, pip, pyright
- Rust (rustc, cargo, rust-analyzer, rustfmt, clippy)
- Go, gopls

## Legacy Build System

The Makefile still works for manual packaging:
```bash
make pack linux    # Archive to cfglx.tar.gz
make pack mac      # Archive to cfgmc.tar.gz
make nvim          # Install nvim config with backup
```

## Adding New bashrc.d Scripts

1. Create file in `lx/bash/.bashrc.d/` (no extension needed)
2. Add shebang: `#!/usr/bin/bash`
3. Script is auto-sourced on shell startup
4. To disable: rename to `*.archived` or add to `EXCLUDE_FILES`

## Dependencies

Listed in `lx/bash/.bashrc.d/dep.lst`, checked by `depcheck` on shell startup.
