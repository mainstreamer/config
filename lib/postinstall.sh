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

    ok "Post-install complete"
}

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
            echo -e "${YELLOW}Debian dash detected - configuration may not fully activate${NC}"
            echo "  Please run: sudo dpkg-reconfigure dash and select 'No'"
            echo "  Then restart your terminal or run: exec bash -l"
        fi

        if source "$HOME/.bashrc" 2>/dev/null; then
            echo -e "${GREEN}Configuration activated for this session${NC}"

            # Verify critical components
            echo "Verifying installation:"
            command -v starship &>/dev/null && echo "  starship prompt" || echo "  starship missing"
            command -v eza &>/dev/null && echo "  eza (modern ls)" || echo "  eza missing"
            type ll 2>/dev/null | grep -q "alias" && echo "  aliases loaded" || echo "  aliases not loaded"

        else
            echo -e "${YELLOW}Configuration not activated. Please run: source ~/.bashrc${NC}"
        fi
    fi
}
