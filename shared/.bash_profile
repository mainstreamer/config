# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Special handling for SSH sessions on Debian/Ubuntu
# These systems often don't create interactive shells for SSH
if [[ -n "$SSH_CONNECTION" ]] && [[ "$-" != *i* ]]; then
    # Force interactive behavior for SSH
    export PS1='\$ '
    # Re-source bashrc to ensure aliases are loaded
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi

# User specific environment and startup programs
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"