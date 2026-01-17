#!/usr/bin/env bash
#
# Bootstrap script for dotfiles
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/master/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/master/install.sh | bash -s -- --minimal
#
# Or clone and run:
#   git clone https://github.com/YOUR_USER/dotfiles.git && cd dotfiles && ./install.sh
#
# Supported distros: Fedora, Debian, Ubuntu, Pop!_OS, Arch, Alpine, macOS
#
set -e

# Config
REPO_URL="${DOTFILES_REPO:-https://github.com/mainstreamer/config.git}"
DOTFILES_TARGET="${DOTFILES_TARGET:-$HOME/.dotfiles}"

OS="$(uname -s)"
MINIMAL_MODE=false
NO_SUDO=false

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

# Run command with sudo if available and allowed
maybe_sudo() {
    if [ "$NO_SUDO" = true ]; then
        warn "Skipping (no-sudo mode): sudo $*"
        return 1
    elif command -v sudo &>/dev/null; then
        sudo "$@"
    else
        warn "sudo not available, skipping: $*"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Detect if running from repo or standalone (curl | bash)
# ------------------------------------------------------------------------------
setup_dotfiles_dir() {
    # Check if we're in a repo with the expected structure
    local script_dir=""

    # Try to get script directory (won't work if piped)
    if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || true
    fi

    # Check for new unified structure (shell/ and nvim/ at root)
    if [ -n "$script_dir" ] && [ -d "$script_dir/shell" ] && [ -d "$script_dir/nvim" ]; then
        DOTFILES_DIR="$script_dir"
        info "Running from repo: $DOTFILES_DIR"
        return
    fi

    # Check for legacy structure (lx/bash, lx/nvim)
    if [ -n "$script_dir" ] && [ -d "$script_dir/lx/bash" ] && [ -d "$script_dir/lx/nvim" ]; then
        DOTFILES_DIR="$script_dir"
        USE_LEGACY_STRUCTURE=true
        info "Running from repo (legacy structure): $DOTFILES_DIR"
        return
    fi

    # Check if already cloned to target (new structure)
    if [ -d "$DOTFILES_TARGET/shell" ] && [ -d "$DOTFILES_TARGET/nvim" ]; then
        DOTFILES_DIR="$DOTFILES_TARGET"
        info "Using existing dotfiles: $DOTFILES_DIR"
        return
    fi

    # Check if already cloned to target (legacy structure)
    if [ -d "$DOTFILES_TARGET/lx/bash" ] && [ -d "$DOTFILES_TARGET/lx/nvim" ]; then
        DOTFILES_DIR="$DOTFILES_TARGET"
        USE_LEGACY_STRUCTURE=true
        info "Using existing dotfiles (legacy): $DOTFILES_DIR"
        return
    fi

    # Need to clone the repo
    info "Cloning dotfiles repository..."

    if ! command -v git &>/dev/null; then
        # Try to install git first
        if command -v apt &>/dev/null; then
            maybe_sudo apt update && maybe_sudo apt install -y git
        elif command -v dnf &>/dev/null; then
            maybe_sudo dnf install -y git
        elif command -v pacman &>/dev/null; then
            maybe_sudo pacman -Sy --noconfirm git
        elif command -v apk &>/dev/null; then
            maybe_sudo apk add git
        elif command -v brew &>/dev/null; then
            brew install git
        else
            error "git not found and cannot install it. Please install git first."
        fi
    fi

    git clone "$REPO_URL" "$DOTFILES_TARGET"
    DOTFILES_DIR="$DOTFILES_TARGET"
    ok "Cloned to $DOTFILES_DIR"
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
                # Alpine defaults to minimal mode
                MINIMAL_MODE=true
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

    local mode_str=""
    [ "$MINIMAL_MODE" = true ] && mode_str=" [minimal]"
    info "Detected: $PLATFORM ($DISTRO)$mode_str"
}

# ------------------------------------------------------------------------------
# Install Homebrew (Fedora, Debian, macOS)
# ------------------------------------------------------------------------------
install_homebrew() {
    if command -v brew &>/dev/null; then
        ok "Homebrew already installed"
        return
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to path for this session
    if [ "$PLATFORM" = "linux" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    else
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    ok "Homebrew installed"
}

# ------------------------------------------------------------------------------
# Install dependencies based on distro
# ------------------------------------------------------------------------------
install_deps() {
    # Ensure ~/.local/bin exists and is in PATH
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    if [ "$NO_SUDO" = true ]; then
        info "Running in no-sudo mode (user-space only)"
        install_userspace_packages
    else
        case "$DISTRO" in
            fedora|debian|macos)
                install_homebrew
                install_brew_deps
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
                install_brew_deps
                ;;
        esac

        # Platform-specific extras
        if [ "$PLATFORM" = "linux" ]; then
            install_linux_extras
        else
            install_macos_extras
        fi
    fi

    ok "Dependencies installed"
}

# ------------------------------------------------------------------------------
# User-space only install (no sudo required)
# ------------------------------------------------------------------------------
install_userspace_packages() {
    local tools_dir="$HOME/.local/bin"
    mkdir -p "$tools_dir"

    info "Installing tools to ~/.local/bin (no sudo)..."

    # Install Rust if not present (needed for cargo installs)
    if ! command -v cargo &>/dev/null; then
        info "Installing Rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>/dev/null || {
            warn "Rust install failed - some tools will be unavailable"
        }
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
    fi

    # Install cargo-based tools
    if command -v cargo &>/dev/null; then
        info "Installing Rust-based CLI tools via cargo..."
        local cargo_packages="eza zoxide bat fd-find ripgrep git-delta atuin"
        if [ "$MINIMAL_MODE" = false ]; then
            cargo_packages="$cargo_packages stylua"
        fi
        for pkg in $cargo_packages; do
            cargo install "$pkg" 2>/dev/null || warn "cargo install $pkg failed"
        done
    fi

    # Install starship
    if ! command -v starship &>/dev/null; then
        info "Installing starship..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$tools_dir" 2>/dev/null || warn "Starship install failed"
    fi

    # Install fzf
    if ! command -v fzf &>/dev/null; then
        info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null && \
            "$HOME/.fzf/install" --bin --no-update-rc --no-completion 2>/dev/null && \
            ln -sf "$HOME/.fzf/bin/fzf" "$tools_dir/fzf" || warn "fzf install failed"
    fi

    # Install lazygit
    if ! command -v lazygit &>/dev/null; then
        info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.40.2")
        curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
            mv /tmp/lazygit "$tools_dir/"
            rm /tmp/lazygit.tar.gz
        } || warn "lazygit install failed"
    fi

    # Install neovim (appimage for Linux, prebuilt for others)
    if ! command -v nvim &>/dev/null; then
        info "Installing neovim..."
        if [ "$PLATFORM" = "linux" ]; then
            curl -fsSLo "$tools_dir/nvim" "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage" 2>/dev/null && \
                chmod +x "$tools_dir/nvim" || warn "Neovim install failed"
        fi
    fi

    # Install stow (perl script, can run without sudo)
    if ! command -v stow &>/dev/null; then
        info "Installing stow..."
        local stow_version="2.4.0"
        curl -fsSL "https://ftp.gnu.org/gnu/stow/stow-${stow_version}.tar.gz" -o /tmp/stow.tar.gz 2>/dev/null && {
            tar -xzf /tmp/stow.tar.gz -C /tmp
            cd /tmp/stow-${stow_version}
            ./configure --prefix="$HOME/.local" 2>/dev/null && make install 2>/dev/null
            cd "$DOTFILES_DIR"
            rm -rf /tmp/stow*
        } || warn "Stow install failed (may need perl)"
    fi

    # Install gh (GitHub CLI)
    if ! command -v gh &>/dev/null; then
        info "Installing GitHub CLI..."
        GH_VERSION=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "2.40.0")
        curl -fsSLo /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/gh.tar.gz -C /tmp
            mv /tmp/gh_${GH_VERSION}_linux_amd64/bin/gh "$tools_dir/"
            rm -rf /tmp/gh*
        } || warn "gh install failed"
    fi

    ok "User-space tools installed to ~/.local/bin"
    echo ""
    warn "Add to your PATH if not already: export PATH=\"\$HOME/.local/bin:\$HOME/.cargo/bin:\$PATH\""
}

