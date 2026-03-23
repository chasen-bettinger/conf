#!/usr/bin/env zsh 
set -e

echo "\$0 :>> $0"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSHRC_SOURCE="$REPO_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"
PLUGINS_FILE="$REPO_DIR/oh-my-zsh-plugins/plugins.txt"
CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
STARSHIP_CONFIG="$HOME/.config/starship.toml"
brew_install() {
    local pkg="$1"
    if ! brew list "$pkg" &> /dev/null; then
        echo "Missing $pkg.. installing $pkg..."
        brew install "$pkg"
    fi
}

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

CLAUDE_MD_SOURCE="$REPO_DIR/CLAUDE.md"
CLAUDE_MD_TARGET="$HOME/.claude/CLAUDE.md"

link_file "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
link_file "$CLAUDE_MD_SOURCE" "$CLAUDE_MD_TARGET"


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

brew_install atuin
brew_install nono
brew_install gh

if ! command -v bw &> /dev/null; then
    echo "Missing bw.. installing bitwarden cli..."
    "$REPO_DIR/add-bw"
fi

if ! command -v gitleaks &> /dev/null; then
    echo "Missing gitleaks.. installing gitleaks..."
    "$REPO_DIR/add-gitleaks"
fi

# Create chasen-learnings directory for knowledge notes
if [ ! -d "$HOME/Documents/chasen-learnings" ]; then
    mkdir -p "$HOME/Documents/chasen-learnings"
    echo "Created ~/Documents/chasen-learnings"
fi

# Create .zshrc.local if it doesn't exist
if [ ! -f "$HOME/.zshrc.local" ]; then
    echo "# Machine-specific zsh config (not tracked by git)" > "$HOME/.zshrc.local"
    echo "Created ~/.zshrc.local for device-specific overrides"
fi

echo "Sourcing ~/.zshrc..."
source ~/.zshrc

echo "Done!"
