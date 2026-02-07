#!/bin/bash
# macOS-specific platform configuration
# This file contains macOS-specific setup that should run during installation

# Install macOS-specific dependencies using Homebrew
install_macos_deps() {
    echo "INFO: Installing macOS-specific dependencies..."
    
    # Check if Homebrew is available
    if ! command -v brew &>/dev/null; then
        echo "WARN: Homebrew not found, skipping macOS dependency installation"
        return 1
    fi
    
    # Install common macOS dependencies
    local deps=("cmake" "pkg-config" "openssl" "zlib")
    
    brew install "${deps[@]}"
    echo "OK: macOS dependencies installed"
    return 0
}

# Main function that runs all macOS-specific setup
main() {
    install_macos_deps
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi