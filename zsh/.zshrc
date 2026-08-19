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
# Git Diff Tooling (lazygit + difftastic)
# ============================================================================
# On macOS lazygit reads ~/Library/Application Support/lazygit/config.yml by
# default, so the stowed ~/.config/lazygit/config.yml would be ignored.
# LG_CONFIG_FILE points lazygit at the stowed config instead of exporting
# XDG_CONFIG_HOME, which would silently relocate the config lookup of every
# other XDG-aware tool on the machine. Redundant but harmless on Linux, where
# ~/.config/lazygit is already the default. lazygit keeps its state files in the
# platform default dir either way, which is correct - state is not dotfiles.
if [ -f "$HOME/.config/lazygit/config.yml" ]; then
  export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
fi

# difftastic: render diffs inline (single column). Upstream's default,
# side-by-side, wants ~160 columns; in a half-width tmux pane it degrades badly
# - long TypeScript lines wrap and the column alignment breaks. Inline spends
# the whole pane width on one column instead.
# Accepted values: side-by-side | side-by-side-show-both | inline | json
# This is inherited by lazygit's extDiff child process too, which is why the
# renderer command in config/.config/lazygit/config.yml carries no --display
# flag - one place to change the mode, not two.
export DFT_DISPLAY="inline"

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

# Wrapper for git worktree add that also links Husky into the new worktree
# Usage: gwa <path> <branch>
# Example: gwa worktrees/feat-new-feature feat-new-feature
gwa() {
    if [ $# -eq 0 ]; then
        echo "Usage: gwa <path> <branch>"
        echo "Example: gwa worktrees/feat-new-feature feat-new-feature"
        return 1
    fi

    # Run git worktree add with all arguments, propagating git's exit status so
    # callers (workt, scripts) can tell a failed add from a successful one.
    git worktree add "$@" || return $?

    echo "✅ Worktree created: $1"

    # The post-checkout hook should link Husky, but do it here too. The
    # relative-path logic lives in exactly ONE place - the helper script below -
    # shared with fix-husky-worktree() and tmux-worktree-session.sh.
    local husky_link="$HOME/.config/tmux/scripts/git-husky-worktree-link.sh"

    if [ ! -x "$husky_link" ]; then
        echo "⚠️  Husky link skipped - not found or not executable: $husky_link"
        echo "   Run 'stow config' from ~/dotfiles to deploy it"
        return 0
    fi

    # --force replaces the real .husky that git worktree add just checked out
    "$husky_link" --force "$1"
}

# Fix the Husky symlink in an existing worktree
# Usage: fix-husky-worktree [worktree-path]   (defaults to the current directory)
fix-husky-worktree() {
    local husky_link="$HOME/.config/tmux/scripts/git-husky-worktree-link.sh"

    if [ ! -x "$husky_link" ]; then
        echo "❌ Not found or not executable: $husky_link"
        echo "   Run 'stow config' from ~/dotfiles to deploy it"
        return 1
    fi

    # --force replaces a real .husky directory left behind by an earlier install
    "$husky_link" --force "${1:-$PWD}"
}

# ============================================================================
# Tmux Work Layout
# ============================================================================

# Build a 3-pane dev layout (lazygit / shell on the left, claude on the right)
# rooted at a directory. Re-running from the same directory reuses the window.
# Usage: work [path]
# Example: work            # current directory
#          work ~/dotfiles
work() {
    local script="$HOME/.config/tmux/scripts/tmux-work-session.sh"

    if [ ! -x "$script" ]; then
        echo "❌ Not found or not executable: $script"
        echo "   Run 'stow config' from ~/dotfiles to deploy it"
        return 1
    fi

    "$script" "${1:-$PWD}"
}

# Same as work, but the 4-pane vertical variant: lazygit / shell on the left
# (40%), nvim in the middle (30%), claude on the right (30%). A directory can
# hold a work window and a vwork window at once; each reuses only its own.
# Usage: vwork [path]
# Example: vwork            # current directory
#          vwork ~/dotfiles
vwork() {
    local script="$HOME/.config/tmux/scripts/tmux-work-session.sh"

    if [ ! -x "$script" ]; then
        echo "❌ Not found or not executable: $script"
        echo "   Run 'stow config' from ~/dotfiles to deploy it"
        return 1
    fi

    "$script" --vertical "${1:-$PWD}"
}

# Create a git worktree for a branch, then open the work layout inside it.
# The worktree lands at <main-repo-root>/worktrees/<branch>, with '/' flattened
# to '-' for the DIRECTORY name only - the branch keeps its real name.
# Prompts when the branch already exists locally or only on origin.
# Usage: workt [branch]
# Example: workt feat/login   # branch feat/login in worktrees/feat-login
#          workt              # prompts for the branch name
workt() {
    local script="$HOME/.config/tmux/scripts/tmux-worktree-session.sh"

    if [ ! -x "$script" ]; then
        echo "❌ Not found or not executable: $script"
        echo "   Run 'stow config' from ~/dotfiles to deploy it"
        return 1
    fi

    "$script" "$@"
}

# Same as workt, but opens the 4-pane vertical layout (see vwork) in the
# worktree instead of the 3-pane default.
# Usage: vworkt [branch]
# Example: vworkt feat/login   # branch feat/login in worktrees/feat-login
#          vworkt              # prompts for the branch name
vworkt() {
    local script="$HOME/.config/tmux/scripts/tmux-worktree-session.sh"

    if [ ! -x "$script" ]; then
        echo "❌ Not found or not executable: $script"
        echo "   Run 'stow config' from ~/dotfiles to deploy it"
        return 1
    fi

    "$script" --vertical "$@"
}

export PATH="$HOME/.local/bin:$PATH"

#. "$HOME/.local/bin/env"


# Machine-local overrides (work paths, secrets) — not tracked in git.
# Create ~/.zshrc.local on machines that need extra sourcing (see zsh/.zshrc.local.template).
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
