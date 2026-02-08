#!/usr/bin/env bash
# Shared helper functions used across lib/ modules

# Ensure ~/.local/bin exists and is on PATH
ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
}

# Install starship prompt (critical dependency)
# Used by both brew and non-brew install paths
ensure_starship() {
    if command -v starship &>/dev/null; then
        ok "starship already installed"
        return 0
    fi

    warn "starship not found - this is required for prompt!"

    if command -v brew &>/dev/null; then
        if brew install starship; then
            ok "starship installed via brew"
            return 0
        fi
        warn "brew failed to install starship, trying curl..."
    fi

    info "Installing starship via curl..."
    if curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"; then
        ok "starship installed via curl"
        if command -v starship &>/dev/null; then
            info "starship verified: $(starship --version)"
            return 0
        fi
    fi

    error "Failed to install starship - this is critical!"
    return 1
}

# Install a binary tool from a GitHub release
# Usage: install_from_github <cmd> <repo> <archive_url> <extract_cmd>
#   cmd          - command name to check (e.g. "lazygit")
#   repo         - GitHub repo (e.g. "jesseduffield/lazygit")
#   archive_url  - download URL (use {VERSION} placeholder)
#   extract_cmd  - extraction command (use {ARCHIVE} and {BIN_DIR} placeholders)
install_from_github() {
    local cmd="$1" repo="$2" archive_url="$3" extract_cmd="$4"
    local tools_dir="$HOME/.local/bin"

    if command -v "$cmd" &>/dev/null; then
        return 0
    fi

    info "Installing $cmd..."
    mkdir -p "$tools_dir"

    # Fetch latest version
    local version
    local dl_cmd="curl -fsSL"
    command -v curl &>/dev/null || dl_cmd="wget -qO-"
    version=$($dl_cmd "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/' || echo "")

    if [ -z "$version" ]; then
        warn "$cmd: could not fetch latest version"
        return 1
    fi

    # Substitute version into URL
    local url="${archive_url//\{VERSION\}/$version}"
    local archive="/tmp/${cmd}-release.tar.gz"

    # Download
    if command -v curl &>/dev/null; then
        curl -fsSLo "$archive" "$url" 2>/dev/null
    else
        wget -qO "$archive" "$url" 2>/dev/null
    fi

    if [ ! -f "$archive" ]; then
        warn "$cmd: download failed"
        return 1
    fi

    # Extract (substitute placeholders)
    local ecmd="${extract_cmd//\{ARCHIVE\}/$archive}"
    ecmd="${ecmd//\{BIN_DIR\}/$tools_dir}"
    ecmd="${ecmd//\{VERSION\}/$version}"

    if eval "$ecmd"; then
        rm -f "$archive"
        ok "$cmd installed"
        return 0
    else
        rm -f "$archive"
        warn "$cmd: extraction failed"
        return 1
    fi
}
