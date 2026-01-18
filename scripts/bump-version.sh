#!/usr/bin/env bash
# Bump version in install.sh and latest file
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SH="$SCRIPT_DIR/install.sh"
LATEST_FILE="$SCRIPT_DIR/latest"

# Get current version
current=$(grep '^VERSION=' "$INSTALL_SH" | cut -d'"' -f2)
IFS='.' read -r major minor patch <<< "$current"

# Bump based on argument
case "${1:-patch}" in
    major) ((major++)); minor=0; patch=0 ;;
    minor) ((minor++)); patch=0 ;;
    patch) ((patch++)) ;;
    *) echo "Usage: $0 [major|minor|patch]"; exit 1 ;;
esac

new="$major.$minor.$patch"

# Update files
sed -i "s/^VERSION=\".*\"/VERSION=\"$new\"/" "$INSTALL_SH"
echo "$new" > "$LATEST_FILE"

echo "$current -> $new"
echo ""
echo "Next: make deploy SERVER=tldr.icu"
