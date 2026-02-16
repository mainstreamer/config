#!/usr/bin/env bash
# Symlink creation, backup, and custom app installation

backup_existing() {
    local backup_dir="$HOME/.${PROJECT_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
    local needs_backup=false

    [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ] && needs_backup=true
    [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && needs_backup=true
    [ -f "$HOME/.bash_profile" ] && [ ! -L "$HOME/.bash_profile" ] && needs_backup=true
    [ -f "$HOME/.profile" ] && [ ! -L "$HOME/.profile" ] && needs_backup=true
    [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && needs_backup=true

    if [ "$needs_backup" = true ]; then
        info "Backing up existing configs to $backup_dir"
        mkdir -p "$backup_dir"

        [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$backup_dir/"
        [ -d "$HOME/.bashrc.d" ] && [ ! -L "$HOME/.bashrc.d" ] && mv "$HOME/.bashrc.d" "$backup_dir/"
        [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$backup_dir/"
        [ -d "$HOME/.zshrc.d" ] && [ ! -L "$HOME/.zshrc.d" ] && mv "$HOME/.zshrc.d" "$backup_dir/"
        [ -f "$HOME/.bash_profile" ] && [ ! -L "$HOME/.bash_profile" ] && mv "$HOME/.bash_profile" "$backup_dir/"
        [ -f "$HOME/.profile" ] && [ ! -L "$HOME/.profile" ] && mv "$HOME/.profile" "$backup_dir/"
        [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$backup_dir/"

        ok "Backup created at $backup_dir"
    fi
}

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

    # Link midnight commander config
    link_mc

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
    rm -rf "$HOME/.local.d" 2>/dev/null || true

    if [ -d "$DOTFILES_DIR/shared" ]; then
        ln -sf "$DOTFILES_DIR/shared/shared.d" "$HOME/.shared.d"

        # Local profile: link personal machine scripts
        if [ "$LOCAL_MODE" = true ] && [ -d "$DOTFILES_DIR/shared/local.d" ]; then
            ln -sf "$DOTFILES_DIR/shared/local.d" "$HOME/.local.d"
        fi

        if [ "$PLATFORM" = "linux" ]; then
            ln -sf "$DOTFILES_DIR/shared/.bashrc" "$HOME/.bashrc"
            # Also link .zshrc on Linux for users who might use Zsh
            ln -sf "$DOTFILES_DIR/shared/.zshrc" "$HOME/.zshrc"
            # Link .bash_profile for SSH login shells
            ln -sf "$DOTFILES_DIR/shared/.bash_profile" "$HOME/.bash_profile"
            # Link .profile for non-bash shells and fallback
            ln -sf "$DOTFILES_DIR/shared/.profile" "$HOME/.profile"
        else
            ln -sf "$DOTFILES_DIR/shared/.zshrc" "$HOME/.zshrc"
            # Link .profile on macOS too for compatibility
            ln -sf "$DOTFILES_DIR/shared/.profile" "$HOME/.profile"
        fi
    else
        warn "Shell config not found, skipping"
    fi

    # Verify all symlinks were created successfully
    info "Verifying symlinks..."
    local broken_symlinks=0
    local symlinks_to_check=(
        "$HOME/.shared.d"
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
    )
    [ "$LOCAL_MODE" = true ] && symlinks_to_check+=("$HOME/.local.d")

    for symlink in "${symlinks_to_check[@]}"; do
        if [ -L "$symlink" ]; then
            # Check if symlink target exists
            if [ ! -e "$symlink" ]; then
                error "Broken symlink: $symlink -> $(readlink $symlink)"
                broken_symlinks=$((broken_symlinks + 1))
            fi
        else
            # Symlink doesn't exist (only warn, not error)
            warn "Symlink not created: $symlink"
        fi
    done

    if [ $broken_symlinks -gt 0 ]; then
        error "$broken_symlinks broken symlinks found!"
        error "Please check the installation and try again."
        return 1
    fi

    ok "All symlinks verified"

    # macOS: Suppress "Last login" message in new terminal tabs
    if [ "$PLATFORM" != "linux" ]; then
        if [ ! -f "$HOME/.hushlogin" ]; then
            touch "$HOME/.hushlogin"
            ok "Created ~/.hushlogin (suppresses 'Last login' message on macOS)"
        fi
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

    local target="$HOME/.config/starship.toml"
    mkdir -p "$HOME/.config"

    # Preserve existing theme choice if it points to a valid theme in our repo
    if [ -L "$target" ]; then
        local current
        current=$(readlink "$target" 2>/dev/null)
        if [ -f "$current" ] && echo "$current" | grep -q "$DOTFILES_DIR/shared/themes/starship"; then
            ok "Starship theme preserved: $(basename "$current" .toml | sed 's/^starship-//;s/^starship$/gruvbox-rainbow (default)/')"
            return 0
        fi
    fi

    # First install or broken link: set default theme
    if [ -f "$DOTFILES_DIR/shared/themes/starship.toml" ]; then
        rm -f "$target" 2>/dev/null || true
        ln -sf "$DOTFILES_DIR/shared/themes/starship.toml" "$target"
    else
        warn "Starship config not found, skipping"
    fi
}

link_mc() {
    info "Linking Midnight Commander config..."

    local mc_config_dir="$HOME/.config/mc"
    mkdir -p "$mc_config_dir"

    if [ -f "$DOTFILES_DIR/settings/mc/ini" ]; then
        ln -sf "$DOTFILES_DIR/settings/mc/ini" "$mc_config_dir/ini"
        ok "Midnight Commander config linked"
    else
        warn "Midnight Commander config not found, skipping"
    fi
}

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

    # Also process [cli] section (cross-platform tools)
    in_section=false
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        if [[ "$line" =~ ^\[([a-z]+)\] ]]; then
            [[ "${BASH_REMATCH[1]}" == "cli" ]] && in_section=true || in_section=false
            continue
        fi

        if [ "$in_section" = true ]; then
            local app="${line// /}"
            [ -z "$app" ] && continue
            command -v "$app" &>/dev/null && continue

            info "Installing CLI tool: $app..."
            if command -v brew &>/dev/null; then
                brew install "$app" 2>/dev/null || true
            elif command -v dnf &>/dev/null; then
                maybe_sudo dnf install -y "$app" 2>/dev/null || true
            elif command -v apt &>/dev/null; then
                maybe_sudo apt install -y "$app" 2>/dev/null || true
            elif command -v pacman &>/dev/null; then
                maybe_sudo pacman -S --noconfirm "$app" 2>/dev/null || true
            fi
        fi
    done < "$apps_conf"
}