# ------------------------------------------------------------------------------
# Homebrew-based install (Fedora, Debian, macOS)
# ------------------------------------------------------------------------------
install_brew_deps() {
    info "Installing dependencies from Brewfile..."
    cd "$DOTFILES_DIR"

    if [ "$MINIMAL_MODE" = true ]; then
        # Install only core packages for minimal mode
        brew install git curl wget jq fzf ripgrep fd bat eza zoxide tree \
            neovim stow starship lazygit delta gh htop btop atuin 2>/dev/null || true
    else
        brew bundle
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
        neovim stow make gcc \
        2>/dev/null || warn "Some apt packages failed"

    # fd and bat have different names on Ubuntu
    maybe_sudo apt install -y fd-find bat ripgrep 2>/dev/null || true

    # Create symlinks for fd and bat (Ubuntu uses different names)
    mkdir -p "$HOME/.local/bin"
    [ -f /usr/bin/fdfind ] && [ ! -e "$HOME/.local/bin/fd" ] && \
        ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
    [ -f /usr/bin/batcat ] && [ ! -e "$HOME/.local/bin/bat" ] && \
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

    # Install tools from GitHub releases or cargo
    install_github_tools

    if [ "$MINIMAL_MODE" = false ]; then
        install_ubuntu_dev_packages
    fi
}

