#!/usr/bin/env bash
#
# epicli bootstrap script
#
# Usage:
#   curl -fsSL https://tldr.icu/i | bash
#   curl -fsSL https://tldr.icu/i | bash -s -- --dev
#
# Or clone and run:
#   ./install.sh
#   ./install.sh --dev
#
# Supported: Fedora, Debian, Ubuntu, Pop!_OS, Arch, Alpine, macOS
#
set -e

# Project identity (change this to rename the project)
PROJECT_NAME="epicli"

# Config
VERSION="2.10.4"
BASE_URL="${DOTFILES_URL:-https://tldr.icu}"
ARCHIVE_URL_SELF="${BASE_URL}/master.tar.gz"
ARCHIVE_URL_GITHUB="https://github.com/mainstreamer/config/archive/refs/heads/master.tar.gz"
DOTFILES_TARGET="${DOTFILES_TARGET:-$HOME/.$PROJECT_NAME}"
VERSION_FILE="$HOME/.${PROJECT_NAME}-version"
MANIFEST_FILE="$HOME/.${PROJECT_NAME}-manifest"

OS="$(uname -s)"
DEV_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Prevent apt from hanging on prompts
export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Utility helpers (needed by both bootstrap and lib/ code)
# ------------------------------------------------------------------------------

# Run command with sudo (dev mode only)
maybe_sudo() {
    if command -v sudo &>/dev/null; then
        sudo "$@"
    else
        warn "sudo not available, skipping: $*"
        return 1
    fi
}

# Check if required commands are already available
# Returns: 0 if all present, 1 if some missing (outputs missing names)
check_commands_present() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "${missing[*]}"
        return 1
    fi
    return 0
}

# Print sudo install hint for missing packages (distro-aware)
print_install_hint() {
    local packages="$1"
    [ -z "$packages" ] && return
    if command -v dnf &>/dev/null; then
        warn "Install with: sudo dnf install -y $packages"
    elif command -v apt &>/dev/null; then
        warn "Install with: sudo apt install -y $packages"
    elif command -v pacman &>/dev/null; then
        warn "Install with: sudo pacman -S $packages"
    elif command -v apk &>/dev/null; then
        warn "Install with: sudo apk add $packages"
    fi
}

# ------------------------------------------------------------------------------
# Migration: clean up artifacts from old project names
# ------------------------------------------------------------------------------

migrate_old_names() {
    local old_names=("dotfiles" "epicli-conf")
    local migrated=false

    for old in "${old_names[@]}"; do
        # Remove old install directory
        if [ -d "$HOME/.$old" ]; then
            info "Removing old install: ~/.$old"
            rm -rf "$HOME/.$old"
            migrated=true
        fi

        # Remove old version/manifest files
        rm -f "$HOME/.${old}-version" 2>/dev/null
        rm -f "$HOME/.${old}-manifest" 2>/dev/null

        # Remove old CLI binary
        if [ -f "$HOME/.local/bin/$old" ]; then
            info "Removing old CLI: ~/.local/bin/$old"
            rm -f "$HOME/.local/bin/$old"
        fi

        # Remove old backups
        for d in "$HOME/.${old}-backup"*; do
            if [ -d "$d" ]; then
                info "Removing old backup: $d"
                rm -rf "$d"
            fi
        done
        rm -rf "$HOME/.${old}-backups" 2>/dev/null
    done

    if [ "$migrated" = true ]; then
        ok "Migrated from old project name to $PROJECT_NAME"
    fi
}

# ------------------------------------------------------------------------------
# Bootstrap: detect environment and download repo if needed
# (Must work standalone before lib/ files are available)
# ------------------------------------------------------------------------------

setup_config_dir() {
    local script_dir=""

    # Try to get script directory (won't work if piped)
    if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
    fi

    # Check for unified structure (shared/ and nvim/ at root)
    if [ -n "$script_dir" ] && [ -d "$script_dir/shared" ] && [ -d "$script_dir/nvim" ]; then
        DOTFILES_DIR="$script_dir"
        info "Running from repo: $DOTFILES_DIR"
        return
    fi

    # Backup existing config for fresh install
    if [ -d "$DOTFILES_TARGET" ]; then
        local backup_dir="$HOME/.${PROJECT_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
        info "Backing up existing config to $backup_dir..."
        mv "$DOTFILES_TARGET" "$backup_dir"
        ok "Backup created: $backup_dir"
        # Clear nvim cache to prevent stale module loading
        rm -rf "$HOME/.cache/nvim" "$HOME/.local/state/nvim/lazy" 2>/dev/null || true
    fi

    # Need to download the repo
    info "Downloading $PROJECT_NAME..."

    # Ensure curl is available
    if ! command -v curl &>/dev/null; then
        if [ "$DEV_MODE" = true ]; then
            if command -v apt &>/dev/null; then
                maybe_sudo apt update && maybe_sudo apt install -y curl
            elif command -v dnf &>/dev/null; then
                maybe_sudo dnf install -y curl
            elif command -v pacman &>/dev/null; then
                maybe_sudo pacman -Sy --noconfirm curl
            elif command -v apk &>/dev/null; then
                maybe_sudo apk add curl
            fi
        else
            error "curl is required but not installed."
            print_install_hint "curl"
            return 1
        fi
    fi

    # Download and extract archive
    info "Trying $BASE_URL..."

    # Always extract to temporary directory first
    TEMP_EXTRACT=$(mktemp -d)

    # Download from primary source
    if ! curl -fsSL "$ARCHIVE_URL_SELF" 2>/dev/null | tar -xz -C "$TEMP_EXTRACT" --strip-components=1 2>/dev/null; then
        info "Falling back to GitHub..."
        if ! curl -fsSL "$ARCHIVE_URL_GITHUB" | tar -xz -C "$TEMP_EXTRACT" --strip-components=1; then
            error "Failed to download configuration archive from both sources!"
            error "Please check your internet connection and try again."
            return 1
        fi
    fi

    # Verify download was successful
    if [ ! -d "$TEMP_EXTRACT/shared" ] || [ ! -d "$TEMP_EXTRACT/nvim" ]; then
        error "Downloaded archive is corrupted or incomplete!"
        error "Expected 'shared' and 'nvim' directories not found."
        return 1
    fi

    # Check for critical files that must exist
    local missing_files=0
    local critical_files=(
        "$TEMP_EXTRACT/shared/.bashrc"
        "$TEMP_EXTRACT/shared/.bash_profile"
        "$TEMP_EXTRACT/shared/.profile"
        "$TEMP_EXTRACT/shared/.zshrc"
        "$TEMP_EXTRACT/shared/shared.d/aliases"
        "$TEMP_EXTRACT/shared/starship.toml"
    )

    for file in "${critical_files[@]}"; do
        if [ ! -f "$file" ]; then
            error "Critical file missing: $file"
            missing_files=$((missing_files + 1))
        fi
    done

    if [ $missing_files -gt 0 ]; then
        error "Archive is incomplete! $missing_files critical files missing."
        error "Please try again or check your internet connection."
        return 1
    fi

    ok "Configuration archive downloaded and verified successfully"

    # Backup existing configuration if present
    if [ -d "$DOTFILES_TARGET" ]; then
        info "Backing up existing configuration..."
        backup_existing
    fi

    # Move new configuration into place (atomic operation)
    info "Activating new configuration..."

    # Self-healing: Ensure target directory is completely removed
    if [ -d "$DOTFILES_TARGET" ]; then
        info "Removing old configuration..."
        rm -rf "$DOTFILES_TARGET" || {
            error "Failed to remove old configuration!"
            error "Please manually remove: $DOTFILES_TARGET"
            return 1
        }
    fi

    # Move new configuration
    mv "$TEMP_EXTRACT" "$DOTFILES_TARGET" || {
        error "Failed to move new configuration!"
        error "Please check permissions and try again."
        return 1
    }

    # Verify the move was successful
    if [ ! -d "$DOTFILES_TARGET" ]; then
        error "Configuration move failed! Target directory not found."
        error "Please check disk space and permissions."
        return 1
    fi

    DOTFILES_DIR="$DOTFILES_TARGET"
    ok "Configuration activated successfully"

    # Run platform configuration after extraction (dev mode only - needs sudo)
    if [ "$DEV_MODE" = true ]; then
        run_platform_config
    fi
}

# Platform-specific configuration (delegates to deps/platform/)
run_platform_config() {
    local platform_installer="$DOTFILES_DIR/deps/platform/installer.sh"

    if [ ! -f "$platform_installer" ]; then
        warn "Platform installer script not found: $platform_installer"
        return 1
    fi

    info "Running platform configuration for $DISTRO..."

    # Run the platform installation driver
    if source "$platform_installer" "$DISTRO"; then
        ok "Platform configuration completed for $DISTRO"
        return 0
    else
        warn "Failed to complete platform configuration for $DISTRO"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Detect OS and Distro
# ------------------------------------------------------------------------------

detect_os() {
    case "$OS" in
        Linux*)
            PLATFORM="linux"
            if [ -f /etc/alpine-release ]; then
                DISTRO="alpine"
            elif [ -f /etc/pop-os/os-release ]; then
                DISTRO="popos"
            elif [ -f /etc/arch-release ]; then
                DISTRO="arch"
            elif [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release 2>/dev/null; then
                DISTRO="ubuntu"
            elif [ -f /etc/fedora-release ]; then
                DISTRO="fedora"
            elif [ -f /etc/debian_version ]; then
                DISTRO="debian"
            else
                DISTRO="unknown"
            fi
            ;;
        Darwin*)
            PLATFORM="macos"
            DISTRO="macos"
            ;;
        *)
            error "Unsupported OS: $OS"
            ;;
    esac

    local mode_str="standard"
    [ "$DEV_MODE" = true ] && mode_str="dev"
    info "Detected: $PLATFORM ($DISTRO) [$mode_str]"
}

# ------------------------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------------------------

parse_args() {
    DEPS_ONLY=false
    STOW_ONLY=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dev)
                DEV_MODE=true
                shift
                ;;
            --deps-only)
                DEPS_ONLY=true
                shift
                ;;
            --stow-only)
                STOW_ONLY=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                shift
                ;;
        esac
    done
}

show_help() {
    cat <<EOF
$PROJECT_NAME Bootstrap Script
==========================

QUICK INSTALL:
    curl -fsSL https://tldr.icu/i | bash
    curl -fsSL https://tldr.icu/i | bash -s -- --dev

COMMANDS:
    ./install.sh              Install (standard mode, no sudo required)
    ./install.sh --dev        Full developer environment (requires sudo)
    ./install.sh version      Show installed version
    ./install.sh check        Check for updates
    ./install.sh update       Update to latest version
    ./install.sh force-update Force fresh installation (bypass version check)
    ./install.sh uninstall    Remove everything

    # After install, use the '$PROJECT_NAME' CLI:
    $PROJECT_NAME status      Show installed version
    $PROJECT_NAME check       Check for updates
    $PROJECT_NAME update      Update to latest version
    $PROJECT_NAME force-update Force fresh installation

OPTIONS:
  --dev         Full developer environment (requires sudo)
                - Everything in standard mode PLUS:
                - Language runtimes: Go, Rust, PHP, Node, Python
                - LSP servers: gopls, rust-analyzer, pyright, phpactor, ts_ls
                - Nvim dev config: autocompletion, LSP, formatters
                - GUI tools: guake, feh, Nerd Fonts

  --deps-only   Install packages only, skip symlink creation

  --stow-only   Create symlinks only, skip package installation

  --help, -h    Show this help message

MODES:
  Standard (default):
    - No sudo required
    - CLI tools: nvim, fzf, rg, fd, bat, eza, zoxide, starship,
                 lazygit, delta, gh, htop, btop, atuin, tree
    - Shell aliases, prompt, docker helpers
    - Nvim with basic editing plugins (no LSP)

  Dev (--dev):
    - Requires sudo
    - Everything in standard mode plus full dev toolchain
    - Language servers and Nvim autocompletion

SUPPORTED PLATFORMS:
  Fedora        Homebrew
  Debian        Homebrew
  Ubuntu        apt + GitHub releases
  Pop!_OS       apt + GitHub releases
  Arch          pacman + AUR
  Alpine        apk + cargo
  macOS         Homebrew

EOF
}

# ------------------------------------------------------------------------------
# Source library modules (available after repo is on disk)
# ------------------------------------------------------------------------------

source_libs() {
    local lib_dir=""

    # When running from repo (DOTFILES_DIR set by setup_config_dir)
    if [ -n "${DOTFILES_DIR:-}" ] && [ -d "$DOTFILES_DIR/lib" ]; then
        lib_dir="$DOTFILES_DIR/lib"
    # When running CLI commands before setup_config_dir (repo already installed)
    elif [ -d "$DOTFILES_TARGET/lib" ]; then
        lib_dir="$DOTFILES_TARGET/lib"
        DOTFILES_DIR="$DOTFILES_TARGET"
    # Fallback: script directory
    elif [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
        if [ -n "$script_dir" ] && [ -d "$script_dir/lib" ]; then
            lib_dir="$script_dir/lib"
        fi
    fi

    if [ -z "$lib_dir" ] || [ ! -d "$lib_dir" ]; then
        error "Library directory not found. Is $PROJECT_NAME installed?"
    fi

    for f in "$lib_dir"/*.sh; do
        [ -f "$f" ] && source "$f"
    done
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
    # Handle CLI commands first (repo must already be installed)
    case "${1:-}" in
        version|--version|-v)
            source_libs
            cmd_version
            exit 0
            ;;
        check)
            source_libs
            cmd_check
            exit $?
            ;;
        update)
            source_libs
            cmd_update
            exit $?
            ;;
        force-update|--force)
            source_libs
            cmd_force_update
            exit $?
            ;;
        uninstall)
            source_libs
            cmd_uninstall
            exit $?
            ;;
    esac

    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $PROJECT_NAME Bootstrap${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""

    parse_args "$@"
    migrate_old_names
    setup_config_dir
    detect_os

    # Load library modules (repo now on disk)
    source_libs

    if [ "$STOW_ONLY" = true ]; then
        link_configs
    elif [ "$DEPS_ONLY" = true ]; then
        install_deps
        [ "$DEV_MODE" = true ] && setup_dev_tools
    else
        install_deps
        [ "$DEV_MODE" = true ] && setup_dev_tools
        link_configs
        post_install
        save_version
        generate_manifest
        install_cli
        print_summary
    fi
}

main "$@"
