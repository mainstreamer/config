#!/bin/bash
# Alpine Linux-specific platform configuration
# This file contains Alpine-specific setup that should run during installation

# Install Alpine-specific dependencies
install_alpine_deps() {
    echo "INFO: Installing Alpine-specific dependencies..."
    local deps=("build-base" "git" "curl" "wget" "cmake" "pkgconf" "openssl-dev" "zlib-dev" "bash")
    
    if command -v sudo &>/dev/null; then
        sudo apk update
        sudo apk add "${deps[@]}"
        echo "OK: Alpine dependencies installed"
        return 0
    else
        echo "WARN: sudo not available, skipping Alpine dependency installation"
        return 1
    fi
}

# Main function that runs all Alpine-specific setup
main() {
    install_alpine_deps
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi