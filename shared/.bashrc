# .bashrc - Linux entry point
# Sources shared scripts from ~/.shared.d/

# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# Environment
export SHELL_TYPE="bash"
# Ensure .local/bin is in PATH (critical for CLI tools)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
export PATH="$HOME/bin:$PATH"
export PATH="$PATH:$HOME/.cargo/bin"

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Dev-mode paths (only if installed)
[ -d "$HOME/go/bin" ] && export PATH="$PATH:$HOME/go/bin"
[ -d "$HOME/.config/composer/vendor/bin" ] && export PATH="$PATH:$HOME/.config/composer/vendor/bin"
[ -d "$HOME/.composer/vendor/bin" ] && export PATH="$PATH:$HOME/.composer/vendor/bin"

# Linuxbrew (Homebrew on Linux)
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
fi
if [ -d "$HOME/.linuxbrew/bin" ]; then
    export PATH="$HOME/.linuxbrew/bin:$HOME/.linuxbrew/sbin:$PATH"
fi

# Bash completion
[ -f /etc/bash_completion ] && . /etc/bash_completion

# Readline settings (interactive shells only)
if [[ $- == *i* ]]; then
    bind 'set colored-stats on'
    bind 'set colored-completion-prefix on'
    bind 'set menu-complete-display-prefix on'
    bind 'set visible-stats on'
    bind 'set mark-symlinked-directories on'
fi

# Source all scripts from shared.d
if [ -d ~/.shared.d ]; then
    for rc in ~/.shared.d/*; do
        [ -f "$rc" ] && [[ "$rc" != *.archived ]] && [[ "$rc" != *.lst ]] && . "$rc"
    done
    unset rc
else
    # Fallback: try to source from the original location if symlink is broken
    if [ -d "$HOME/.epicli-conf/shared/shared.d" ]; then
        for rc in "$HOME/.epicli-conf/shared/shared.d"/*; do
            [ -f "$rc" ] && [[ "$rc" != *.archived ]] && [[ "$rc" != *.lst ]] && . "$rc"
        done
        unset rc
    fi
fi
