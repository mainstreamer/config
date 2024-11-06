#!/bin/bashz

if type brew &>/dev/null; then
   FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
  fi

#zstyle ':completion:*:*:git:*' script /usr/local/etc/bash_completion # here should be your path to the file
fpath=(~/.zsh $fpath)


# User specific aliases and functions
if [ -d ~/.zshrc.d ]; then
    for rc in ~/.zshrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc


autoload -Uz compinit promptinit # loads autocomplete features



# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
autoload -Uz compinit && compinit






# autoload -Uz compinit && compinit
export PATH="/usr/local/opt/node@18/bin:$PATH"
# export PATH="/usr/local/opt/node@14/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey '^F' fzf-cd-widget

#Glasgow Haskell Compiler
#[ -f "/Users/artem/.ghcup/env" ] && source "/Users/artem/.ghcup/env" # ghcup-envexport PATH="/usr/local/sbin:$PATH"

#Built Wed  6 Nov 2024 16:05:50 GMT
