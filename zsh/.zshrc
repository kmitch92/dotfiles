# Created by newuser for 5.9

# Source system-wide profile if it exists
if [[ -f /etc/zprofile ]]; then
    source /etc/zprofile
fi

# Homebrew PATH setup
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Apple Silicon Mac
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    # Intel Mac
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# ============================================================================
# Oh My Zsh Configuration
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Theme - commented out to use Starship instead
# ZSH_THEME="darkblood"

# Update behavior
zstyle ':omz:update' mode reminder

# Plugins - base plugins
plugins=(
    git
    web-search
    zsh-interactive-cd
)

# Add optional plugins if they exist
[[ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]] && plugins+=(zsh-autosuggestions)
[[ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]] && plugins+=(zsh-syntax-highlighting)
[[ -d "$ZSH/custom/plugins/you-should-use" ]] && plugins+=(you-should-use)
[[ -d "$ZSH/custom/plugins/zsh-bat" ]] && plugins+=(zsh-bat)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# Editor Configuration
# ============================================================================
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Linux/Ubuntu specific - snap code environment
if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f "$HOME/snap/code/209/.local/share/../bin/env" ]]; then
    . "$HOME/snap/code/209/.local/share/../bin/env"
fi

# ============================================================================
# Aliases
# ============================================================================
# kvim - launch the kickstart.nvim trial config (isolated from LazyVim `nvim`)
alias kvim='NVIM_APPNAME=nvim-kickstart nvim'

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# ============================================================================
# Starship Prompt (replaces Oh My Zsh theme)
# ============================================================================
# Install with: brew install starship
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# ============================================================================
# zoxide + fzf - smarter navigation
# ============================================================================
# zoxide - smarter cd (z <dir> to jump, zi for fzf interactive pick)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# fzf key bindings and fuzzy completion (Ctrl-T files, Ctrl-R history, Alt-C cd)
if command -v fzf &>/dev/null; then
  source <(fzf --zsh) 2>/dev/null || true
fi

# ============================================================================
# tmux Auto-Start
# ============================================================================
# Automatically start tmux for interactive shells
# To disable, set: export DISABLE_AUTO_TMUX=true
if command -v tmux &> /dev/null; then
    # Only start tmux if:
    # 1. Not already in tmux
    # 2. Not disabled via environment variable
    # 3. This is an interactive shell
    # 4. Not in an IDE terminal (VS Code, etc.)
    if [[ -z "$TMUX" ]] && \
       [[ "${DISABLE_AUTO_TMUX:-false}" != "true" ]] && \
       [[ $- == *i* ]] && \
       [[ -z "$VSCODE_INJECTION" ]] && \
       [[ -z "$TERM_PROGRAM" ]]; then
        # Attach to existing session or create new one
        tmux attach-session -t default || tmux new-session -s default
    fi
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ============================================================================
# Git Worktree Helpers - Auto-fix Husky
# ============================================================================

# Wrapper for git worktree add that automatically creates Husky symlink
# Usage: gwa <path> <branch>
# Example: gwa worktrees/feat-new-feature feat-new-feature
gwa() {
    if [ $# -eq 0 ]; then
        echo "Usage: gwa <path> <branch>"
        echo "Example: gwa worktrees/feat-new-feature feat-new-feature"
        return 1
    fi

    # Run git worktree add with all arguments
    git worktree add "$@"

    # If successful, create symlink (post-checkout hook should handle this, but just in case)
    if [ $? -eq 0 ]; then
        local worktree_path="$1"

        # Find the main repo root (where .git directory is)
        local main_repo=$(git rev-parse --git-common-dir | sed 's|/.git$||')

        # Calculate relative path from worktree to main repo .husky
        local relative_husky=$(python3 -c "import os.path; print(os.path.relpath('$main_repo/.husky', '$worktree_path'))" 2>/dev/null)

        # Fallback to simple relative path if Python fails
        if [ -z "$relative_husky" ]; then
            relative_husky="../../.husky"
        fi

        # Create symlink if it doesn't exist
        if [ ! -e "$worktree_path/.husky" ]; then
            ln -sf "$relative_husky" "$worktree_path/.husky"
            echo "✅ Worktree created with Husky symlink"
        else
            echo "✅ Worktree created (Husky already configured)"
        fi
    fi
}

# Fix existing worktree Husky symlink
# Usage: fix-husky-worktree (run from within worktree directory)
fix-husky-worktree() {
    # Check if we're in a worktree (worktrees have .git file, not directory)
    if [ -f .git ]; then
        local main_repo=$(git rev-parse --git-common-dir | sed 's|/.git/worktrees/.*$||')
        local current_dir=$(pwd)
        local relative_husky=$(python3 -c "import os.path; print(os.path.relpath('$main_repo/.husky', '$current_dir'))" 2>/dev/null)

        # Fallback to simple relative path if Python fails
        if [ -z "$relative_husky" ]; then
            relative_husky="../../.husky"
        fi

        # Remove existing .husky if not a symlink
        if [ -e .husky ] && [ ! -L .husky ]; then
            rm -rf .husky
        fi

        ln -sf "$relative_husky" .husky
        echo "✅ Husky symlink fixed: .husky -> $relative_husky"
    else
        echo "❌ Not in a worktree (or already in main repo)"
        echo "   Worktrees have a .git file (not directory)"
    fi
}

export PATH="$HOME/.local/bin:$PATH"

#. "$HOME/.local/bin/env"


# Machine-local overrides (work paths, secrets) — not tracked in git.
# Create ~/.zshrc.local on machines that need extra sourcing (see zsh/.zshrc.local.template).
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
