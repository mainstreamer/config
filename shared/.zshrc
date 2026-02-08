# .zshrc - macOS entry point
# Sources shared scripts from ~/.shared.d/

# Homebrew completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$(brew --prefix)/share/zsh-completions:$FPATH"
fi

autoload -Uz compinit && compinit
autoload -Uz promptinit && promptinit

# Environment
export SHELL_TYPE="zsh"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="$PATH:$HOME/.cargo/bin"

# macOS specific paths
[ -d "/opt/homebrew/bin" ] && export PATH="/opt/homebrew/bin:$PATH"
[ -d "/usr/local/bin" ] && export PATH="/usr/local/bin:$PATH"

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

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Source all scripts from shared.d
if [ -d ~/.shared.d ]; then
    for rc in ~/.shared.d/*; do
        [ -f "$rc" ] && [[ "$rc" != *.archived ]] && [[ "$rc" != *.lst ]] && . "$rc"
    done
    unset rc
fi
