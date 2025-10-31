#!/bin/bash

# Tmux Window Name Generator
# Generates abbreviated window names from git repo root + branch
# Format: repo/branch (e.g., "dotfiles/main" -> "dot/mai")

# Get the current path from tmux
CURRENT_PATH="${1:-$(pwd)}"

# Function to abbreviate a name (keep first 3 chars of each word)
abbreviate() {
    local name="$1"

    # Handle hyphenated names (feature-branch -> fea-bra)
    if [[ "$name" == *"-"* ]]; then
        echo "$name" | awk -F'-' '{
            result = ""
            for (i = 1; i <= NF; i++) {
                if (i > 1) result = result "-"
                result = result substr($i, 1, 3)
            }
            print result
        }'
    # Handle camelCase names (featureBranch -> feaBra)
    elif [[ "$name" =~ [a-z][A-Z] ]]; then
        echo "$name" | sed -E 's/([a-z])([A-Z])/\1-\2/g' | awk -F'-' '{
            result = ""
            for (i = 1; i <= NF; i++) {
                if (i > 1) result = result "-"
                result = result substr($i, 1, 3)
            }
            print result
        }'
    # Handle underscore names (feature_branch -> fea_bra)
    elif [[ "$name" == *"_"* ]]; then
        echo "$name" | awk -F'_' '{
            result = ""
            for (i = 1; i <= NF; i++) {
                if (i > 1) result = result "_"
                result = result substr($i, 1, 3)
            }
            print result
        }'
    # Single word: just take first 3 chars
    else
        echo "${name:0:3}"
    fi
}

# Try to get git info
if git -C "$CURRENT_PATH" rev-parse --is-inside-work-tree &>/dev/null; then
    # Get git repository root
    GIT_ROOT=$(git -C "$CURRENT_PATH" rev-parse --show-toplevel 2>/dev/null)
    REPO_NAME=$(basename "$GIT_ROOT")

    # Get current branch
    BRANCH=$(git -C "$CURRENT_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Abbreviate both repo and branch
    REPO_ABBR=$(abbreviate "$REPO_NAME")
    BRANCH_ABBR=$(abbreviate "$BRANCH")

    echo "${REPO_ABBR}/${BRANCH_ABBR}"
else
    # Not in a git repo, just show abbreviated directory name
    DIR_NAME=$(basename "$CURRENT_PATH")
    abbreviate "$DIR_NAME"
fi
