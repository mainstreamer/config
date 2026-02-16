# .bashrc - Linux entry point
# Sources shared scripts from ~/.shared.d/

# Fix TERM for starship and other tools (common issue in some terminals)
if [ "$TERM" = "dumb" ] || [ -z "$TERM" ]; then
    export TERM=xterm-256color
fi

# Force interactive behavior for non-interactive shells
# This can happen in some terminal emulators or nested shells
if [[ "$-" != *i* ]] && [[ -z "$SSH_CONNECTION" ]]; then
    # This is a non-interactive shell, but we want to load our config anyway
    # Set a minimal PS1 to indicate this is somewhat interactive
    export PS1='\$ '
    # Continue loading configuration
fi

# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

export PATH="$HOME/.npm-global/bin:$PATH"

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

# Homebrew performance settings
if command -v brew &>/dev/null; then
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_INSTALL_FROM_API=1
fi

# Bash history (infinite, deduplicated, shared across sessions)
shopt -s histappend
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth
export HISTTIMEFORMAT="%F %T  "
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

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
    if [ -d "$HOME/.epicli/shared/shared.d" ]; then
        for rc in "$HOME/.epicli/shared/shared.d"/*; do
            [ -f "$rc" ] && [[ "$rc" != *.archived ]] && [[ "$rc" != *.lst ]] && . "$rc"
        done
        unset rc
    fi
fi

# Local profile extras (installed with --local)
if [ -d ~/.local.d ]; then
    for rc in ~/.local.d/*; do
        [ -f "$rc" ] && [[ "$rc" != *.archived ]] && [[ "$rc" != *.lst ]] && . "$rc"
    done
    unset rc
fi

# Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