install_ubuntu_dev_packages() {
    info "Installing development packages..."
    maybe_sudo apt install -y \
        nodejs npm php php-cli composer python3 python3-pip \
        golang-go \
        2>/dev/null || warn "Some dev packages failed"

    # Language servers need manual install
    if command -v npm &>/dev/null; then
        maybe_sudo npm install -g typescript typescript-language-server 2>/dev/null || \
            npm install -g --prefix "$HOME/.local" typescript typescript-language-server 2>/dev/null || true
    fi

    # Python LSP
    if command -v pip3 &>/dev/null; then
        pip3 install --user pyright 2>/dev/null || true
    fi

    # Go LSP
    if command -v go &>/dev/null; then
        go install golang.org/x/tools/gopls@latest 2>/dev/null || true
    fi
}

install_github_tools() {
    local tools_dir="$HOME/.local/bin"
    mkdir -p "$tools_dir"

    # Install atuin via official script
    if ! command -v atuin &>/dev/null; then
        info "Installing atuin..."
        curl -fsSL https://setup.atuin.sh | bash 2>/dev/null || warn "Atuin install failed"
    fi

    # Install starship
    if ! command -v starship &>/dev/null; then
        info "Installing starship..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y 2>/dev/null || warn "Starship install failed"
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

    # Install eza (try binary first, fall back to cargo)
    if ! command -v eza &>/dev/null; then
        info "Installing eza..."
        EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.18.0")
        curl -fsSLo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/eza.tar.gz -C "$tools_dir"
            rm /tmp/eza.tar.gz
        } || {
            # Fallback to cargo
            command -v cargo &>/dev/null && cargo install eza 2>/dev/null || warn "eza install failed"
        }
    fi

    # Install delta (try binary first, fall back to cargo)
    if ! command -v delta &>/dev/null; then
        info "Installing delta..."
        DELTA_VERSION=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "0.18.2")
        curl -fsSLo /tmp/delta.tar.gz "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" 2>/dev/null && {
            tar -xzf /tmp/delta.tar.gz -C /tmp
            mv "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu/delta" "$tools_dir/"
            rm -rf /tmp/delta*
        } || {
            # Fallback to cargo
            command -v cargo &>/dev/null && cargo install git-delta 2>/dev/null || warn "delta install failed"
        }
    fi
}

