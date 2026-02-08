# .profile - System-wide login configuration
# This file is read by bash (if .bash_profile missing) and other shells

# Source .bashrc for bash users
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Set PATH for user's private bin directories
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Load any user-specific environment variables
if [ -f "$HOME/.environment" ]; then
    . "$HOME/.environment"
fi

export PATH