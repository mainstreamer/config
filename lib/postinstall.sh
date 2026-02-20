#!/usr/bin/env bash
# Post-installation tasks and summary output

post_install() {
    info "Running post-install tasks..."

    # Initialize zoxide
    command -v zoxide &>/dev/null && eval "$(zoxide init bash)" 2>/dev/null || true

    # Sync neovim plugins
    if command -v nvim &>/dev/null; then
        info "Syncing Neovim plugins (this may take a moment)..."

        local sync_ok=false
        for attempt in 1 2 3; do
            if [ "$DEV_MODE" != true ]; then
                NVIM_STANDARD=1 nvim --headless "+Lazy! sync" +qa 2>/dev/null && sync_ok=true && break
            else
                nvim --headless "+Lazy! sync" +qa 2>/dev/null && sync_ok=true && break
            fi
            warn "Plugin sync attempt $attempt failed, retrying..."
            sleep 2
        done

        if [ "$sync_ok" = true ]; then
            ok "Neovim plugins synced"
        else
            warn "Plugin sync failed. Run manually: nvim --headless '+Lazy! sync' +qa"
        fi
    else
        warn "nvim not found, skipping plugin sync"
    fi

    # Rebuild info cheatsheet pages
    local aliases_src="$DOTFILES_TARGET/shared/shared.d/aliases"
    if [ -f "$aliases_src" ]; then
        if ( source "$aliases_src" 2>/dev/null && info --rebuild > /dev/null 2>&1 ); then
            ok "Info pages rebuilt"
        else
            warn "Could not rebuild info pages — run 'info --rebuild' after shell restart"
        fi
    fi

    ok "Post-install complete"
}

print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation complete! (v${VERSION})${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Available commands:"
    echo "  $PROJECT_NAME status|check|update|uninstall"
    echo ""
    echo "Quick start:"
    echo "  z <dir>      smart cd          gitdiff      fuzzy file diff"
    echo "  eza -la      modern ls         lazygit      terminal git UI"
    echo "  bat <file>   syntax highlight  b64 <text>   base64 encode"
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
    local config_loaded=false
    if [ -f "$HOME/.bashrc" ]; then
        if source "$HOME/.bashrc" 2>/dev/null; then
            config_loaded=true
            echo -e "${GREEN}✓ Configuration loaded for this session${NC}"
        fi
    fi

    # Only show restart message if config failed to load
    if [ "$config_loaded" = false ]; then
        echo ""
        echo -e "${YELLOW}→ Restart your terminal to activate configuration${NC}"
        echo "  Or reload now: source ~/.bashrc"
    fi

    # Special handling for Debian systems
    if [ "$DISTRO" = "debian" ] && [ "$(readlink /bin/sh)" = "dash" ]; then
        echo ""
        echo -e "${YELLOW}⚠ Debian dash detected - some features may not work${NC}"
        echo "  Fix: sudo dpkg-reconfigure dash (select 'No')"
        echo "  Then: exec bash -l (to reload shell)"
    fi
}
