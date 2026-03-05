#!/usr/bin/env bash
# Bump version in install.sh and latest file, then deploy + push
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SH="$SCRIPT_DIR/install.sh"
LATEST_FILE="$SCRIPT_DIR/latest"

# Get current version
current=$(grep '^VERSION=' "$INSTALL_SH" | cut -d'"' -f2)
IFS='.' read -r major minor patch <<< "$current"

# Bump based on argument
case "${1:-patch}" in
    major) ((major = major +1)); minor=0; patch=0 ;;
    minor) ((minor = minor +1)); patch=0 ;;
    patch) ((patch = patch +1)) ;;
    *) echo "Usage: $0 [major|minor|patch]"; exit 1 ;;
esac

new="$major.$minor.$patch"

# Update files
sed -i "s/^VERSION=\".*\"/VERSION=\"$new\"/" "$INSTALL_SH"
echo "$new" > "$LATEST_FILE"

echo "Version: $current -> $new"

# Commit and tag
cd "$SCRIPT_DIR"
git add install.sh latest
git commit -m "v$new"
git tag "v$new"

# Deploy to server (archive + sign + scp)
echo ""
make deploy

# Push commit and tag -> triggers GitHub Actions for GH release + Homebrew
echo ""
echo "Pushing to origin..."
git push
git push --tags

echo ""
echo "Done! v$new deployed to server and pushed to GitHub."
echo "GitHub Actions will create the release and update Homebrew."