# ------------------------------------------------------------------------------
# Arch Linux packages (pacman + AUR)
# ------------------------------------------------------------------------------
install_arch_packages() {
    info "Installing packages via pacman..."

    # Core packages
    local packages="git curl wget jq fzf ripgrep fd bat eza zoxide tree \
        neovim stow starship lazygit git-delta github-cli htop btop atuin"

    if [ "$MINIMAL_MODE" = false ]; then
        packages="$packages nodejs npm php composer python python-pip \
            go gopls rust rust-analyzer pyright"
    fi

    maybe_sudo pacman -Syu --noconfirm $packages 2>/dev/null || warn "Some pacman packages failed"

    # Install typescript-language-server via npm
    if [ "$MINIMAL_MODE" = false ] && command -v npm &>/dev/null; then
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

    if [ -n "$aur_helper" ] && [ "$MINIMAL_MODE" = false ]; then
        info "Installing AUR packages via $aur_helper..."
        $aur_helper -S --noconfirm phpactor 2>/dev/null || warn "phpactor AUR install failed"
    fi
}

# ------------------------------------------------------------------------------
# Alpine Linux packages (apk + cargo)
# ------------------------------------------------------------------------------
install_alpine_packages() {
    info "Installing packages via apk..."

    # Core packages
    maybe_sudo apk add --no-cache \
        git curl wget jq fzf ripgrep fd bat tree \
        neovim stow starship htop btop \
        build-base cargo \
        2>/dev/null || warn "Some apk packages failed"

    # Install tools via cargo (eza, zoxide, atuin)
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

    # phpactor via composer (not in most package managers)
    if [ "$MINIMAL_MODE" = false ] && command -v composer &>/dev/null && ! command -v phpactor &>/dev/null; then
        composer global require phpactor/phpactor 2>/dev/null || warn "phpactor install failed"
    fi

    # Distro-specific GUI tools (skip in no-sudo mode)
    if [ "$NO_SUDO" = false ]; then
        case "$DISTRO" in
            fedora)
                maybe_sudo dnf install -y guake feh 2>/dev/null || warn "Some dnf packages failed"
                ;;
            debian|ubuntu|popos)
                maybe_sudo apt install -y guake feh 2>/dev/null || warn "Some apt packages failed"
                ;;
            arch)
                maybe_sudo pacman -S --noconfirm guake feh 2>/dev/null || warn "Some pacman packages failed"
                ;;
        esac
    fi
}

