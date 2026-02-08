#!/usr/bin/env bash
# Version tracking and installation manifest generation

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

generate_manifest() {
    local mode="standard"
    [ "$DEV_MODE" = true ] && mode="dev"

    cat > "$MANIFEST_FILE" << MEOF
# $PROJECT_NAME manifest - generated $(date +%Y-%m-%d)
mode=$mode
version=$VERSION
platform=${DISTRO:-unknown}
MEOF

    # Tools section - only list what's actually installed
    echo "" >> "$MANIFEST_FILE"
    echo "[tools]" >> "$MANIFEST_FILE"
    local tools=(
        "nvim:Modern editor"
        "starship:Cross-shell prompt"
        "fzf:Fuzzy finder"
        "rg:Fast grep (ripgrep)"
        "fd:Fast find"
        "bat:cat + syntax highlighting"
        "eza:Modern ls"
        "zoxide:Smart cd (z)"
        "lazygit:Terminal git UI"
        "delta:Better git diffs"
        "gh:GitHub CLI"
        "tmux:Terminal multiplexer"
        "atuin:Shell history sync"
        "htop:Process viewer"
        "btop:Process viewer"
        "ffmpeg:Media toolkit"
        "tree:Directory tree"
    )
    for entry in "${tools[@]}"; do
        local cmd="${entry%%:*}"
        local desc="${entry#*:}"
        if command -v "$cmd" &>/dev/null; then
            printf "%-12s %s\n" "$cmd" "$desc" >> "$MANIFEST_FILE"
        fi
    done

    # Dev tools (only if dev mode)
    if [ "$DEV_MODE" = true ]; then
        echo "" >> "$MANIFEST_FILE"
        echo "[dev-tools]" >> "$MANIFEST_FILE"
        local dev_tools=(
            "node:Node.js runtime"
            "tsc:TypeScript compiler"
            "php:PHP runtime"
            "composer:PHP package manager"
            "python3:Python runtime"
            "rustc:Rust compiler"
            "go:Go runtime"
            "gopls:Go LSP"
            "pyright:Python LSP"
            "rust-analyzer:Rust LSP"
        )
        for entry in "${dev_tools[@]}"; do
            local cmd="${entry%%:*}"
            local desc="${entry#*:}"
            if command -v "$cmd" &>/dev/null; then
                printf "%-12s %s\n" "$cmd" "$desc" >> "$MANIFEST_FILE"
            fi
        done
    fi

    # Configs section - check what was linked
    echo "" >> "$MANIFEST_FILE"
    echo "[configs]" >> "$MANIFEST_FILE"
    [ -L "$HOME/.bashrc" ] && printf "%-12s %s\n" "shell" "bashrc, zshrc, shared.d" >> "$MANIFEST_FILE"
    [ -L "$HOME/.config/nvim" ] && printf "%-12s %s\n" "nvim" "Neovim ($mode mode)" >> "$MANIFEST_FILE"
    [ -L "$HOME/.config/starship.toml" ] && printf "%-12s %s\n" "starship" "Starship prompt" >> "$MANIFEST_FILE"

    # Shell utilities section
    echo "" >> "$MANIFEST_FILE"
    echo "[utilities]" >> "$MANIFEST_FILE"
    local utils=(
        "aliases:Shell aliases & git shortcuts"
        "prompt:Starship prompt init"
        "docker:Docker helpers (dc, dsh, dclean)"
        "cleanup:Media file organizer"
        "depcheck:Dependency checker"
        "enc:File encryption"
        "key:USB key management"
        "rec:Screen recording (ffmpeg)"
        "where:IP geolocation"
        "hidevpn:VPN toggle"
        "atuin:Shell history (opt-in)"
        "unglitch:Terminal reset"
    )
    if [ -d "$DOTFILES_DIR/shared/shared.d" ]; then
        for entry in "${utils[@]}"; do
            local name="${entry%%:*}"
            local desc="${entry#*:}"
            if [ -f "$DOTFILES_DIR/shared/shared.d/$name" ]; then
                printf "%-12s %s\n" "$name" "$desc" >> "$MANIFEST_FILE"
            fi
        done
    fi
}
