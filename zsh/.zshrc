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

# Plugins
plugins=(
    git
    web-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    you-should-use
    zsh-bat
    zsh-interactive-cd
)

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

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# ============================================================================
# Starship Prompt (replaces Oh My Zsh theme)
# ============================================================================
# Install with: brew install starship
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
