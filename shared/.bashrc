# .bashrc - Linux entry point
# Sources shared scripts from ~/.shared.d/

# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# Environment
export SHELL_TYPE="bash"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="$PATH:$HOME/.cargo/bin"

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Dev-mode paths (only if installed)
[ -d "$HOME/go/bin" ] && export PATH="$PATH:$HOME/go/bin"
[ -d "$HOME/.config/composer/vendor/bin" ] && export PATH="$PATH:$HOME/.config/composer/vendor/bin"
[ -d "$HOME/.composer/vendor/bin" ] && export PATH="$PATH:$HOME/.composer/vendor/bin"

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
fi
