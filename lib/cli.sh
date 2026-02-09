#!/usr/bin/env bash
# CLI commands: version, check, update, uninstall
# Also generates the standalone CLI helper script

cmd_uninstall() {
    echo -e "${RED}================================${NC}"
    echo -e "${RED}  $PROJECT_NAME Uninstall${NC}"
    echo -e "${RED}================================${NC}"
    echo ""
    echo "This will remove:"
    echo "  - $DOTFILES_TARGET"
    echo "  - $VERSION_FILE"
    echo "  - $MANIFEST_FILE"
    echo "  - ~/.local/bin/$PROJECT_NAME"
    echo "  - Symlinks (~/.bashrc, ~/.bash_profile, ~/.profile, ~/.config/nvim, etc.)"
    echo "  - Homebrew (/home/linuxbrew/.linuxbrew)"
    echo ""
    read -p "Are you sure? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && echo "Aborted." && exit 0

    info "Removing symlinks..."
    rm -f "$HOME/.bashrc" 2>/dev/null
    rm -f "$HOME/.zshrc" 2>/dev/null
    rm -f "$HOME/.bash_profile" 2>/dev/null
    rm -f "$HOME/.profile" 2>/dev/null
    rm -rf "$HOME/.shared.d" 2>/dev/null
    rm -rf "$HOME/.shellrc.d" 2>/dev/null
    rm -rf "$HOME/.bashrc.d" 2>/dev/null
    rm -rf "$HOME/.config/nvim" 2>/dev/null
    rm -f "$HOME/.config/starship.toml" 2>/dev/null

    info "Removing $PROJECT_NAME..."
    rm -rf "$DOTFILES_TARGET"
    rm -f "$VERSION_FILE"
    rm -f "$MANIFEST_FILE"
    rm -f "$HOME/.local/bin/$PROJECT_NAME"

    # Clean up old project name artifacts
    for old in dotfiles epicli-conf; do
        rm -rf "$HOME/.$old" 2>/dev/null
        rm -f "$HOME/.${old}-version" "$HOME/.${old}-manifest" 2>/dev/null
        rm -f "$HOME/.local/bin/$old" 2>/dev/null
    done

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
    echo -e "${BLUE}$PROJECT_NAME${NC} v$(get_local_version) ($(get_install_date))"

    if [ -f "$MANIFEST_FILE" ]; then
        local mode=$(grep '^mode=' "$MANIFEST_FILE" | cut -d= -f2)
        local platform=$(grep '^platform=' "$MANIFEST_FILE" | cut -d= -f2)
        echo "  Mode: $mode | Platform: $platform | Location: $DOTFILES_TARGET"

        # Display each section from manifest
        local sections="tools dev-tools configs utilities"
        for section in $sections; do
            local content
            content=$(sed -n "/^\[$section\]/,/^\[/{/^\[/d;/^#/d;/^$/d;p}" "$MANIFEST_FILE" 2>/dev/null)
            [ -z "$content" ] && continue

            local count
            count=$(echo "$content" | wc -l)
            local label="$section"
            case "$section" in
                tools)     label="Tools ($count)" ;;
                dev-tools) label="Dev tools ($count)" ;;
                configs)   label="Configs" ;;
                utilities) label="Utilities ($count)" ;;
            esac

            echo ""
            echo -e "  ${GREEN}$label:${NC}"
            echo "$content" | while IFS= read -r line; do
                echo "    $line"
            done
        done
    else
        echo "  Location: $DOTFILES_TARGET"
        echo "  (no manifest - run install to generate)"
    fi
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

cmd_force_update() {
    info "Forcing fresh installation (ignoring version check)..."
    exec curl -fsSL "$BASE_URL/i" | bash
}

