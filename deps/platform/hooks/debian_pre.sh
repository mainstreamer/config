#!/bin/bash
# Debian pre-installation hook
# This runs BEFORE dependency installation on Debian systems

# Fix dash vs bash issue
echo "INFO: Checking Debian shell configuration..."
if [ "$(readlink /bin/sh)" = "dash" ]; then
    echo "INFO: Detected dash as default shell, switching to bash..."
    if command -v sudo &>/dev/null; then
        if sudo dpkg-reconfigure dash 2>/dev/null; then
            echo "OK: Successfully switched to bash as default shell"
        else
            echo "WARN: Could not automatically switch shell"
            echo "Please run: sudo dpkg-reconfigure dash and select 'No'"
        fi
    else
        echo "WARN: sudo not available, cannot fix dash/bash issue"
    fi
fi