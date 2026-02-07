#!/bin/bash
# Arch Linux-specific platform configuration
# This file contains Arch-specific setup that should run during installation

# Install Arch-specific dependencies
install_arch_deps() {
    echo "INFO: Installing Arch-specific dependencies..."
    local deps=("base-devel" "git" "curl" "wget" "cmake" "pkgconf" "openssl" "zlib")
    
    if command -v sudo &>/dev/null; then
        sudo pacman -Syu --noconfirm "${deps[@]}"
        echo "OK: Arch dependencies installed"
        return 0
    else
        echo "WARN: sudo not available, skipping Arch dependency installation"
        return 1
    fi
}

# Main function that runs all Arch-specific setup
main() {
    install_arch_deps
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi