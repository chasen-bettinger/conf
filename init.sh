#!/usr/bin/env zsh 
set -e

echo "\$0 :>> $0"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC_SOURCE="$REPO_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"
PLUGINS_FILE="$REPO_DIR/oh-my-zsh-plugins/plugins.txt"
CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
ATUIN=$(brew list | grep "atuin" || echo "missing")

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


if [ ! -f "$STARSHIP_CONFIG" ]; then
    echo "Missing startship config.. installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null 2>&1
fi

if [[ "$ATUIN" == "missing" ]]; then
    echo "Missing atuin.. installing atuin..."
    brew install atuin
fi

# Create .zshrc.local if it doesn't exist
if [ ! -f "$HOME/.zshrc.local" ]; then
    echo "# Machine-specific zsh config (not tracked by git)" > "$HOME/.zshrc.local"
    echo "Created ~/.zshrc.local for device-specific overrides"
fi

echo "Sourcing ~/.zshrc..."
source ~/.zshrc

echo "Done!"
