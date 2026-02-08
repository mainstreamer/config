#!/usr/bin/env bash
# Dev-mode tools: language runtimes, LSPs, fonts, GUI config
# All functions here only run when --dev is passed

# Main entry point for dev tool installation
setup_dev_tools() {
    setup_rust
    install_php_tools
}

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
