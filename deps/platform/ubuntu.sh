#!/bin/bash
# Ubuntu-specific platform configuration
# This file contains Ubuntu-specific setup that should run during installation

# Install Ubuntu-specific dependencies
install_ubuntu_deps() {
    echo "INFO: Installing Ubuntu-specific dependencies..."
    local deps=("build-essential" "git" "curl" "wget" "cmake" "pkg-config" "libssl-dev" "zlib1g-dev")
    
    if command -v sudo &>/dev/null; then
        sudo apt update
        sudo apt install -y "${deps[@]}"
        echo "OK: Ubuntu dependencies installed"
        return 0
    else
        echo "WARN: sudo not available, skipping Ubuntu dependency installation"
        return 1
    fi
}

# Main function that runs all Ubuntu-specific setup
main() {
    install_ubuntu_deps
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi