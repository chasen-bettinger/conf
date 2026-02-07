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

# Install oh-my-zsh custom plugins
PLUGINS_FILE="$REPO_DIR/oh-my-zsh-plugins/plugins.txt"
CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

if [ -f "$PLUGINS_FILE" ]; then
    while read -r name url; do
        [ -z "$name" ] && continue
        dest="$CUSTOM_PLUGINS_DIR/$name"
        if [ -d "$dest" ]; then
            echo "Plugin $name already installed, pulling latest..."
            git -C "$dest" pull --quiet
        else
            echo "Cloning plugin $name..."
            git clone --quiet "$url" "$dest"
        fi
    done < "$PLUGINS_FILE"
fi

# Create .zshrc.local if it doesn't exist
if [ ! -f "$HOME/.zshrc.local" ]; then
    echo "# Machine-specific zsh config (not tracked by git)" > "$HOME/.zshrc.local"
    echo "Created ~/.zshrc.local for device-specific overrides"
fi

echo "Sourcing ~/.zshrc..."
source ~/.zshrc

echo "Done!"
