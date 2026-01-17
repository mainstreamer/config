# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

export NODE_PATH=$(npm root -g)

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
    PATH="$PATH:$HOME/.cargo/bin"
    PATH="$PATH:$HOME/go/bin"
    # Composer global packages (location varies by system)
    [ -d "$HOME/.config/composer/vendor/bin" ] && PATH="$PATH:$HOME/.config/composer/vendor/bin"
    [ -d "$HOME/.composer/vendor/bin" ] && PATH="$PATH:$HOME/.composer/vendor/bin"
fi
export PATH

. "$HOME/.cargo/env"


# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# Files to skip when sourcing .bashrc.d/*
# - dep.lst: dependency list file, not a script
# - *.archived: deprecated scripts kept for reference
EXCLUDE_FILES=("dep.lst" "devprompt.archived")
# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            filename=$(basename "$rc")

            # Skip archived files and explicit exclusions
            if [[ "$filename" == *.archived ]]; then
                continue
            elif [[ " ${EXCLUDE_FILES[@]} " =~ " $filename " ]]; then
                continue
            else
                . "$rc"
            fi
        fi
    done
fi
unset rc
#Built Sun 20 Apr 02:00:07 BST 2025
