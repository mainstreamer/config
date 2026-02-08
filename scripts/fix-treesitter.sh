#!/usr/bin/env bash

# Fix treesitter configuration issues
# Usage: ./scripts/fix-treesitter.sh

echo "Fixing treesitter configuration..."

# Check if nvim is available
if ! command -v nvim &>/dev/null; then
    echo "Error: nvim not found. Please install Neovim first."
    exit 1
fi

# Try to install treesitter plugin first
echo "1/3 Ensuring treesitter plugin is installed..."
nvim --headless "+Lazy! install nvim-treesitter" +qa 2>/dev/null || {
    echo "Warning: Failed to install treesitter plugin"
}

# Install all parsers
echo "2/3 Installing treesitter parsers..."
nvim --headless "+TSInstall all" +qa 2>/dev/null || {
    echo "Warning: Failed to install all parsers, trying essential ones..."
    nvim --headless "+TSInstall lua vim bash javascript typescript python json" +qa 2>/dev/null || {
        echo "Error: Failed to install essential parsers"
        exit 1
    }
}

# Sync all plugins
echo "3/3 Syncing all plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || {
    echo "Warning: Plugin sync failed"
}

echo "Treesitter configuration fixed!"
echo "Please restart Neovim."