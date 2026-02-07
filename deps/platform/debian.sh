#!/bin/bash
# Debian-specific platform configuration
# This file contains Debian-specific setup that should run during installation

# Fix dash vs bash issue (Debian uses dash as default /bin/sh)
fix_dash_bash() {
    if [ "$(readlink /bin/sh)" = "dash" ]; then
        echo "INFO: Detected dash as default shell, switching to bash for compatibility..."
        if command -v sudo &>/dev/null; then
            if sudo dpkg-reconfigure dash 2>/dev/null; then
                echo "OK: Successfully switched to bash as default shell"
                return 0
            else
                echo "WARN: Could not automatically switch shell"
                return 1
            fi
        else
            echo "WARN: sudo not available, cannot automatically fix dash/bash issue"
            return 1
        fi
    fi
    return 0
}

# Install Debian-specific dependencies
install_debian_deps() {
    echo "INFO: Installing Debian-specific dependencies..."
    local deps=("build-essential" "git" "curl" "wget" "cmake" "pkg-config" "libssl-dev" "zlib1g-dev")
    
    if command -v sudo &>/dev/null; then
        sudo apt update
        sudo apt install -y "${deps[@]}"
        echo "OK: Debian dependencies installed"
        return 0
    else
        echo "WARN: sudo not available, skipping Debian dependency installation"
        return 1
    fi
}

# Fix Debian-specific permission issues
fix_debian_permissions() {
    echo "INFO: Setting Debian-specific permissions..."
    chmod 755 ~
    chmod 755 ~/.config 2>/dev/null || true
    chmod 755 ~/.local 2>/dev/null || true
    echo "OK: Permissions set"
    return 0
}

# Main function that runs all Debian-specific setup
main() {
    fix_dash_bash
    install_debian_deps
    fix_debian_permissions
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi