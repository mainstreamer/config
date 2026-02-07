#!/bin/bash
# Fedora-specific platform configuration
# This file contains Fedora-specific setup that should run during installation

# Install Fedora-specific dependencies
install_fedora_deps() {
    echo "INFO: Installing Fedora-specific dependencies..."
    local deps=("@development-tools" "git" "curl" "wget" "cmake" "pkgconf-pkg-config" "openssl-devel" "zlib-devel")
    
    if command -v sudo &>/dev/null; then
        sudo dnf install -y "${deps[@]}"
        echo "OK: Fedora dependencies installed"
        return 0
    else
        echo "WARN: sudo not available, skipping Fedora dependency installation"
        return 1
    fi
}

# Main function that runs all Fedora-specific setup
main() {
    install_fedora_deps
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi