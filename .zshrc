#!/bin/bashz

if type brew &>/dev/null; then
   FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
  fi


#zstyle ':completion:*:*:git:*' script /usr/local/etc/bash_completion # here should be your path to the file
fpath=(~/.zsh $fpath)

function prompt_version {
 echo "$( php -v | grep -o '[5,7,8]\.[0-9]\.[0-9]' -m 1)"
}

function git_branch {
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {sub("refs/heads/", ""); print $0 }')
  [[ $branch != "" ]] && echo ' ~>('$branch')'
}

function git_dirty {
 if [[ $(git status --porcelain 2> /dev/null) ]]; then
  [[ $(date +%u) -lt 5 && $(date +%H) -lt 20 ]] && echo "🐼" || echo "🐁"
 fi
}

function prompt {
 PROMPT="[%F{cyan}$(prompt_version)%f] %n@%~%F{cyan}$(git_branch)%f$(git_dirty) $ "
 RPROMPT="%F{cyan}[%w, %*]%f"
}

precmd_functions+=(prompt) # reload prompt each time it is shown
autoload -Uz compinit promptinit # loads autocomplete features

function change_docker_context {
    if [ -z "$1" ]; then
        docker context use desktop-linux
    else
        docker context use "$1"
    fi
}

function view {
    curl -s "$1" | imgcat
}

function imgk_remote {
    if [ $# -eq 2 ]; then
       imgcat -W "$2" -u "$1"
    else
       imgcat -u "$1"
    fi
}

function open_w_imgk {
    if [ $# -eq 2 ]; then
        imgcat -W "$2" "$1"
    else
       imgcat "$1"
    fi
}

function up_dir {
    cd ..
    prompt
    zle reset-prompt
}
zle -N up_dir
#option + delete
bindkey ";5K" up_dir 

delete-selection(){
  local s=$(pbpaste)
  BUFFER="${BUFFER:0:$CURSOR}${BUFFER:$CURSOR+${#s}}"
}
zle -N delete-selection
#shift+delete
bindkey ";11D" delete-selection


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
autoload -Uz compinit && compinit

alias dc='docker compose'
alias d='docker'
alias dce='docker compose exec -it'
alias ::='make -- --'
alias ds='docker stop $(docker ps -q)'
alias 'cdc'='change_docker_context'
alias gpom='git push origin master'
alias gcb='git checkout -b'
alias gcq='git commit -a -m "commit $(date)"' 
alias gca='git commit -a -m '
alias gc='git commit'
alias c=view
alias i=open_w_imgk
alias iu=imgk_remote
alias ..=up_dir

autoload -Uz compinit && compinit
export PATH="/usr/local/opt/node@18/bin:$PATH"
export PATH="/usr/local/opt/node@14/bin:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
bindkey '^F' fzf-cd-widget

#Glasgow Haskell Compiler
[ -f "/Users/artem/.ghcup/env" ] && source "/Users/artem/.ghcup/env" # ghcup-envexport PATH="/usr/local/sbin:$PATH"

# Navigate to the beginning of the previous word
bindkey ";9D" backward-word #option + arrow left

# Navigate to the beginning of the next word
bindkey ";9C" forward-word #option + arrow right

