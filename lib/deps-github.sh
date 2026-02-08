#!/usr/bin/env bash
# Install CLI tools from GitHub releases (Ubuntu/Pop!_OS path)
# Uses install_from_github() from common.sh for binary downloads

install_github_tools() {
    local tools_dir="$HOME/.local/bin"
    mkdir -p "$tools_dir"

    # Install atuin via official script
    if ! command -v atuin &>/dev/null; then
        info "Installing atuin..."
        curl -fsSL https://setup.atuin.sh | bash 2>/dev/null || warn "Atuin install failed"
    fi

    # Install starship (critical for prompt)
    ensure_starship

    # Install zoxide
    if ! command -v zoxide &>/dev/null; then
        info "Installing zoxide..."
        curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || warn "Zoxide install failed"
    fi

    # Install lazygit
    install_from_github "lazygit" "jesseduffield/lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_{VERSION}_Linux_x86_64.tar.gz" \
        "tar -xzf {ARCHIVE} -C /tmp lazygit && mv /tmp/lazygit {BIN_DIR}/"

    # Install gh (GitHub CLI)
    install_from_github "gh" "cli/cli" \
        "https://github.com/cli/cli/releases/download/v{VERSION}/gh_{VERSION}_linux_amd64.tar.gz" \
        "tar -xzf {ARCHIVE} -C /tmp && mv /tmp/gh_{VERSION}_linux_amd64/bin/gh {BIN_DIR}/ && rm -rf /tmp/gh_*"

    # Install eza (with cargo fallback)
    if ! command -v eza &>/dev/null; then
        install_from_github "eza" "eza-community/eza" \
            "https://github.com/eza-community/eza/releases/download/v{VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" \
            "tar -xzf {ARCHIVE} -C {BIN_DIR}" \
        || {
            command -v cargo &>/dev/null && cargo install eza 2>/dev/null || warn "eza install failed"
        }
    fi

    # Install delta (with cargo fallback)
    if ! command -v delta &>/dev/null; then
        install_from_github "delta" "dandavison/delta" \
            "https://github.com/dandavison/delta/releases/download/{VERSION}/delta-{VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
            "tar -xzf {ARCHIVE} -C /tmp && mv /tmp/delta-{VERSION}-x86_64-unknown-linux-gnu/delta {BIN_DIR}/ && rm -rf /tmp/delta-*" \
        || {
            command -v cargo &>/dev/null && cargo install git-delta 2>/dev/null || warn "delta install failed"
        }
    fi
}