# Generate and install the standalone CLI helper to ~/.local/bin
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
        if [ -f "\$VER_FILE" ]; then
            MANIFEST="\$HOME/.${PROJECT_NAME}-manifest"
            ver=\$(head -1 "\$VER_FILE")
            date=\$(sed -n '2p' "\$VER_FILE")
            echo "$PROJECT_NAME v\$ver (\$date)"
            if [ -f "\$MANIFEST" ]; then
                mode=\$(grep '^mode=' "\$MANIFEST" | cut -d= -f2)
                platform=\$(grep '^platform=' "\$MANIFEST" | cut -d= -f2)
                echo "  Mode: \$mode | Platform: \$platform"
                echo ""
                for section in tools dev-tools configs utilities; do
                    content=\$(sed -n "/^\[\$section\]/,/^\[/{/^\[/d;/^#/d;/^\$/d;p}" "\$MANIFEST" 2>/dev/null)
                    [ -z "\$content" ] && continue
                    count=\$(echo "\$content" | wc -l)
                    case "\$section" in
                        tools)     label="Tools (\$count)" ;;
                        dev-tools) label="Dev tools (\$count)" ;;
                        configs)   label="Configs" ;;
                        utilities) label="Utilities (\$count)" ;;
                    esac
                    echo "  \$label:"
                    echo "\$content" | while IFS= read -r line; do echo "    \$line"; done
                    echo ""
                done
            fi
        else
            echo "not installed"
        fi
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
    force-update|--force)
        curl -fsSL "\$URL/i" | bash
        ;;
    uninstall)
        [ -f "\$DOTFILES/install.sh" ] && bash "\$DOTFILES/install.sh" uninstall || curl -fsSL "\$URL/i" | bash -s -- uninstall
        ;;
    man)
        doc="\$DOTFILES/docs/COMMANDS.md"
        if [ ! -f "\$doc" ]; then
            echo "Manual not found at \$doc"
            echo "Run '$PROJECT_NAME update' to install."
            exit 1
        fi
        if command -v bat &>/dev/null; then
            bat --language=md --style=plain --paging=always "\$doc"
        elif command -v glow &>/dev/null; then
            glow -p "\$doc"
        else
            less "\$doc"
        fi
        ;;
    help)
        echo "$PROJECT_NAME - dotfiles manager"
        echo ""
        echo "Commands:"
        echo "  status         Show installed version and manifest"
        echo "  check          Check for available updates"
        echo "  update         Update to latest version"
        echo "  force-update   Force reinstall (ignore version check)"
        echo "  uninstall      Remove $PROJECT_NAME and all symlinks"
        echo "  man            Full commands reference (paged)"
        echo "  help           Show this help message"
        echo ""
        echo "Shell extras (loaded in interactive shells):"
        echo "  themes [name]           Switch starship prompt theme"
        echo "  fo                      Fuzzy-open file in editor"
        echo "  fcd / fj                Fuzzy-cd into directory"
        echo "  gitbr                   Git branch picker (fzf)"
        echo "  gitlog                  Git commit browser (fzf)"
        echo "  gitgraph                Pretty branch graph"
        echo "  gitdiff f1 f2           Compare files with delta"
        echo "  lg                      Lazygit TUI"
        echo "  dec <string>            URL-decode a string"
        echo ""
        echo "Keyboard shortcuts (fzf):"
        echo "  Ctrl+T                  Fuzzy file search"
        echo "  Ctrl+R                  Fuzzy history search"
        echo "  Alt+C / Esc+C           Fuzzy cd into directory"
        echo ""
        echo "Git aliases (oh-my-zsh style):"
        echo "  gs/gst          status           gc/gc!    commit/amend"
        echo "  ga/gaa          add/add all       gcam     commit -am"
        echo "  gp/gpf          push/force-lease  gl       pull"
        echo "  gd/gds          diff/staged       gco/gcb  checkout/new branch"
        echo "  gb/gba          branch/all        gm/gma   merge/abort"
        echo "  grb/gri [n]     rebase/interactive gsta/gstp stash/pop"
        echo "  glog/gloga      log graph          gsh      show"
        echo ""
        echo "Other aliases: ll/la/lt/lta (eza) | d/dc/dce/ds/dsh/dclean (docker)"
        ;;
    *)
        echo "Usage: $PROJECT_NAME [status|check|update|force-update|uninstall|man|help]"
        ;;
esac
EOF

    chmod +x "$cli_path"
    ok "Installed '$PROJECT_NAME' CLI"
}
