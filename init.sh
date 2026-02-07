#!/usr/bin/env zsh 
set -e

echo "\$0 :>> $0"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC_SOURCE="$REPO_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"
P10K_SOURCE="$REPO_DIR/.p10k.zsh"
P10K_TARGET="$HOME/.p10k.zsh"

link_file() {
    local src="$1"
    local dest="$2"
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing $dest to $dest.backup"
        mv "$dest" "$dest.backup"
    elif [ -L "$dest" ]; then
        echo "Removing existing symlink at $dest"
        rm "$dest"
    fi
    ln -s "$src" "$dest"
    echo "Symlinked $dest → $src"
}

link_file "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
link_file "$P10K_SOURCE" "$P10K_TARGET"


# Create .zshrc.local if it doesn't exist
if [ ! -f "$HOME/.zshrc.local" ]; then
    echo "# Machine-specific zsh config (not tracked by git)" > "$HOME/.zshrc.local"
    echo "Created ~/.zshrc.local for device-specific overrides"
fi

echo "Sourcing ~/.zshrc..."
source ~/.zshrc

echo "Done!"
