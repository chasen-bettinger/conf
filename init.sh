#!/usr/bin/env zsh 
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC_SOURCE="$REPO_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

# Back up existing .zshrc if it's not already a symlink to us
if [ -f "$ZSHRC_TARGET" ] && [ ! -L "$ZSHRC_TARGET" ]; then
    echo "Backing up existing ~/.zshrc to ~/.zshrc.backup"
    mv "$ZSHRC_TARGET" "$ZSHRC_TARGET.backup"
elif [ -L "$ZSHRC_TARGET" ]; then
    echo "Removing existing symlink at ~/.zshrc"
    rm "$ZSHRC_TARGET"
fi

ln -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
echo "Symlinked ~/.zshrc → $ZSHRC_SOURCE"

# Create .zshrc.local if it doesn't exist
if [ ! -f "$HOME/.zshrc.local" ]; then
    echo "# Machine-specific zsh config (not tracked by git)" > "$HOME/.zshrc.local"
    echo "Created ~/.zshrc.local for device-specific overrides"
fi

echo "Sourcing ~/.zshrc..."
source ~/.zshrc

echo "Done!"
