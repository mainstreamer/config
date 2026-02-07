# .bashrc - Linux entry point
# Sources shared scripts from ~/.shellrc.d/

# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# Environment
export SHELL_TYPE="bash"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/go/bin"
[ -d "$HOME/.config/composer/vendor/bin" ] && export PATH="$PATH:$HOME/.config/composer/vendor/bin"
[ -d "$HOME/.composer/vendor/bin" ] && export PATH="$PATH:$HOME/.composer/vendor/bin"

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Source all scripts from .shellrc.d
if [ -d ~/.shellrc.d ]; then
    for rc in ~/.shellrc.d/*; do
        [ -f "$rc" ] && [[ "$rc" != *.archived ]] && [[ "$rc" != *.lst ]] && . "$rc"
    done
    unset rc
fi

# opencode
export PATH=/home/stx/.opencode/bin:$PATH
