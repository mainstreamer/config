# Architecture

## Overview

epicli-conf is a cross-platform dotfiles manager that installs CLI tools, shell configuration, and Neovim setup. It supports Fedora, Debian, Ubuntu, Pop!_OS, Arch, Alpine, and macOS.

Two installation modes:
- **Standard** (default) — no sudo required, installs CLI tools + shell config + basic Neovim
- **Dev** (`--dev`) — requires sudo, adds language runtimes, LSP servers, GUI tools, full Neovim config

## How Installation Works

The bootstrap follows a two-phase architecture:

```
curl https://tldr.icu/i | bash
  |
  v
install.sh (runs standalone, no dependencies)
  |
  |- Phase 1: Bootstrap
  |   |- parse_args()       Parse --dev, --deps-only, --stow-only
  |   |- setup_config_dir() Download repo archive to ~/.epicli-conf
  |   |- detect_os()        Identify platform and distro
  |
  |- source_libs()          Load lib/*.sh from the downloaded repo
  |
  |- Phase 2: Install (functions from lib/)
      |- install_deps()     Install CLI tools per distro
      |- setup_dev_tools()  Rust, PHP, LSPs (--dev only)
      |- link_configs()     Create symlinks for shell, nvim, starship
      |- post_install()     Sync nvim plugins
      |- save_version()     Write version file
      |- generate_manifest() Write manifest of installed tools
      |- install_cli()      Generate ~/.local/bin/epicli-conf helper
      |- print_summary()    Show next steps
```

Phase 1 code lives in `install.sh` itself because it must run before the repo is available. Phase 2 code lives in `lib/` files that are sourced after the repo is downloaded.

## Directory Map

```
install.sh              Orchestrator + bootstrap (standalone entry point)
lib/
  common.sh             Shared helpers (GitHub release installer, ensure_starship)
  deps.sh               Package installation dispatcher + per-distro installers
  deps-github.sh        GitHub release binary installer (Ubuntu/Pop!_OS path)
  devtools.sh           Dev-mode tools: Rust, PHP, fonts, guake
  links.sh              Symlink creation, backup, custom apps
  postinstall.sh        Nvim plugin sync, installation summary
  cli.sh                CLI commands: version, check, update, uninstall
  manifest.sh           Version tracking and manifest generation
deps/
  Brewfile              Standard brew packages
  Brewfile.dev          Dev-only brew packages
  apps.conf             Custom apps per platform ([linux], [macos], [cli])
  composer.json         PHP tool dependencies
  platform/
    installer.sh        Data-driven platform config engine
    generic.sh          Platform-agnostic setup (bash-completion, permissions)
    debian.sh           Debian-specific (dash/bash fix, build deps)
    ubuntu.sh           Ubuntu-specific build deps
    fedora.sh           Fedora-specific build deps
    arch.sh             Arch-specific build deps
    alpine.sh           Alpine-specific build deps
    macos.sh            macOS-specific setup
    data/*.deps         Package lists per platform
    hooks/              Pre/post install hooks
shared/
  .bashrc               Linux shell entry point
  .zshrc                macOS/Zsh entry point
  .bash_profile         SSH login shell entry
  .profile              POSIX fallback
  starship.toml         Starship prompt theme
  shared.d/             Modular shell scripts (symlinked to ~/.shared.d)
nvim/                   Neovim config (symlinked to ~/.config/nvim)
settings/               App-specific settings (guake, iterm2)
scripts/                Dev utilities (bump-version.sh, fix-treesitter.sh)
docs/                   Documentation
```

## install.sh

Contains only code needed for standalone bootstrap:

| Section | Purpose |
|---------|---------|
| Constants | PROJECT_NAME, VERSION, URLs, paths, colors |
| Logging | `info()`, `ok()`, `warn()`, `error()` |
| Utilities | `maybe_sudo()`, `check_commands_present()`, `print_install_hint()` |
| Bootstrap | `setup_config_dir()`, `run_platform_config()`, `detect_os()` |
| Args | `parse_args()`, `show_help()` |
| Loader | `source_libs()` |
| Main | `main()` — orchestration only |

## lib/ Files

| File | Responsibility | Key Functions |
|------|---------------|---------------|
| `common.sh` | Shared helpers used across modules | `ensure_local_bin()`, `ensure_starship()`, `install_from_github()` |
| `deps.sh` | CLI tool installation per distro | `install_deps()`, `install_homebrew()`, `install_brew_packages()`, `install_ubuntu_packages()`, `install_arch_packages()`, `install_alpine_packages()`, `install_linux_extras()`, `install_macos_extras()` |
| `deps-github.sh` | Binary installs from GitHub releases | `install_github_tools()` — uses `install_from_github()` for lazygit, gh, eza, delta |
| `devtools.sh` | Dev-mode only tools | `setup_dev_tools()`, `setup_rust()`, `install_php_tools()`, `install_ubuntu_dev_packages()`, `install_nerd_fonts()`, `configure_guake()` |
| `links.sh` | Filesystem setup | `link_configs()`, `link_shell()`, `link_nvim()`, `link_starship()`, `install_custom_apps()`, `backup_existing()` |
| `postinstall.sh` | Post-install tasks | `post_install()`, `print_summary()` |
| `cli.sh` | CLI commands + helper generator | `cmd_version()`, `cmd_check()`, `cmd_update()`, `cmd_force_update()`, `cmd_uninstall()`, `install_cli()` |
| `manifest.sh` | Version and manifest | `get_local_version()`, `get_remote_version()`, `save_version()`, `generate_manifest()` |

## deps/platform/ System

Separate from `lib/` — handles **base system dependencies** (build-essential, cmake, libssl-dev) and platform-specific configuration. Only runs in dev mode.

- `installer.sh` is the engine: detects package manager, reads `.deps` files, runs hooks
- Per-distro scripts handle distro-specific quirks (e.g., Debian dash-to-bash fix)
- Data files (`data/*.deps`) list packages per platform
- Hooks (`hooks/`) run pre/post installation scripts

This system is independent of the `lib/deps.sh` tool installer.

## How to Add a New Distro

1. Add detection to `detect_os()` in `install.sh`
2. Add an installer function in `lib/deps.sh` (e.g., `install_newdistro_packages()`)
3. Add the distro to the `install_deps()` case statement in `lib/deps.sh`
4. Optionally add `deps/platform/newdistro.sh` and `deps/platform/data/newdistro.deps`

## How to Add a New CLI Tool

**For all distros (brew-based):** Add to `deps/Brewfile`

**For Ubuntu/Pop!_OS (GitHub release):** Add an `install_from_github` call in `lib/deps-github.sh`

**For Arch:** Add to the `packages` variable in `install_arch_packages()` in `lib/deps.sh`

**For Alpine:** Add to the `apk_packages` variable in `install_alpine_packages()` in `lib/deps.sh`
