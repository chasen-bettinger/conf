#!/bin/bash
set -e

FILE_PATH="$1"

# --- Validations (fail fast) ---

if [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 <file-path>"
    echo "Removes a file from the working tree and purges it from all git history."
    exit 1
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a git repository."
    echo "Run this script from within a git repo."
    exit 1
fi

if ! command -v git-filter-repo > /dev/null 2>&1; then
    echo "Error: git-filter-repo is not installed."
    echo "Install it with: brew install git-filter-repo"
    exit 1
fi

COMMIT_COUNT=$(git log --all --oneline -- "$FILE_PATH" | wc -l | tr -d ' ')

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "Error: '$FILE_PATH' not found in git history."
    echo "Check the path and try again. Use a path relative to the repo root."
    exit 1
fi

# --- Confirmation ---

echo "Found '$FILE_PATH' in $COMMIT_COUNT commit(s)."
echo ""
echo "This will:"
echo "  - Rewrite git history to remove '$FILE_PATH' from ALL commits"
echo "  - Delete '$FILE_PATH' from the working tree if it still exists"
echo ""
echo "This is IRREVERSIBLE. All collaborators will need to re-clone."
echo ""
read -r -p "Proceed? [y/N] " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

# --- Purge ---

echo "Rewriting history..."
git filter-repo --invert-paths --path "$FILE_PATH" --force

if [ -f "$FILE_PATH" ]; then
    rm "$FILE_PATH"
    echo "Removed '$FILE_PATH' from working tree."
fi

# --- Verification ---

REMAINING=$(git log --all --oneline -- "$FILE_PATH" | wc -l | tr -d ' ')

if [ "$REMAINING" -ne 0 ]; then
    echo "ERROR: '$FILE_PATH' still appears in $REMAINING commit(s) after purge."
    echo "This can happen when:"
    echo "  - The file exists under other refs (tags, stashes, etc.)"
    echo "  - There are packed refs that weren't rewritten"
    echo ""
    echo "Try running manually:"
    echo "  git reflog expire --expire=now --all"
    echo "  git gc --prune=now --aggressive"
    echo "  git filter-repo --invert-paths --path '$FILE_PATH' --force"
    exit 1
fi

echo "Verified: '$FILE_PATH' has been purged from all git history."
