#!/bin/bash
# Core platform configuration engine
# This script provides a generic, data-driven approach to platform configuration

# Configuration
PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$PLATFORM_DIR/data"
HOOKS_DIR="$PLATFORM_DIR/hooks"

# Detect package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apk &>/dev/null; then
        echo "apk"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Install packages using appropriate package manager
install_packages() {
    local pkg_manager="$1"
    shift
    local packages=("$@")
    
    echo "INFO: Installing packages with $pkg_manager..."
    
    case "$pkg_manager" in
        apt)
            if command -v sudo &>/dev/null; then
                sudo apt update
                sudo apt install -y "${packages[@]}"
            else
                apt update
                apt install -y "${packages[@]}"
            fi
            ;;
        dnf)
            if command -v sudo &>/dev/null; then
                sudo dnf install -y "${packages[@]}"
            else
                dnf install -y "${packages[@]}"
            fi
            ;;
        pacman)
            if command -v sudo &>/dev/null; then
                sudo pacman -Sy --noconfirm "${packages[@]}"
            else
                pacman -Sy --noconfirm "${packages[@]}"
            fi
            ;;
        apk)
            if command -v sudo &>/dev/null; then
                sudo apk update
                sudo apk add "${packages[@]}"
            else
                apk update
                apk add "${packages[@]}"
            fi
            ;;
        brew)
            brew install "${packages[@]}"
            ;;
        *)
            echo "WARN: Unknown package manager: $pkg_manager"
            return 1
            ;;
    esac
    
    echo "OK: Packages installed"
    return 0
}

# Read dependency file
read_dependency_file() {
    local dep_file="$1"
    local packages=()
    
    if [ ! -f "$dep_file" ]; then
        echo "WARN: Dependency file not found: $dep_file"
        return 1
    fi
    
    # Read packages from file, ignoring comments and empty lines
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi
        packages+=("$line")
    done < "$dep_file"
    
    echo "${packages[@]}"
    return 0
}

# Run hook scripts
run_hooks() {
    local hook_type="$1"
    local platform="$2"
    local hook_file=""
    
    # Run generic hooks first
    hook_file="$HOOKS_DIR/${hook_type}_pre.sh"
    if [ -f "$hook_file" ]; then
        echo "INFO: Running generic $hook_type hooks..."
        source "$hook_file"
    fi
    
    # Run platform-specific hooks
    hook_file="$HOOKS_DIR/${platform}_${hook_type}.sh"
    if [ -f "$hook_file" ]; then
        echo "INFO: Running $platform $hook_type hooks..."
        source "$hook_file"
    fi
}

# Main configuration function
configure_platform() {
    local platform="$1"
    local dep_file="$DATA_DIR/${platform}.deps"
    local packages=()
    local pkg_manager=""
    
    echo "INFO: Configuring platform: $platform"
    
    # Run pre-installation hooks
    run_hooks "pre" "$platform"
    
    # Detect package manager
    pkg_manager=$(detect_package_manager)
    echo "INFO: Detected package manager: $pkg_manager"
    
    # Read dependencies
    if [ -f "$dep_file" ]; then
        packages=($(read_dependency_file "$dep_file"))
        echo "INFO: Found ${#packages[@]} packages to install"
        
        # Install packages if any
        if [ ${#packages[@]} -gt 0 ]; then
            install_packages "$pkg_manager" "${packages[@]}"
        else
            echo "INFO: No packages to install"
        fi
    else
        echo "WARN: No dependency file found for $platform"
    fi
    
    # Run post-installation hooks
    run_hooks "post" "$platform"
    
    echo "OK: Platform configuration complete for $platform"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <platform>"
        echo "Available platforms:"
        ls "$DATA_DIR" | sed 's/\..*//'
        exit 1
    fi
    
    local platform="$1"
    configure_platform "$platform"
fi