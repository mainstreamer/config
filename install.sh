#!/usr/bin/env bash
#
# epicli-conf bootstrap script
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
PROJECT_NAME="epicli-conf"

# Config
VERSION="2.2.5"
BASE_URL="${DOTFILES_URL:-https://tldr.icu}"
ARCHIVE_URL_SELF="${BASE_URL}/master.tar.gz"
ARCHIVE_URL_GITHUB="https://github.com/mainstreamer/config/archive/refs/heads/master.tar.gz"
DOTFILES_TARGET="${DOTFILES_TARGET:-$HOME/.$PROJECT_NAME}"
VERSION_FILE="$HOME/.${PROJECT_NAME}-version"

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

# Version helpers
get_local_version() {
    [ -f "$VERSION_FILE" ] && head -1 "$VERSION_FILE" || echo "none"
}

get_remote_version() {
    curl -fsSL "$BASE_URL/latest" 2>/dev/null || echo "unknown"
}

get_install_date() {
    [ -f "$VERSION_FILE" ] && sed -n '2p' "$VERSION_FILE" || echo "never"
}

save_version() {
    echo "$VERSION" > "$VERSION_FILE"
    date +%Y-%m-%d >> "$VERSION_FILE"
}

# Run command with sudo (dev mode only)
maybe_sudo() {
    if command -v sudo &>/dev/null; then
        sudo "$@"
    else
        warn "sudo not available, skipping: $*"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Detect if running from repo or standalone (curl | bash)
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

    # Check if already cloned to target
    if [ -d "$DOTFILES_TARGET/shared" ] && [ -d "$DOTFILES_TARGET/nvim" ]; then
        DOTFILES_DIR="$DOTFILES_TARGET"
        info "Using existing config: $DOTFILES_DIR"
        return
    fi

    # Need to download the repo
    info "Downloading $PROJECT_NAME..."

    # Ensure curl is available
    if ! command -v curl &>/dev/null; then
        if command -v apt &>/dev/null; then
            maybe_sudo apt update && maybe_sudo apt install -y curl
        elif command -v dnf &>/dev/null; then
            maybe_sudo dnf install -y curl
        elif command -v pacman &>/dev/null; then
            maybe_sudo pacman -Sy --noconfirm curl
        elif command -v apk &>/dev/null; then
            maybe_sudo apk add curl
        else
            error "curl not found and cannot install it. Please install curl first."
        fi
    fi

    # Download and extract archive
    info "Trying $BASE_URL..."
    
    # Always extract to temporary directory first
    TEMP_EXTRACT=$(mktemp -d)
    if ! curl -fsSL "$ARCHIVE_URL_SELF" 2>/dev/null | tar -xz -C "$TEMP_EXTRACT" --strip-components=1 2>/dev/null; then
        info "Falling back to GitHub..."
        curl -fsSL "$ARCHIVE_URL_GITHUB" | tar -xz -C "$TEMP_EXTRACT" --strip-components=1
    fi
    
    # Backup existing configuration if present
    if [ -d "$DOTFILES_TARGET" ]; then
        info "Backing up existing configuration..."
        backup_existing
    fi
    
    # Move new configuration into place (atomic operation)
    info "Activating new configuration..."
    rm -rf "$DOTFILES_TARGET"
    mv "$TEMP_EXTRACT" "$DOTFILES_TARGET"
    DOTFILES_DIR="$DOTFILES_TARGET"
    ok "Configuration activated"
    
    # Run platform configuration after extraction
    run_platform_config
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
# Install Homebrew (Fedora, Debian, macOS)
# ------------------------------------------------------------------------------
install_homebrew() {
    if command -v brew &>/dev/null; then
        ok "Homebrew already installed"
        return
    fi

    # Homebrew requires git + gcc
    info "Installing Homebrew prerequisites..."
    case "$DISTRO" in
        fedora)
            maybe_sudo dnf install -y git gcc gcc-c++ make curl
            ;;
        debian|ubuntu|popos)
            maybe_sudo apt update && maybe_sudo apt install -y git build-essential curl
            ;;
    esac

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to path for this session
    if [ "$PLATFORM" = "linux" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Apply Linuxbrew performance optimizations
    info "Configuring Homebrew for optimal performance..."
    
    # Set parallel compilation jobs
    echo 'export HOMEBREW_MAKE_JOBS=$(nproc)' >> "$HOME/.bashrc"
    echo 'export HOMEBREW_MAKE_JOBS=$(sysctl -n hw.ncpu)' >> "$HOME/.zshrc"
    export HOMEBREW_MAKE_JOBS=$(nproc)
    
    # Prefer bottles (pre-compiled binaries) when available
    echo 'export HOMEBREW_INSTALL_FROM_API=1' >> "$HOME/.bashrc"
    echo 'export HOMEBREW_INSTALL_FROM_API=1' >> "$HOME/.zshrc"
    export HOMEBREW_INSTALL_FROM_API=1
    
    # Disable auto-update to control when updates happen
    echo 'export HOMEBREW_NO_AUTO_UPDATE=1' >> "$HOME/.bashrc"
    echo 'export HOMEBREW_NO_AUTO_UPDATE=1' >> "$HOME/.zshrc"
    export HOMEBREW_NO_AUTO_UPDATE=1
    
    # Keep builds for potential reuse (reduces recompilation)
    echo 'export HOMEBREW_NO_INSTALL_CLEANUP=1' >> "$HOME/.bashrc"
    echo 'export HOMEBREW_NO_INSTALL_CLEANUP=1' >> "$HOME/.zshrc"
    export HOMEBREW_NO_INSTALL_CLEANUP=1
    
    # Use tmpfs for build directory if sufficient RAM available (Linux only)
    if [ "$PLATFORM" = "linux" ] && [ -d /dev/shm ] && [ $(free -m | awk '/Mem:/ {print $2}') -gt 4000 ]; then
        echo '# Use tmpfs for Homebrew builds (faster I/O)' >> "$HOME/.bashrc"
        echo 'if [ -d /dev/shm ]; then' >> "$HOME/.bashrc"
        echo '    export HOMEBREW_TEMP=$(mktemp -d /dev/shm/homebrew-XXXXXX)' >> "$HOME/.bashrc"
        echo 'fi' >> "$HOME/.bashrc"
        
        echo '# Use tmpfs for Homebrew builds (faster I/O)' >> "$HOME/.zshrc"
        echo 'if [ -d /dev/shm ]; then' >> "$HOME/.zshrc"
        echo '    export HOMEBREW_TEMP=$(mktemp -d /dev/shm/homebrew-XXXXXX)' >> "$HOME/.zshrc"
        echo 'fi' >> "$HOME/.zshrc"
    fi

    ok "Homebrew installed and optimized"
}

# Platform-specific configuration
# ------------------------------------------------------------------------------
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
# Install dependencies based on distro
# ------------------------------------------------------------------------------
install_deps() {
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    case "$DISTRO" in
        fedora|debian|macos)
            install_homebrew
            install_brew_packages
            ;;
        ubuntu|popos)
            install_ubuntu_packages
            ;;
        arch)
            install_arch_packages
            ;;
        alpine)
            install_alpine_packages
            ;;
        *)
            warn "Unknown distro '$DISTRO', attempting Homebrew install"
            install_homebrew
            install_brew_packages
            ;;
    esac

    # Platform-specific extras
    if [ "$PLATFORM" = "linux" ]; then
        install_linux_extras
    else
        install_macos_extras
    fi

    ok "Dependencies installed"
}

# ------------------------------------------------------------------------------
# Homebrew-based install (Fedora, Debian, macOS)
# ------------------------------------------------------------------------------
install_brew_packages() {
    info "Installing packages from Brewfile..."
    cd "$DOTFILES_DIR"

    # Standard packages (always)
    brew bundle --file=deps/Brewfile 2>/dev/null || {
        # Fallback: install core packages individually
        brew install curl wget jq fzf ripgrep fd bat eza zoxide tree \
            neovim tmux starship lazygit delta gh htop btop atuin 2>/dev/null || true
    }

    # Dev packages (only in dev mode)
    if [ "$DEV_MODE" = true ] && [ -f "$DOTFILES_DIR/deps/Brewfile.dev" ]; then
        info "Installing dev packages from Brewfile.dev..."
        brew bundle --file=deps/Brewfile.dev 2>/dev/null || true
    fi

    # Ensure proper permissions for shared scripts
    info "Setting proper permissions for shared scripts..."
    find "$DOTFILES_DIR/shared/shared.d" -type f -exec chmod +x {} \; 2>/dev/null || true
    chmod +x "$DOTFILES_DIR/shared/.bashrc" 2>/dev/null || true
    chmod +x "$DOTFILES_DIR/shared/.zshrc" 2>/dev/null || true

    # Verify critical tools are installed
    info "Verifying critical tools..."
    
    # Starship is CRITICAL for prompt - install it first
    if ! command -v starship &>/dev/null; then
        warn "starship not found - this is required for prompt!"
        if command -v brew &>/dev/null; then
            if brew install starship; then
                ok "starship installed via brew"
            else
                error "brew failed to install starship"
                return 1
            fi
        else
            info "Installing starship via curl..."
            if curl -fsSL https://starship.rs/install.sh | sh; then
                ok "starship installed via curl"
            else
                error "Failed to install starship - this is critical!"
                return 1
            fi
        fi
    else
        ok "starship already installed"
    fi

    # Other tools
    if ! command -v eza &>/dev/null; then
        warn "eza not found, installing..."
        brew install eza 2>/dev/null || echo "Failed to install eza"
    fi

    if ! command -v bat &>/dev/null; then
        warn "bat not found, installing..."
        brew install bat 2>/dev/null || echo "Failed to install bat"
    fi

    if ! command -v zoxide &>/dev/null; then
        warn "zoxide not found, installing..."
        brew install zoxide 2>/dev/null || echo "Failed to install zoxide"
    fi
}

# ------------------------------------------------------------------------------
# Ubuntu/Pop!_OS packages (apt + GitHub releases)
# ------------------------------------------------------------------------------
install_ubuntu_packages() {
    info "Installing packages via apt..."
    maybe_sudo apt update || true

    # Core packages available in apt
    maybe_sudo apt install -y \
        git curl wget jq fzf tree htop btop \
        neovim make gcc \
        2>/dev/null || warn "Some apt packages failed"

    # fd and bat have different names on Ubuntu
    maybe_sudo apt install -y fd-find bat ripgrep 2>/dev/null || true

    # Create symlinks for fd and bat (Ubuntu uses different names)
    mkdir -p "$HOME/.local/bin"
    [ -f /usr/bin/fdfind ] && [ ! -e "$HOME/.local/bin/fd" ] && \
        ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
    [ -f /usr/bin/batcat ] && [ ! -e "$HOME/.local/bin/bat" ] && \
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

    # Install tools from GitHub releases
    install_github_tools

    if [ "$DEV_MODE" = true ]; then
        install_ubuntu_dev_packages
    fi
}

install_ubuntu_dev_packages() {
    info "Installing development packages..."
    maybe_sudo apt install -y \
        nodejs npm php php-cli composer python3 python3-pip \
        golang-go \
        2>/dev/null || warn "Some dev packages failed"

    # Language servers
    if command -v npm &>/dev/null; then
        maybe_sudo npm install -g typescript typescript-language-server 2>/dev/null || \
            npm install -g --prefix "$HOME/.local" typescript typescript-language-server 2>/dev/null || true
    fi

    if command -v pip3 &>/dev/null; then
        pip3 install --user pyright 2>/dev/null || true
    fi

    if command -v go &>/dev/null; then
        go install golang.org/x/tools/gopls@latest 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# Install tools from GitHub releases (Ubuntu/Pop!_OS)
# ------------------------------------------------------------------------------
install_github_tools() {
    local tools_dir="$HOME/.local/bin"
    mkdir -p "$tools_dir"

    # Install atuin via official script
    if ! command -v atuin &>/dev/null; then
        info "Installing atuin..."
        curl -fsSL https://setup.atuin.sh | bash 2>/dev/null || warn "Atuin install failed"
    fi

    # Install starship (CRITICAL for prompt)
    if ! command -v starship &>/dev/null; then
        info "Installing starship..."
        if curl -fsSL https://starship.rs/install.sh | sh; then
            ok "starship installed"
        else
            error "Starship install failed - this is critical for prompt!"
            return 1
        fi
    fi

    # Install zoxide
    if ! command -v zoxide &>/dev/null; then
        info "Installing zoxide..."
        curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || warn "Zoxide install failed"
    fi

    # Install lazygit
    if ! command -v lazygit &>/dev/null; then
        info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.44.1")
        curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
            mv /tmp/lazygit "$tools_dir/"
            rm /tmp/lazygit.tar.gz
        } || warn "lazygit install failed"
    fi

    # Install gh (GitHub CLI)
    if ! command -v gh &>/dev/null; then
        info "Installing GitHub CLI..."
        GH_VERSION=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "2.63.2")
        curl -fsSLo /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/gh.tar.gz -C /tmp
            mv "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" "$tools_dir/"
            rm -rf /tmp/gh*
        } || warn "gh install failed"
    fi

    # Install eza
    if ! command -v eza &>/dev/null; then
        info "Installing eza..."
        EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.18.0")
        curl -fsSLo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/eza.tar.gz -C "$tools_dir"
            rm /tmp/eza.tar.gz
        } || {
            command -v cargo &>/dev/null && cargo install eza 2>/dev/null || warn "eza install failed"
        }
    fi

    # Install delta
    if ! command -v delta &>/dev/null; then
        info "Installing delta..."
        DELTA_VERSION=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "0.18.2")
        curl -fsSLo /tmp/delta.tar.gz "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/delta.tar.gz -C /tmp
            mv "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu/delta" "$tools_dir/"
            rm -rf /tmp/delta*
        } || {
            command -v cargo &>/dev/null && cargo install git-delta 2>/dev/null || warn "delta install failed"
        }
    fi
}

# ------------------------------------------------------------------------------
# Arch Linux packages (pacman + AUR)
# ------------------------------------------------------------------------------
install_arch_packages() {
    info "Installing packages via pacman..."

    # Standard packages
    local packages="git curl wget jq fzf ripgrep fd bat eza zoxide tree \
        neovim starship lazygit git-delta github-cli htop btop atuin"

    if [ "$DEV_MODE" = true ]; then
        packages="$packages nodejs npm php composer python python-pip \
            go gopls rust rust-analyzer pyright"
    fi

    maybe_sudo pacman -Syu --noconfirm $packages 2>/dev/null || warn "Some pacman packages failed"

    # Dev-only: typescript-language-server via npm
    if [ "$DEV_MODE" = true ] && command -v npm &>/dev/null; then
        maybe_sudo npm install -g typescript typescript-language-server 2>/dev/null || \
            npm install -g --prefix "$HOME/.local" typescript typescript-language-server 2>/dev/null || true
    fi

    # Detect and use AUR helper for additional packages
    local aur_helper=""
    if command -v yay &>/dev/null; then
        aur_helper="yay"
    elif command -v paru &>/dev/null; then
        aur_helper="paru"
    fi

    if [ -n "$aur_helper" ] && [ "$DEV_MODE" = true ]; then
        info "Installing AUR packages via $aur_helper..."
        $aur_helper -S --noconfirm phpactor 2>/dev/null || warn "phpactor AUR install failed"
    fi
}

# ------------------------------------------------------------------------------
# Alpine Linux packages (apk + cargo)
# ------------------------------------------------------------------------------
install_alpine_packages() {
    info "Installing packages via apk..."

    maybe_sudo apk add --no-cache \
        git curl wget jq fzf ripgrep fd bat tree \
        neovim starship htop btop \
        build-base cargo \
        2>/dev/null || warn "Some apk packages failed"

    # Install tools via cargo
    if command -v cargo &>/dev/null; then
        info "Installing Rust-based tools via cargo..."
        cargo install eza zoxide atuin git-delta 2>/dev/null || warn "Some cargo installs failed"
    fi

    # Install lazygit from binary
    if ! command -v lazygit &>/dev/null; then
        info "Installing lazygit..."
        local tools_dir="$HOME/.local/bin"
        mkdir -p "$tools_dir"
        LAZYGIT_VERSION=$(wget -qO- https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.44.1")
        wget -qO /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && {
            tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
            mv /tmp/lazygit "$tools_dir/"
            rm /tmp/lazygit.tar.gz
        } || warn "lazygit install failed"
    fi

    # Install gh from binary
    if ! command -v gh &>/dev/null; then
        info "Installing GitHub CLI..."
        local tools_dir="$HOME/.local/bin"
        mkdir -p "$tools_dir"
        GH_VERSION=$(wget -qO- https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "2.63.2")
        wget -qO /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" && {
            tar -xzf /tmp/gh.tar.gz -C /tmp
            mv "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" "$tools_dir/"
            rm -rf /tmp/gh*
        } || warn "gh install failed"
    fi
}

# ------------------------------------------------------------------------------
# Platform-specific extras
# ------------------------------------------------------------------------------
install_linux_extras() {
    info "Installing Linux-specific packages..."

    # phpactor via composer (dev mode only)
    if [ "$DEV_MODE" = true ] && command -v composer &>/dev/null && ! command -v phpactor &>/dev/null; then
        composer global require phpactor/phpactor 2>/dev/null || warn "phpactor install failed"
    fi

    # GUI tools (dev mode has sudo)
    if [ "$DEV_MODE" = true ]; then
        case "$DISTRO" in
            fedora)
                maybe_sudo dnf install -y guake feh dconf 2>/dev/null || warn "Some dnf packages failed"
                ;;
            debian|ubuntu|popos)
                maybe_sudo apt install -y guake feh dconf-cli 2>/dev/null || warn "Some apt packages failed"
                ;;
            arch)
                maybe_sudo pacman -S --noconfirm guake feh dconf 2>/dev/null || warn "Some pacman packages failed"
                ;;
        esac

        # Install Nerd Fonts
        install_nerd_fonts

        # Apply guake configuration
        configure_guake
    fi
}

install_macos_extras() {
    info "Installing macOS-specific packages..."
    brew install --cask iterm2 2>/dev/null || true
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Install Nerd Fonts (Linux)
# ------------------------------------------------------------------------------
install_nerd_fonts() {
    local fonts_dir="$HOME/.local/share/fonts"
    local nerd_font="Hack"

    if fc-list 2>/dev/null | grep -qi "Hack.*Nerd"; then
        ok "Nerd Fonts already installed"
        return
    fi

    info "Installing $nerd_font Nerd Font..."
    mkdir -p "$fonts_dir"

    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${nerd_font}.zip"
    local tmp_zip="/tmp/${nerd_font}-nerd-font.zip"

    if curl -fsSL "$font_url" -o "$tmp_zip" 2>/dev/null; then
        unzip -o "$tmp_zip" -d "$fonts_dir/${nerd_font}NerdFont" 2>/dev/null || {
            unzip -o "$tmp_zip" -d "$fonts_dir" 2>/dev/null
        }
        rm -f "$tmp_zip"
        command -v fc-cache &>/dev/null && fc-cache -fv "$fonts_dir" 2>/dev/null || true
        ok "$nerd_font Nerd Font installed"
    else
        warn "Failed to download Nerd Font"
    fi
}

# ------------------------------------------------------------------------------
# Apply guake configuration
# ------------------------------------------------------------------------------
configure_guake() {
    command -v guake &>/dev/null || return
    command -v dconf &>/dev/null || return

    if [ -f "$DOTFILES_DIR/settings/linux/guake.dconf" ]; then
        info "Applying guake configuration..."
        dconf load /apps/guake/ < "$DOTFILES_DIR/settings/linux/guake.dconf" 2>/dev/null && \
            ok "Guake config applied" || \
            warn "Failed to apply guake config"
    fi
}

# ------------------------------------------------------------------------------
# Setup Rust toolchain (dev mode only)
# ------------------------------------------------------------------------------
setup_rust() {
    if [ "$DEV_MODE" != true ]; then
        return
    fi

    if command -v rustc &>/dev/null; then
        ok "Rust already installed"
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        return
    fi

    if command -v rustup-init &>/dev/null; then
        info "Setting up Rust toolchain..."
        rustup-init -y --no-modify-path
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        rustup component add rustfmt clippy
        ok "Rust toolchain ready"
    elif command -v rustup &>/dev/null; then
        ok "Rust already installed via rustup"
    else
        info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>/dev/null || warn "Rust install failed"
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        if command -v rustup &>/dev/null; then
            rustup component add rustfmt clippy 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# Install PHP tools via composer (dev mode only)
# ------------------------------------------------------------------------------
install_php_tools() {
    if [ "$DEV_MODE" != true ]; then
        return
    fi

    if ! command -v composer &>/dev/null; then
        warn "Composer not found, skipping PHP tools"
        return
    fi

    if ! command -v php &>/dev/null; then
        warn "PHP not found, skipping PHP tools"
        return
    fi

    info "Installing PHP tools via composer..."

    if [ -f "$DOTFILES_DIR/deps/composer.json" ]; then
        local composer_home="${COMPOSER_HOME:-$HOME/.config/composer}"
        mkdir -p "$composer_home"

        command -v phpactor &>/dev/null || \
            composer global require phpactor/phpactor 2>/dev/null || warn "phpactor install failed"

        command -v phpcs &>/dev/null || \
            composer global require squizlabs/php_codesniffer 2>/dev/null || warn "phpcs install failed"

        command -v php-cs-fixer &>/dev/null || \
            composer global require friendsofphp/php-cs-fixer 2>/dev/null || warn "php-cs-fixer install failed"
    else
        composer global require phpactor/phpactor squizlabs/php_codesniffer 2>/dev/null || warn "Some PHP tools failed"
    fi

    ok "PHP tools installed"
}

# ------------------------------------------------------------------------------
# Create symlinks
# ------------------------------------------------------------------------------
link_configs() {
    cd "$DOTFILES_DIR"

    info "Creating symlinks..."

    # Backup existing configs
    backup_existing

    # Ensure .config directory exists
    mkdir -p "$HOME/.config"

    # Link shell config
    link_shell

    # Link nvim config
    link_nvim

    # Link starship config
    link_starship

    # Install custom apps (dev mode only, needs sudo)
    if [ "$DEV_MODE" = true ]; then
        install_custom_apps
    fi

    # Set mode marker for nvim
    if [ "$DEV_MODE" != true ]; then
        touch "$HOME/.config/nvim/.standard"
        ok "Standard mode marker created"
    else
        rm -f "$HOME/.config/nvim/.standard"
    fi

    ok "Symlinks created"
}

link_shell() {
    info "Linking shell config..."

    # Clean up old symlinks (both old and new naming)
    rm -f "$HOME/.bashrc" 2>/dev/null || true
    rm -f "$HOME/.zshrc" 2>/dev/null || true
    rm -rf "$HOME/.bashrc.d" 2>/dev/null || true
    rm -rf "$HOME/.zshrc.d" 2>/dev/null || true
    rm -rf "$HOME/.shellrc.d" 2>/dev/null || true
    rm -rf "$HOME/.shared.d" 2>/dev/null || true

    if [ -d "$DOTFILES_DIR/shared" ]; then
        ln -sf "$DOTFILES_DIR/shared/shared.d" "$HOME/.shared.d"

        if [ "$PLATFORM" = "linux" ]; then
            ln -sf "$DOTFILES_DIR/shared/.bashrc" "$HOME/.bashrc"
        else
            ln -sf "$DOTFILES_DIR/shared/.zshrc" "$HOME/.zshrc"
        fi
    else
        warn "Shell config not found, skipping"
    fi
}

link_nvim() {
    info "Linking Neovim config..."

    rm -rf "$HOME/.config/nvim" 2>/dev/null || true

    if [ -d "$DOTFILES_DIR/nvim" ]; then
        ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    else
        warn "Neovim config not found, skipping"
    fi
}

link_starship() {
    info "Linking Starship config..."

    if [ -f "$DOTFILES_DIR/shared/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        rm -f "$HOME/.config/starship.toml" 2>/dev/null || true
        ln -sf "$DOTFILES_DIR/shared/starship.toml" "$HOME/.config/starship.toml"
    else
        warn "Starship config not found, skipping"
    fi
}

# ------------------------------------------------------------------------------
# Install custom apps from apps.conf
# ------------------------------------------------------------------------------
install_custom_apps() {
    local apps_conf="$DOTFILES_DIR/deps/apps.conf"
    [ -f "$apps_conf" ] || return

    info "Installing custom apps from apps.conf..."

    local section=""
    if [ "$PLATFORM" = "linux" ]; then
        section="linux"
    else
        section="macos"
    fi

    local in_section=false
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        if [[ "$line" =~ ^\[([a-z]+)\] ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$section" ]]; then
                in_section=true
            else
                in_section=false
            fi
            continue
        fi

        if [ "$in_section" = true ]; then
            local app="${line// /}"
            [ -z "$app" ] && continue

            info "Installing $app..."
            if [ "$PLATFORM" = "linux" ]; then
                if command -v dnf &>/dev/null; then
                    maybe_sudo dnf install -y "$app" 2>/dev/null || true
                elif command -v apt &>/dev/null; then
                    maybe_sudo apt install -y "$app" 2>/dev/null || true
                elif command -v pacman &>/dev/null; then
                    maybe_sudo pacman -S --noconfirm "$app" 2>/dev/null || true
                fi
            else
                brew install --cask "$app" 2>/dev/null || brew install "$app" 2>/dev/null || true
            fi
        fi
    done < "$apps_conf"
}

backup_existing() {
    local backup_dir="$HOME/.${PROJECT_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
    local needs_backup=false

    [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ] && needs_backup=true
    [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && needs_backup=true
    [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && needs_backup=true

    if [ "$needs_backup" = true ]; then
        info "Backing up existing configs to $backup_dir"
        mkdir -p "$backup_dir"

        [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$backup_dir/"
        [ -d "$HOME/.bashrc.d" ] && [ ! -L "$HOME/.bashrc.d" ] && mv "$HOME/.bashrc.d" "$backup_dir/"
        [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$backup_dir/"
        [ -d "$HOME/.zshrc.d" ] && [ ! -L "$HOME/.zshrc.d" ] && mv "$HOME/.zshrc.d" "$backup_dir/"
        [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$backup_dir/"

        ok "Backup created at $backup_dir"
    fi
}

# ------------------------------------------------------------------------------
# Post-install setup
# ------------------------------------------------------------------------------
post_install() {
    info "Running post-install tasks..."

    # Initialize zoxide
    command -v zoxide &>/dev/null && eval "$(zoxide init bash)" 2>/dev/null || true

    # Sync neovim plugins
    if command -v nvim &>/dev/null; then
        info "Syncing Neovim plugins (this may take a moment)..."
        if [ "$DEV_MODE" != true ]; then
            NVIM_STANDARD=1 nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Nvim plugin sync skipped"
        else
            nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Nvim plugin sync skipped"
        fi
    fi

    ok "Post-install complete"
}

# ------------------------------------------------------------------------------
# Print summary
# ------------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation complete! (v${VERSION})${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal (or run: source ~/.bashrc)"
    echo ""
    echo "Manage config:"
    echo "  $PROJECT_NAME status   : show installed version"
    echo "  $PROJECT_NAME check    : check for updates"
    echo "  $PROJECT_NAME update   : update to latest"
    echo "  version                : show version (shell alias)"
    echo ""
    echo "New tools to try:"
    echo "  z <dir>      : smart cd (zoxide)"
    echo "  eza -la      : modern ls"
    echo "  bat <file>   : cat with syntax highlighting"
    echo "  lazygit      : terminal git UI"
    echo "  fzf          : fuzzy finder (Ctrl+R for history)"
    echo "  cleanup [N]  : organize media files from last N days"
    echo ""

    if command -v atuin &>/dev/null; then
        echo -e "${YELLOW}Atuin installed but disabled.${NC} To enable:"
        echo "  touch ~/.config/atuin/.enabled"
        echo "  Then: atuin register / atuin login"
        echo ""
    fi

    if [ "$DEV_MODE" != true ]; then
        echo "Standard mode installed. For full dev environment:"
        echo "  curl -fsSL https://tldr.icu/i | bash -s -- --dev"
        echo ""
    fi

    # Try to activate configuration in current session
    if [ -f "$HOME/.bashrc" ]; then
        echo "Attempting to activate configuration..."
        
        # Special handling for Debian systems
        if [ "$DISTRO" = "debian" ] && [ "$(readlink /bin/sh)" = "dash" ]; then
            echo -e "${YELLOW}⚠ Debian dash detected - configuration may not fully activate${NC}"
            echo "  Please run: sudo dpkg-reconfigure dash and select 'No'"
            echo "  Then restart your terminal or run: exec bash -l"
        fi
        
        if source "$HOME/.bashrc" 2>/dev/null; then
            echo -e "${GREEN}✓ Configuration activated for this session${NC}"
            
            # Verify critical components
            echo "Verifying installation:"
            command -v starship &>/dev/null && echo "  ✓ starship prompt" || echo "  ✗ starship missing"
            command -v eza &>/dev/null && echo "  ✓ eza (modern ls)" || echo "  ✗ eza missing"
            type ll 2>/dev/null | grep -q "alias" && echo "  ✓ aliases loaded" || echo "  ✗ aliases not loaded"
            
        else
            echo -e "${YELLOW}⚠ Configuration not activated. Please run: source ~/.bashrc${NC}"
        fi
    fi
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
    ./install.sh uninstall    Remove everything

    # After install, use the '$PROJECT_NAME' CLI:
    $PROJECT_NAME status      Show installed version
    $PROJECT_NAME check       Check for updates
    $PROJECT_NAME update      Update to latest

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
# Commands: version, check, update, uninstall
# ------------------------------------------------------------------------------
cmd_uninstall() {
    echo -e "${RED}================================${NC}"
    echo -e "${RED}  $PROJECT_NAME Uninstall${NC}"
    echo -e "${RED}================================${NC}"
    echo ""
    echo "This will remove:"
    echo "  - $DOTFILES_TARGET"
    echo "  - $VERSION_FILE"
    echo "  - ~/.local/bin/$PROJECT_NAME"
    echo "  - Symlinks (~/.bashrc, ~/.config/nvim, etc.)"
    echo "  - Homebrew (/home/linuxbrew/.linuxbrew)"
    echo ""
    read -p "Are you sure? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && echo "Aborted." && exit 0

    info "Removing symlinks..."
    rm -f "$HOME/.bashrc" 2>/dev/null
    rm -f "$HOME/.zshrc" 2>/dev/null
    rm -rf "$HOME/.shared.d" 2>/dev/null
    rm -rf "$HOME/.shellrc.d" 2>/dev/null
    rm -rf "$HOME/.bashrc.d" 2>/dev/null
    rm -rf "$HOME/.config/nvim" 2>/dev/null
    rm -f "$HOME/.config/starship.toml" 2>/dev/null

    info "Removing $PROJECT_NAME..."
    rm -rf "$DOTFILES_TARGET"
    rm -f "$VERSION_FILE"
    rm -f "$HOME/.local/bin/$PROJECT_NAME"

    info "Removing Homebrew..."
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -- --force
    fi
    if [ -d "$HOME/.linuxbrew" ]; then
        rm -rf "$HOME/.linuxbrew"
    fi

    echo ""
    ok "Uninstall complete."
    echo ""
    echo "You may want to restore your original .bashrc:"
    echo "  cp /etc/skel/.bashrc ~/"
    echo ""
    echo "Then restart your shell or: exec bash"
}

cmd_version() {
    echo -e "${BLUE}$PROJECT_NAME${NC}"
    echo "  Installed: $(get_local_version)"
    echo "  Date:      $(get_install_date)"
    echo "  Location:  $DOTFILES_TARGET"
}

cmd_check() {
    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)

    echo "Installed: $local_ver"
    echo "Available: $remote_ver"

    if [ "$local_ver" = "none" ]; then
        echo -e "\n${YELLOW}Not installed.${NC} Run: curl -fsSL $BASE_URL/i | bash"
        return 1
    elif [ "$local_ver" = "$remote_ver" ]; then
        echo -e "\n${GREEN}Up to date.${NC}"
        return 0
    else
        echo -e "\n${YELLOW}Update available.${NC} Run: curl -fsSL $BASE_URL/i | bash"
        return 2
    fi
}

cmd_update() {
    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)

    if [ "$local_ver" = "$remote_ver" ]; then
        ok "Already at $local_ver"
        return 0
    fi

    info "Updating $local_ver -> $remote_ver"
    exec curl -fsSL "$BASE_URL/i" | bash
}

# ------------------------------------------------------------------------------
# Install CLI helper
# ------------------------------------------------------------------------------
install_cli() {
    local cli_path="$HOME/.local/bin/$PROJECT_NAME"
    mkdir -p "$HOME/.local/bin"

    cat > "$cli_path" << EOF
#!/usr/bin/env bash
URL="https://tldr.icu"
VER_FILE="\$HOME/.${PROJECT_NAME}-version"
DOTFILES="\${DOTFILES_TARGET:-\$HOME/.$PROJECT_NAME}"

case "\${1:-status}" in
    status|version)
        [ -f "\$VER_FILE" ] && cat "\$VER_FILE" || echo "not installed"
        ;;
    check)
        local_ver=\$(head -1 "\$VER_FILE" 2>/dev/null || echo "none")
        remote_ver=\$(curl -fsSL "\$URL/latest" 2>/dev/null || echo "?")
        echo "Installed: \$local_ver"
        echo "Available: \$remote_ver"
        [ "\$local_ver" = "\$remote_ver" ] && echo "Up to date." || echo "Run: $PROJECT_NAME update"
        ;;
    update)
        curl -fsSL "\$URL/i" | bash
        ;;
    uninstall)
        [ -f "\$DOTFILES/install.sh" ] && bash "\$DOTFILES/install.sh" uninstall || curl -fsSL "\$URL/i" | bash -s -- uninstall
        ;;
    *)
        echo "Usage: $PROJECT_NAME [status|check|update|uninstall]"
        ;;
esac
EOF

    chmod +x "$cli_path"
    ok "Installed '$PROJECT_NAME' CLI"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    # Handle commands first
    case "${1:-}" in
        version|--version|-v)
            cmd_version
            exit 0
            ;;
        check)
            cmd_check
            exit $?
            ;;
        update)
            cmd_update
            exit $?
            ;;
        uninstall)
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
    setup_config_dir
    detect_os

    if [ "$STOW_ONLY" = true ]; then
        link_configs
    elif [ "$DEPS_ONLY" = true ]; then
        install_deps
        [ "$DEV_MODE" = true ] && setup_rust
        [ "$DEV_MODE" = true ] && install_php_tools
    else
        install_deps
        [ "$DEV_MODE" = true ] && setup_rust
        [ "$DEV_MODE" = true ] && install_php_tools
        link_configs
        post_install

        save_version
        install_cli

        print_summary
    fi
}

main "$@"