install_macos_extras() {
    info "Installing macOS-specific packages..."

    # Install casks
    brew install --cask iterm2 2>/dev/null || true
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Setup Rust toolchain
# ------------------------------------------------------------------------------
setup_rust() {
    if [ "$MINIMAL_MODE" = true ]; then
        ok "Skipping Rust setup (minimal mode)"
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
        # Install rustup (no sudo needed - installs to ~/.cargo)
        info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>/dev/null || warn "Rust install failed"
        [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
        if command -v rustup &>/dev/null; then
            rustup component add rustfmt clippy 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# Install PHP tools via composer
# ------------------------------------------------------------------------------
install_php_tools() {
    if [ "$MINIMAL_MODE" = true ]; then
        ok "Skipping PHP tools (minimal mode)"
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

    # Use composer.json from repo if available
    if [ -f "$DOTFILES_DIR/lx/composer/composer.json" ]; then
        # Merge with existing global composer.json or use ours
        local composer_home="${COMPOSER_HOME:-$HOME/.config/composer}"
        mkdir -p "$composer_home"

        # Install phpactor
        if ! command -v phpactor &>/dev/null; then
            composer global require phpactor/phpactor 2>/dev/null || warn "phpactor install failed"
        else
            ok "phpactor already installed"
        fi

        # Install phpcs
        if ! command -v phpcs &>/dev/null; then
            composer global require squizlabs/php_codesniffer 2>/dev/null || warn "phpcs install failed"
        else
            ok "phpcs already installed"
        fi

        # Install php-cs-fixer
        if ! command -v php-cs-fixer &>/dev/null; then
            composer global require friendsofphp/php-cs-fixer 2>/dev/null || warn "php-cs-fixer install failed"
        else
            ok "php-cs-fixer already installed"
        fi
    else
        # Fallback: install common PHP tools
        composer global require phpactor/phpactor squizlabs/php_codesniffer 2>/dev/null || warn "Some PHP tools failed"
    fi

    # Ensure composer bin is in PATH hint
    local composer_bin="$HOME/.config/composer/vendor/bin"
    [ -d "$HOME/.composer/vendor/bin" ] && composer_bin="$HOME/.composer/vendor/bin"

    if [[ ":$PATH:" != *":$composer_bin:"* ]]; then
        warn "Add to PATH: export PATH=\"\$PATH:$composer_bin\""
    fi

    ok "PHP tools installed"
}

# ------------------------------------------------------------------------------
# Stow packages
# ------------------------------------------------------------------------------
stow_packages() {
    if ! command -v stow &>/dev/null; then
        error "GNU Stow not installed. Run with --deps-only first."
    fi

    cd "$DOTFILES_DIR"

    info "Creating symlinks with stow..."

    # Backup existing configs
    backup_existing

    # Ensure .config directory exists
    mkdir -p "$HOME/.config"

    # Stow shell config based on platform
    stow_shell

    # Stow nvim config
    stow_nvim

    # Stow starship config
    stow_starship

    # Install custom apps
    install_custom_apps

    # Set minimal mode marker if needed
    if [ "$MINIMAL_MODE" = true ]; then
        touch "$HOME/.config/nvim/.minimal"
        ok "Minimal mode marker created"
    fi

    ok "Symlinks created"
}

stow_shell() {
    info "Stowing shell config..."

    # Clean up old symlinks
    rm -f "$HOME/.bashrc" 2>/dev/null || true
    rm -f "$HOME/.zshrc" 2>/dev/null || true
    rm -rf "$HOME/.bashrc.d" 2>/dev/null || true
    rm -rf "$HOME/.zshrc.d" 2>/dev/null || true
    rm -rf "$HOME/.shellrc.d" 2>/dev/null || true

    # New unified structure: shell/
    if [ -d "$DOTFILES_DIR/shell" ]; then
        ln -sf "$DOTFILES_DIR/shell/.shellrc.d" "$HOME/.shellrc.d"

        if [ "$PLATFORM" = "linux" ]; then
            ln -sf "$DOTFILES_DIR/shell/.bashrc" "$HOME/.bashrc"
        else
            ln -sf "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
        fi
    # Legacy structure: lx/bash, mc/zsh
    elif [ "$PLATFORM" = "linux" ] && [ -d "$DOTFILES_DIR/lx/bash" ]; then
        cd "$DOTFILES_DIR/lx/bash"
        stow -v -t "$HOME" -R . 2>&1 | grep -v "^LINK:" || true
        cd "$DOTFILES_DIR"
    elif [ -d "$DOTFILES_DIR/mc/zsh" ]; then
        cd "$DOTFILES_DIR/mc/zsh"
        stow -v -t "$HOME" -R . 2>&1 | grep -v "^LINK:" || true
        cd "$DOTFILES_DIR"
    else
        warn "Shell config not found, skipping"
    fi
}

stow_nvim() {
    info "Stowing Neovim config..."

    rm -rf "$HOME/.config/nvim" 2>/dev/null || true

    # New unified structure: nvim/ at root
    if [ -d "$DOTFILES_DIR/nvim" ]; then
        ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    # Legacy structure: lx/nvim or mc/nvim
    elif [ -d "$DOTFILES_DIR/lx/nvim" ]; then
        ln -sf "$DOTFILES_DIR/lx/nvim" "$HOME/.config/nvim"
    elif [ -d "$DOTFILES_DIR/mc/nvim" ]; then
        ln -sf "$DOTFILES_DIR/mc/nvim" "$HOME/.config/nvim"
    else
        warn "Neovim config not found, skipping"
    fi
}

stow_starship() {
    info "Stowing Starship config..."

    local starship_config=""

    # New unified structure: starship/ at root
    if [ -f "$DOTFILES_DIR/starship/starship.toml" ]; then
        starship_config="$DOTFILES_DIR/starship/starship.toml"
    # Legacy structure
    elif [ -f "$DOTFILES_DIR/lx/starship/starship.toml" ]; then
        starship_config="$DOTFILES_DIR/lx/starship/starship.toml"
    fi

    if [ -n "$starship_config" ]; then
        mkdir -p "$HOME/.config"
        rm -f "$HOME/.config/starship.toml" 2>/dev/null || true
        ln -sf "$starship_config" "$HOME/.config/starship.toml"
    else
        warn "Starship config not found, skipping"
    fi
}

# ------------------------------------------------------------------------------
# Install custom apps from apps.conf
# ------------------------------------------------------------------------------
install_custom_apps() {
    local apps_conf="$DOTFILES_DIR/apps.conf"

    if [ ! -f "$apps_conf" ]; then
        return
    fi

    info "Installing custom apps from apps.conf..."

    local section=""
    if [ "$PLATFORM" = "linux" ]; then
        section="linux"
    else
        section="macos"
    fi

    # Parse apps.conf and install apps for current platform
    local in_section=false
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Check for section headers
        if [[ "$line" =~ ^\[([a-z]+)\] ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$section" ]]; then
                in_section=true
            else
                in_section=false
            fi
            continue
        fi

        # Install apps in our section
        if [ "$in_section" = true ]; then
            local app="${line// /}"  # trim whitespace
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
                # macOS - try cask first, then regular formula
                brew install --cask "$app" 2>/dev/null || brew install "$app" 2>/dev/null || true
            fi
        fi
    done < "$apps_conf"
}

backup_existing() {
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    local needs_backup=false

    # Check what needs backing up
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

    # Note: atuin is installed but disabled by default
    # Enable with: touch ~/.config/atuin/.enabled

    # Sync neovim plugins
    if command -v nvim &>/dev/null; then
        info "Syncing Neovim plugins (this may take a moment)..."
        if [ "$MINIMAL_MODE" = true ]; then
            NVIM_MINIMAL=1 nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Nvim plugin sync skipped"
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
    echo -e "${GREEN}  Installation complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal (or run: source ~/.bashrc)"
    echo "  2. Install a Nerd Font if you haven't: https://www.nerdfonts.com/"
    echo ""
    echo "New tools to try:"
    echo "  - z <dir>      : smart cd (zoxide)"
    echo "  - eza -la      : modern ls"
    echo "  - bat <file>   : cat with syntax highlighting"
    echo "  - lazygit      : terminal git UI"
    echo "  - fzf          : fuzzy finder (Ctrl+R for history)"
    echo ""

    if command -v atuin &>/dev/null; then
        echo -e "${YELLOW}Atuin installed but disabled.${NC} To enable:"
        echo "  touch ~/.config/atuin/.enabled"
        echo "  Then: atuin register / atuin login"
        echo ""
    fi

    if [ "$MINIMAL_MODE" = true ]; then
        echo -e "${YELLOW}Minimal mode:${NC} LSP and dev tools were skipped."
        echo "Run without --minimal for full development environment."
        echo ""
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
            --minimal)
                MINIMAL_MODE=true
                shift
                ;;
            --no-sudo)
                NO_SUDO=true
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
    cat <<'EOF'
Dotfiles Bootstrap Script
==========================

QUICK INSTALL (curl):
    curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash
    curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash -s -- --minimal

Or clone first:
    git clone https://github.com/mainstreamer/config.git ~/.dotfiles
    cd ~/.dotfiles && ./install.sh

OPTIONS:
  --minimal     Lightweight install for servers/containers
                - Installs: git, nvim, fzf, rg, fd, bat, eza, zoxide, starship,
                            lazygit, delta, stow, htop, btop, atuin
                - Skips: Language servers, compilers, LSP plugins
                - Nvim loads minimal config (no autocompletion, no LSP)

  --no-sudo     User-space only install (no root required)
                - Installs tools to ~/.local/bin via cargo/scripts
                - Skips system packages (apt/dnf/pacman)
                - Requires: curl, git, tar (usually pre-installed)
                - Good for: shared servers, restricted environments

  --deps-only   Install packages only, skip symlink creation
                - Useful for testing or staged installs

  --stow-only   Create symlinks only, skip package installation
                - Assumes dependencies already installed
                - Creates: ~/.bashrc -> repo, ~/.config/nvim -> repo

  --help, -h    Show this help message

SUPPORTED DISTROS:
  Fedora        Uses Homebrew for consistent tooling
  Debian        Uses Homebrew for consistent tooling
  Ubuntu        Uses apt + GitHub releases + install scripts
  Pop!_OS       Same as Ubuntu
  Arch          Uses pacman + AUR (yay/paru if available)
  Alpine        Uses apk + cargo (auto-enables --minimal)
  macOS         Uses Homebrew

WHAT GETS INSTALLED:

  Core CLI tools (always):
    git, curl, wget, jq, fzf, ripgrep (rg), fd, bat, eza, zoxide,
    tree, neovim, stow, starship, lazygit, delta, gh, htop, btop, atuin

  Development tools (full mode only):
    - Node.js, npm, TypeScript, typescript-language-server
    - PHP, Composer, phpactor
    - Python 3, pip, pyright
    - Rust (rustc, cargo, rust-analyzer, rustfmt, clippy)
    - Go, gopls

WHAT GETS SYMLINKED:
    ~/.bashrc        -> <repo>/lx/bash/.bashrc
    ~/.bashrc.d/     -> <repo>/lx/bash/.bashrc.d/
    ~/.config/nvim/  -> <repo>/lx/nvim/

EXAMPLES:
    # One-liner install (clones repo automatically)
    curl -fsSL https://raw.githubusercontent.com/mainstreamer/config/master/install.sh | bash

    # One-liner with options
    curl ... | bash -s -- --minimal --no-sudo

    # From cloned repo
    ./install.sh                      # Full install on detected distro
    ./install.sh --minimal            # Lightweight, no dev tools
    ./install.sh --no-sudo            # User-space only, no root
    ./install.sh --minimal --no-sudo  # Minimal + user-space
    ./install.sh --deps-only          # Just packages, no symlinks
    ./install.sh --stow-only          # Just symlinks

ENVIRONMENT VARIABLES:
    DOTFILES_REPO     Git URL to clone (default: github.com/mainstreamer/config)
    DOTFILES_TARGET   Where to clone (default: ~/.dotfiles)

ATUIN (shell history sync) - DISABLED BY DEFAULT:
    Atuin is installed but not activated. To enable:
      touch ~/.config/atuin/.enabled        # Enable atuin shell integration
      source ~/.bashrc                      # Reload shell

    Then optionally set up cross-machine sync:
      atuin register -u <user> -e <email>   # Create account
      atuin login -u <user>                 # Or login existing
      atuin import auto                     # Import bash history
      atuin sync                            # Sync history

    Or self-host: docker run -p 8888:8888 ghcr.io/atuinsh/atuin server start
    Then: atuin config set sync_address "http://your-server:8888"

    Without sync, atuin still provides local fuzzy Ctrl+R history search.

EOF
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Dotfiles Bootstrap${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""

    parse_args "$@"
    setup_dotfiles_dir
    detect_os

    if [ "$STOW_ONLY" = true ]; then
        stow_packages
    elif [ "$DEPS_ONLY" = true ]; then
        install_deps
        setup_rust
        install_php_tools
    else
        install_deps
        setup_rust
        install_php_tools
        stow_packages
        post_install
        print_summary
    fi
}

main "$@"
