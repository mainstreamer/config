#!/usr/bin/env bash
# Dependency installation dispatcher and per-distro package installers

install_deps() {
    ensure_local_bin

    case "$DISTRO" in
        fedora|debian|macos)
            if install_homebrew; then
                install_brew_packages
            else
                warn "Homebrew unavailable, falling back to apt + GitHub releases"
                install_ubuntu_packages
            fi
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
# Homebrew setup and brew-based install (Fedora, Debian, macOS)
# ------------------------------------------------------------------------------

install_homebrew() {
    if command -v brew &>/dev/null; then
        ok "Homebrew already installed"
        return
    fi

    # Homebrew refuses to run as root
    if [ "$(id -u)" -eq 0 ]; then
        warn "Homebrew cannot be installed as root, skipping"
        return 1
    fi

    # Homebrew requires git + gcc
    local missing_prereqs
    missing_prereqs=$(check_commands_present git gcc make curl) || true
    if [ -n "$missing_prereqs" ]; then
        if [ "$DEV_MODE" = true ]; then
            info "Installing Homebrew prerequisites: $missing_prereqs"
            case "$DISTRO" in
                fedora)
                    maybe_sudo dnf install -y git gcc gcc-c++ make curl
                    ;;
                debian|ubuntu|popos)
                    maybe_sudo apt update && maybe_sudo apt install -y git build-essential curl
                    ;;
            esac
        else
            warn "Missing Homebrew prerequisites: $missing_prereqs"
            case "$DISTRO" in
                fedora) print_install_hint "git gcc gcc-c++ make curl" ;;
                debian|ubuntu|popos) print_install_hint "git build-essential curl" ;;
            esac
            warn "Attempting Homebrew install anyway..."
        fi
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to path for this session
    if [ "$PLATFORM" = "linux" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # Set performance env vars for this session (repo shell configs handle persistence)
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1

    ok "Homebrew installed"
}

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

    # Verify critical tools
    info "Verifying critical tools..."
    ensure_starship

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

    local apt_packages="git curl wget jq fzf tree htop btop neovim make gcc"
    local apt_extras="fd-find bat ripgrep"
    local missing_apt=""
    local missing_extras=""

    for pkg in $apt_packages; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || missing_apt="$missing_apt $pkg"
    done
    for pkg in $apt_extras; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || missing_extras="$missing_extras $pkg"
    done

    if [ -n "$missing_apt" ] || [ -n "$missing_extras" ]; then
        if [ "$DEV_MODE" = true ]; then
            maybe_sudo apt update || true
            [ -n "$missing_apt" ] && maybe_sudo apt install -y $missing_apt 2>/dev/null || warn "Some apt packages failed"
            [ -n "$missing_extras" ] && maybe_sudo apt install -y $missing_extras 2>/dev/null || true
        else
            local all_missing="$missing_apt $missing_extras"
            warn "Missing packages:$all_missing"
            print_install_hint "$all_missing"
            info "Continuing with user-space tools..."
        fi
    else
        ok "All apt packages already installed"
    fi

    # Create symlinks for fd and bat (Ubuntu uses different names)
    mkdir -p "$HOME/.local/bin"
    [ -f /usr/bin/fdfind ] && [ ! -e "$HOME/.local/bin/fd" ] && \
        ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
    [ -f /usr/bin/batcat ] && [ ! -e "$HOME/.local/bin/bat" ] && \
        ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"

    # Install tools from GitHub releases (no sudo needed)
    install_github_tools

    if [ "$DEV_MODE" = true ]; then
        install_ubuntu_dev_packages
    fi
}

# ------------------------------------------------------------------------------
# Arch Linux packages (pacman + AUR)
# ------------------------------------------------------------------------------

install_arch_packages() {
    info "Checking installed packages..."

    # Standard packages
    local packages="git curl wget jq fzf ripgrep fd bat eza zoxide tree \
        neovim starship lazygit git-delta github-cli htop btop atuin"

    if [ "$DEV_MODE" = true ]; then
        packages="$packages nodejs npm php composer python python-pip \
            go gopls rust rust-analyzer pyright"
    fi

    local missing=""
    for pkg in $packages; do
        pacman -Q "$pkg" &>/dev/null || missing="$missing $pkg"
    done

    if [ -n "$missing" ]; then
        if [ "$DEV_MODE" = true ]; then
            info "Installing missing packages:$missing"
            maybe_sudo pacman -Syu --noconfirm $missing 2>/dev/null || warn "Some pacman packages failed"
        else
            warn "Missing packages:$missing"
            print_install_hint "$missing"
            info "Continuing without them..."
        fi
    else
        ok "All packages already installed"
    fi

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
    info "Checking installed packages..."

    local apk_packages="git curl wget jq fzf ripgrep fd bat tree neovim starship htop btop build-base cargo"
    local missing=""
    for pkg in $apk_packages; do
        apk info -e "$pkg" &>/dev/null || missing="$missing $pkg"
    done

    if [ -n "$missing" ]; then
        if [ "$DEV_MODE" = true ]; then
            info "Installing missing packages:$missing"
            maybe_sudo apk add --no-cache $missing 2>/dev/null || warn "Some apk packages failed"
        else
            warn "Missing packages:$missing"
            print_install_hint "$missing"
            info "Continuing without them..."
        fi
    else
        ok "All apk packages already installed"
    fi

    # Install tools via cargo
    if command -v cargo &>/dev/null; then
        info "Installing Rust-based tools via cargo..."
        cargo install eza zoxide atuin git-delta 2>/dev/null || warn "Some cargo installs failed"
    fi

    # Install lazygit from binary
    install_from_github "lazygit" "jesseduffield/lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_{VERSION}_Linux_x86_64.tar.gz" \
        "tar -xzf {ARCHIVE} -C /tmp lazygit && mv /tmp/lazygit {BIN_DIR}/"

    # Install gh from binary
    install_from_github "gh" "cli/cli" \
        "https://github.com/cli/cli/releases/download/v{VERSION}/gh_{VERSION}_linux_amd64.tar.gz" \
        "tar -xzf {ARCHIVE} -C /tmp && mv /tmp/gh_{VERSION}_linux_amd64/bin/gh {BIN_DIR}/ && rm -rf /tmp/gh_*"
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
