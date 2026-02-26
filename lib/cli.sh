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
    echo "  - Config files (~/.bashrc, ~/.bash_profile, ~/.profile, ~/.config/nvim, etc.)"
    echo "  - Homebrew (/home/linuxbrew/.linuxbrew)"
    echo ""
    read -p "Are you sure? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && echo "Aborted." && exit 0

    info "Removing config files..."
    rm -f "$HOME/.bashrc" 2>/dev/null
    rm -f "$HOME/.zshrc" 2>/dev/null
    rm -f "$HOME/.bash_profile" 2>/dev/null
    rm -f "$HOME/.profile" 2>/dev/null
    rm -rf "$HOME/.shared.d" 2>/dev/null
    rm -rf "$HOME/.local.d" 2>/dev/null
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
        # Support both old mode= and new profile= format
        local profile=$(grep '^profile=' "$MANIFEST_FILE" | cut -d= -f2)
        [ -z "$profile" ] && profile=$(grep '^mode=' "$MANIFEST_FILE" | cut -d= -f2)
        local platform=$(grep '^platform=' "$MANIFEST_FILE" | cut -d= -f2)
        echo "  Profile: $profile | Platform: $platform | Location: $DOTFILES_TARGET"

        # Display each section from manifest
        local sections="tools dev-tools configs utilities local-utils"
        for section in $sections; do
            local content
            content=$(sed -n "/^\[$section\]/,/^\[/{/^\[/d;/^#/d;/^$/d;p}" "$MANIFEST_FILE" 2>/dev/null)
            [ -z "$content" ] && continue

            local count
            count=$(echo "$content" | wc -l)
            local label="$section"
            case "$section" in
                tools)      label="Tools ($count)" ;;
                dev-tools)  label="Dev tools ($count)" ;;
                configs)    label="Configs" ;;
                utilities)  label="Utilities ($count)" ;;
                local-utils) label="Local utils ($count)" ;;
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

# Reconstruct install flags from manifest profile or explicit args
# Usage: _build_update_flags [user-provided flags...]
_build_update_flags() {
    local flags=""

    # If user passed explicit flags, use those (override stored profile)
    if [ $# -gt 0 ]; then
        for arg in "$@"; do
            case "$arg" in
                --standard) flags="" ;;  # strip everything
                --local)    flags="$flags --local" ;;
                --dev)      flags="$flags --dev" ;;
            esac
        done
        echo "$flags"
        return
    fi

    # No explicit flags: read profile from manifest
    if [ -f "$MANIFEST_FILE" ]; then
        local profile=$(grep '^profile=' "$MANIFEST_FILE" | cut -d= -f2)
        # Fallback for old mode= format
        [ -z "$profile" ] && profile=$(grep '^mode=' "$MANIFEST_FILE" | cut -d= -f2)
        case "$profile" in
            *local*) flags="$flags --local" ;;
        esac
        case "$profile" in
            *dev*) flags="$flags --dev" ;;
        esac
    fi
    echo "$flags"
}

cmd_update() {
    local ver_arg=""
    local profile_args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --version) ver_arg="--version $2"; shift 2 ;;
            *) profile_args+=("$1"); shift ;;
        esac
    done

    local local_ver=$(get_local_version)
    local remote_ver=$(get_remote_version)
    local flags=$(_build_update_flags "${profile_args[@]}")

    if [ ${#profile_args[@]} -eq 0 ] && [ -z "$ver_arg" ] && [ "$local_ver" = "$remote_ver" ]; then
        ok "Already at $local_ver"
        return 0
    fi

    if [ -n "$ver_arg" ]; then
        info "Installing $ver_arg..."
    else
        info "Updating $local_ver -> $remote_ver${flags:+ (profile:$flags)}"
    fi
    curl -fsSL "$BASE_URL/i" | bash -s -- --update $flags $ver_arg
}

cmd_force_update() {
    local flags=$(_build_update_flags "$@")
    info "Forcing fresh installation${flags:+ (profile:$flags)}..."
    curl -fsSL "$BASE_URL/i" | bash -s -- --update $flags
}

# Generate and install the standalone CLI helper to ~/.local/bin
install_cli() {
    local cli_path="$HOME/.local/bin/$PROJECT_NAME"
    mkdir -p "$HOME/.local/bin"

    cat > "$cli_path" << 'CLIEOF'
#!/usr/bin/env bash
URL="https://tldr.icu"
CLIEOF
    cat >> "$cli_path" << EOF
VER_FILE="\$HOME/.${PROJECT_NAME}-version"
MANIFEST="\$HOME/.${PROJECT_NAME}-manifest"
DOTFILES="\${DOTFILES_TARGET:-\$HOME/.$PROJECT_NAME}"
NAME="$PROJECT_NAME"
SIGNING_KEY_URL="$SIGNING_KEY_URL"
SIGNING_PUBLIC_KEY="$SIGNING_PUBLIC_KEY"
EOF
    cat >> "$cli_path" << 'CLIEOF'

# Download install.sh to a temp file, verify its signature, then exec.
# Falls back gracefully if openssl or the sig are unavailable.
_verified_exec() {
    local installer sig_file pubkey_file
    installer=$(mktemp)
    sig_file=$(mktemp)
    pubkey_file=$(mktemp)
    trap 'rm -f "$installer" "$sig_file" "$pubkey_file"' EXIT

    if ! curl -fsSL --max-time 60 "$URL/i" -o "$installer" 2>/dev/null; then
        echo "error: failed to download installer" >&2; exit 1
    fi

    if ! command -v openssl &>/dev/null; then
        echo "warn: openssl not found — skipping signature verification" >&2
        trap - EXIT; bash "$installer" "$@"; local rc=$?; rm -f "$installer"; return $rc
    fi

    if ! curl -fsSL --max-time 10 "$URL/i.sig" -o "$sig_file" 2>/dev/null; then
        echo "warn: could not fetch installer signature — skipping verification" >&2
        trap - EXIT; bash "$installer" "$@"; local rc=$?; rm -f "$installer"; return $rc
    fi

    local fetched_key
    fetched_key=$(curl -fsSL --max-time 10 "$SIGNING_KEY_URL" 2>/dev/null)
    if echo "$fetched_key" | grep -q "BEGIN PUBLIC KEY"; then
        printf '%s\n' "$fetched_key" > "$pubkey_file"
    else
        printf '%s\n' "$SIGNING_PUBLIC_KEY" > "$pubkey_file"
    fi

    if openssl pkeyutl -verify -pubin -inkey "$pubkey_file" \
            -sigfile "$sig_file" -rawin -in "$installer" &>/dev/null; then
        echo "Installer signature verified"
    else
        echo "error: installer signature verification FAILED — aborting" >&2
        exit 1
    fi

    trap - EXIT
    rm -f "$sig_file" "$pubkey_file"
    bash "$installer" "$@"
    local rc=$?; rm -f "$installer"; return $rc
}

# Reconstruct install flags from manifest profile
_profile_flags() {
    local flags=""
    if [ -f "$MANIFEST" ]; then
        local profile=$(grep '^profile=' "$MANIFEST" | cut -d= -f2)
        [ -z "$profile" ] && profile=$(grep '^mode=' "$MANIFEST" | cut -d= -f2)
        case "$profile" in *local*) flags="$flags --local" ;; esac
        case "$profile" in *dev*) flags="$flags --dev" ;; esac
    fi
    echo "$flags"
}

# Build flags: use explicit args if given, otherwise read from manifest
_build_flags() {
    if [ $# -gt 0 ]; then
        local flags=""
        for arg in "$@"; do
            case "$arg" in
                --standard) flags="" ;;
                --local)    flags="$flags --local" ;;
                --dev)      flags="$flags --dev" ;;
            esac
        done
        echo "$flags"
    else
        _profile_flags
    fi
}

