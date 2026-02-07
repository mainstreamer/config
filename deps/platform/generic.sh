#!/bin/bash
# Generic platform configuration
# This file contains platform-agnostic setup that should run on all systems

# Install bash-completion (should be available on all platforms)
install_bash_completion() {
    echo "INFO: Installing bash-completion..."
    
    if command -v apt &>/dev/null; then
        # Debian/Ubuntu
        if ! dpkg -l bash-completion &>/dev/null; then
            if command -v sudo &>/dev/null; then
                sudo apt update && sudo apt install -y bash-completion
                if [ -f /etc/bash_completion ]; then
                    source /etc/bash_completion
                    echo "OK: bash-completion installed (apt)"
                    return 0
                fi
            fi
        else
            echo "OK: bash-completion already installed (apt)"
            return 0
        fi
    elif command -v dnf &>/dev/null; then
        # Fedora
        if ! rpm -q bash-completion &>/dev/null; then
            if command -v sudo &>/dev/null; then
                sudo dnf install -y bash-completion
                echo "OK: bash-completion installed (dnf)"
                return 0
            fi
        else
            echo "OK: bash-completion already installed (dnf)"
            return 0
        fi
    elif command -v pacman &>/dev/null; then
        # Arch
        if ! pacman -Q bash-completion &>/dev/null; then
            if command -v sudo &>/dev/null; then
                sudo pacman -Sy --noconfirm bash-completion
                echo "OK: bash-completion installed (pacman)"
                return 0
            fi
        else
            echo "OK: bash-completion already installed (pacman)"
            return 0
        fi
    elif command -v apk &>/dev/null; then
        # Alpine
        if ! apk info -e bash-completion &>/dev/null; then
            if command -v sudo &>/dev/null; then
                sudo apk add bash-completion
                echo "OK: bash-completion installed (apk)"
                return 0
            fi
        else
            echo "OK: bash-completion already installed (apk)"
            return 0
        fi
    else
        echo "WARN: Cannot determine package manager, skipping bash-completion"
        return 1
    fi
}

# Set proper permissions (generic for all platforms)
fix_generic_permissions() {
    echo "INFO: Setting generic permissions..."
    chmod 755 ~
    chmod 755 ~/.config 2>/dev/null || true
    chmod 755 ~/.local 2>/dev/null || true
    echo "OK: Generic permissions set"
    return 0
}

# Main function that runs all generic setup
main() {
    install_bash_completion
    fix_generic_permissions
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi