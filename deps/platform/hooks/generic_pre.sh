#!/bin/bash
# Generic pre-installation hook
# This runs BEFORE dependency installation on ALL platforms

# Install bash-completion
echo "INFO: Installing bash-completion..."
if command -v apt &>/dev/null; then
    # Debian/Ubuntu
    if ! dpkg -l bash-completion &>/dev/null; then
        if command -v sudo &>/dev/null; then
            sudo apt update && sudo apt install -y bash-completion
            if [ -f /etc/bash_completion ]; then
                source /etc/bash_completion
                echo "OK: bash-completion installed"
            fi
        fi
    else
        echo "OK: bash-completion already installed"
    fi
elif command -v dnf &>/dev/null; then
    # Fedora
    if ! rpm -q bash-completion &>/dev/null; then
        if command -v sudo &>/dev/null; then
            sudo dnf install -y bash-completion
            echo "OK: bash-completion installed"
        fi
    else
        echo "OK: bash-completion already installed"
    fi
elif command -v pacman &>/dev/null; then
    # Arch
    if ! pacman -Q bash-completion &>/dev/null; then
        if command -v sudo &>/dev/null; then
            sudo pacman -Sy --noconfirm bash-completion
            echo "OK: bash-completion installed"
        fi
    else
        echo "OK: bash-completion already installed"
    fi
elif command -v apk &>/dev/null; then
    # Alpine
    if ! apk info -e bash-completion &>/dev/null; then
        if command -v sudo &>/dev/null; then
            sudo apk add bash-completion
            echo "OK: bash-completion installed"
        fi
    else
        echo "OK: bash-completion already installed"
    fi
else
    echo "WARN: Cannot determine package manager, skipping bash-completion"
fi

# Set generic permissions
echo "INFO: Setting generic permissions..."
chmod 755 ~
chmod 755 ~/.config 2>/dev/null || true
chmod 755 ~/.local 2>/dev/null || true
echo "OK: Permissions set"