case "${1:-status}" in
    status|version)
        if [ -f "$VER_FILE" ]; then
            ver=$(head -1 "$VER_FILE")
            date=$(sed -n '2p' "$VER_FILE")
            echo "$NAME v$ver ($date)"
            if [ -f "$MANIFEST" ]; then
                profile=$(grep '^profile=' "$MANIFEST" | cut -d= -f2)
                [ -z "$profile" ] && profile=$(grep '^mode=' "$MANIFEST" | cut -d= -f2)
                platform=$(grep '^platform=' "$MANIFEST" | cut -d= -f2)
                echo "  Profile: $profile | Platform: $platform"
                echo ""
                for section in tools dev-tools configs utilities local-utils; do
                    content=$(sed -n "/^\[$section\]/,/^\[/{/^\[/d;/^#/d;/^$/d;p}" "$MANIFEST" 2>/dev/null)
                    [ -z "$content" ] && continue
                    count=$(echo "$content" | wc -l)
                    case "$section" in
                        tools)      label="Tools ($count)" ;;
                        dev-tools)  label="Dev tools ($count)" ;;
                        configs)    label="Configs" ;;
                        utilities)  label="Utilities ($count)" ;;
                        local-utils) label="Local utils ($count)" ;;
                    esac
                    echo "  $label:"
                    echo "$content" | while IFS= read -r line; do echo "    $line"; done
                    echo ""
                done
            fi
        else
            echo "not installed"
        fi
        ;;
    check)
        local_ver=$(head -1 "$VER_FILE" 2>/dev/null || echo "none")
        remote_ver=$(curl -fsSL "$URL/latest" 2>/dev/null || echo "?")
        echo "Installed: $local_ver"
        echo "Available: $remote_ver"
        [ "$local_ver" = "$remote_ver" ] && echo "Up to date." || echo "Run: $NAME update"
        ;;
    update|up)
        shift
        ver_arg=""
        profile_args=()
        while [ $# -gt 0 ]; do
            case "$1" in
                --version) ver_arg="--version $2"; shift 2 ;;
                *) profile_args+=("$1"); shift ;;
            esac
        done
        flags=$(_build_flags "${profile_args[@]}")
        _verified_exec --update $flags $ver_arg
        ;;
    force-update|--force)
        shift
        flags=$(_build_flags "$@")
        _verified_exec --update $flags
        ;;
    uninstall)
        [ -f "$DOTFILES/install.sh" ] && bash "$DOTFILES/install.sh" uninstall || _verified_exec uninstall
        ;;
    man)
        doc="$DOTFILES/docs/COMMANDS.md"
        if [ ! -f "$doc" ]; then
            echo "Manual not found at $doc"
            echo "Run '$NAME update' to install."
            exit 1
        fi
        if command -v bat &>/dev/null; then
            bat --language=md --style=plain --paging=always "$doc"
        elif command -v glow &>/dev/null; then
            glow -p "$doc"
        else
            less "$doc"
        fi
        ;;
    help)
        echo "$NAME - dotfiles manager"
        echo ""
        echo "Commands:"
        echo "  status              Show installed version and profile"
        echo "  check               Check for available updates"
        echo "  update / up         Update (preserves current profile)"
        echo "  update --local      Upgrade to standard+local profile"
        echo "  update --dev        Upgrade to standard+dev profile"
        echo "  update --standard   Downgrade to standard only"
        echo "  update --version X  Install a specific version (e.g. 3.3.7)"
        echo "  force-update        Force reinstall (ignore version check)"
        echo "  uninstall           Remove $NAME and all symlinks"
        echo "  man                 Full commands reference (paged)"
        echo "  help                Show this help message"
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
        echo "Crypto shortcuts:"
        echo "  sha <file> [file2]      SHA-256 hash / compare"
        echo "  checksig <file>         Verify GPG signature"
        echo "  signfile <file>         GPG detached-sign"
        echo "  fingerprint <file|id>   SSH/GPG/TLS fingerprint"
        echo "  certinfo <host|file>    TLS certificate details"
        echo "  pw [length]             Generate random password"
        echo ""
        echo "Keyboard shortcuts (fzf):"
        echo "  Ctrl+T                  Fuzzy file search"
        echo "  Ctrl+R                  Fuzzy history search"
        echo "  Alt+C / Esc+C           Fuzzy cd into directory"
        echo ""
        echo "Git aliases (oh-my-zsh style):"
        echo "  gs/gst          status           gc/gc!    commit/amend"
        echo "  ga/gaa          add/add all       gcam     add all + commit"
        echo "  gp/gpf          push/force-lease  gl       pull"
        echo "  gd/gds          diff/staged       gco/gcb  checkout/new branch"
        echo "  gb/gba          branch/all        gm/gma   merge/abort"
        echo "  grb/gri [n]     rebase/interactive gsta/gstp stash/pop"
        echo "  glog/gloga      log graph          gsh      show"
        echo ""
        echo "Other aliases: ll/la/lt/lta (eza) | d/dc/dce/ds/dsh/dclean (docker)"
        ;;
    *)
        echo "Usage: $NAME [status|check|update|force-update|uninstall|man|help]"
        ;;
esac
CLIEOF

    chmod +x "$cli_path"
    ok "Installed '$PROJECT_NAME' CLI"
}
