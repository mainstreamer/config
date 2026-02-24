#!/usr/bin/env bash
# Config file installation, backup, and custom app installation

backup_existing() {
    # Skip backup if epicli already manages these files (subsequent install/update)
    [ -f "${VERSION_FILE:-$HOME/.epicli-version}" ] && return 0

    local backup_dir="$HOME/.${PROJECT_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
    local needs_backup=false

    [ -f "$HOME/.bashrc" ] && needs_backup=true
    [ -f "$HOME/.zshrc" ] && needs_backup=true
    [ -f "$HOME/.bash_profile" ] && needs_backup=true
    [ -f "$HOME/.profile" ] && needs_backup=true
    [ -d "$HOME/.config/nvim" ] && needs_backup=true

    if [ "$needs_backup" = true ]; then
        info "Backing up existing configs to $backup_dir"
        mkdir -p "$backup_dir"

        [ -f "$HOME/.bashrc" ]        && mv "$HOME/.bashrc" "$backup_dir/"
        [ -d "$HOME/.bashrc.d" ]      && mv "$HOME/.bashrc.d" "$backup_dir/"
        [ -f "$HOME/.zshrc" ]         && mv "$HOME/.zshrc" "$backup_dir/"
        [ -d "$HOME/.zshrc.d" ]       && mv "$HOME/.zshrc.d" "$backup_dir/"
        [ -f "$HOME/.bash_profile" ]  && mv "$HOME/.bash_profile" "$backup_dir/"
        [ -f "$HOME/.profile" ]       && mv "$HOME/.profile" "$backup_dir/"
        [ -d "$HOME/.config/nvim" ]   && mv "$HOME/.config/nvim" "$backup_dir/"

        ok "Backup created at $backup_dir"
    fi
}

link_configs() {
    cd "$DOTFILES_DIR"

    info "Installing config files..."

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

    ok "Configs installed"
}

link_shell() {
    info "Installing shell config..."

    # Remove old symlinks or stale dirs from previous installs
    rm -f "$HOME/.bashrc" 2>/dev/null || true
    rm -f "$HOME/.zshrc" 2>/dev/null || true
    rm -rf "$HOME/.bashrc.d" 2>/dev/null || true
    rm -rf "$HOME/.zshrc.d" 2>/dev/null || true
    rm -rf "$HOME/.shellrc.d" 2>/dev/null || true
    rm -rf "$HOME/.shared.d" 2>/dev/null || true
    rm -rf "$HOME/.local.d" 2>/dev/null || true

    if [ -d "$DOTFILES_DIR/shared" ]; then
        cp -r "$DOTFILES_DIR/shared/shared.d" "$HOME/.shared.d"

        # Local profile: copy personal machine scripts
        if [ "$LOCAL_MODE" = true ] && [ -d "$DOTFILES_DIR/shared/local.d" ]; then
            cp -r "$DOTFILES_DIR/shared/local.d" "$HOME/.local.d"
        fi

        if [ "$PLATFORM" = "linux" ]; then
            cp "$DOTFILES_DIR/shared/.bashrc" "$HOME/.bashrc"
            cp "$DOTFILES_DIR/shared/.zshrc" "$HOME/.zshrc"
            cp "$DOTFILES_DIR/shared/.bash_profile" "$HOME/.bash_profile"
            cp "$DOTFILES_DIR/shared/.profile" "$HOME/.profile"
        else
            cp "$DOTFILES_DIR/shared/.zshrc" "$HOME/.zshrc"
            cp "$DOTFILES_DIR/shared/.profile" "$HOME/.profile"
        fi
    else
        warn "Shell config not found, skipping"
    fi

    # Verify all config files were copied successfully
    info "Verifying configs..."
    local missing=0
    local files_to_check=(
        "$HOME/.shared.d"
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
    )
    [ "$LOCAL_MODE" = true ] && files_to_check+=("$HOME/.local.d")

    for f in "${files_to_check[@]}"; do
        if [ ! -e "$f" ]; then
            warn "Config not installed: $f"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -gt 0 ]; then
        error "$missing config files missing — check the installation."
        return 1
    fi

    ok "All configs verified"

    # macOS: Suppress "Last login" message in new terminal tabs
    if [ "$PLATFORM" != "linux" ]; then
        if [ ! -f "$HOME/.hushlogin" ]; then
            touch "$HOME/.hushlogin"
            ok "Created ~/.hushlogin (suppresses 'Last login' message on macOS)"
        fi
    fi
}

link_nvim() {
    info "Installing Neovim config..."

    rm -rf "$HOME/.config/nvim" 2>/dev/null || true

    if [ -d "$DOTFILES_DIR/nvim" ]; then
        cp -r "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    else
        warn "Neovim config not found, skipping"
    fi
}

link_starship() {
    info "Installing Starship config..."

    local target="$HOME/.config/starship.toml"
    local theme_record="$HOME/.config/starship-theme"
    mkdir -p "$HOME/.config"

    # Preserve theme chosen by user (stored in ~/.config/starship-theme)
    local saved_theme=""
    [ -f "$theme_record" ] && saved_theme=$(cat "$theme_record")

    # If no record yet but a starship.toml exists, detect which theme it matches
    if [ -z "$saved_theme" ] && [ -f "$target" ]; then
        for f in "$DOTFILES_DIR/shared/themes"/starship*.toml; do
            [ -f "$f" ] || continue
            if diff -q "$f" "$target" &>/dev/null; then
                saved_theme=$(basename "$f" .toml | sed 's/^starship-//;s/^starship$/default/')
                echo "$saved_theme" > "$theme_record"
                break
            fi
        done
    fi

    if [ -n "$saved_theme" ]; then
        local theme_file
        if [ "$saved_theme" = "default" ] || [ "$saved_theme" = "gruvbox-rainbow" ]; then
            theme_file="$DOTFILES_DIR/shared/themes/starship.toml"
        else
            theme_file="$DOTFILES_DIR/shared/themes/starship-${saved_theme}.toml"
        fi
        if [ -f "$theme_file" ]; then
            rm -f "$target"
            cp "$theme_file" "$target"
            ok "Starship theme preserved: $saved_theme"
            return 0
        fi
    fi

    # First install or unrecognised theme: keep existing file untouched if present
    if [ -f "$target" ]; then
        ok "Starship config untouched (custom theme)"
        return 0
    fi

    if [ -f "$DOTFILES_DIR/shared/themes/starship.toml" ]; then
        cp "$DOTFILES_DIR/shared/themes/starship.toml" "$target"
        echo "default" > "$theme_record"
    else
        warn "Starship config not found, skipping"
    fi
}

link_mc() {
    info "Installing Midnight Commander config..."

    local mc_config_dir="$HOME/.config/mc"
    mkdir -p "$mc_config_dir"

    if [ -f "$DOTFILES_DIR/settings/mc/ini" ]; then
        rm -f "$mc_config_dir/ini"
        cp "$DOTFILES_DIR/settings/mc/ini" "$mc_config_dir/ini"
        ok "Midnight Commander config installed"
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
