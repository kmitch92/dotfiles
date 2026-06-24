#!/bin/bash

# =============================================================================
# Dotfiles Installation - Main Orchestrator
# =============================================================================
# Modular installation script that bootstraps a new development environment
#
# Usage: ./install.sh [OPTIONS]
# Options:
#   --skip-optional    Skip all optional installations (fonts, docker, etc)
#   --yes, -y          Automatically answer yes to all prompts (non-interactive)
# =============================================================================

set -e  # Exit on error

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Determine OS-specific script directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_SCRIPTS_DIR="$SCRIPTS_DIR/macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_SCRIPTS_DIR="$SCRIPTS_DIR/linux"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Parse arguments
SKIP_OPTIONAL=false
export AUTO_CONFIRM=false

for arg in "$@"; do
    case "$arg" in
        --skip-optional)
            SKIP_OPTIONAL=true
            ;;
        --yes|-y)
            AUTO_CONFIRM=true
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-optional    Skip all optional installations"
            echo "  --yes, -y          Automatically answer yes to all prompts"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Source utilities
source "$SCRIPTS_DIR/utils.sh"

# Initialize installation tracking (bash 3.2 compatible)
INSTALL_LOG="$DOTFILES_DIR/.install.log"
INSTALL_STATUS_FILE="$DOTFILES_DIR/.install_status"
echo "=== Installation started at $(date) ===" > "$INSTALL_LOG"
echo "" > "$INSTALL_STATUS_FILE"

# =============================================================================
# Main Installation Flow
# =============================================================================

print_header "Dotfiles Installation"
echo "Source: $DOTFILES_DIR"
echo "Target: $HOME"
echo "OS: $(uname -s)"
if $SKIP_OPTIONAL; then
    print_info "Running in minimal mode (--skip-optional)"
fi
echo ""

# Step 1: Install Homebrew (macOS only)
if is_macos; then
    run_step "Homebrew" "install-homebrew.sh" "required"
fi

# Step 2: Install system packages (stow, git, curl, wget, etc.)
run_step "System Packages" "install-packages.sh" "required"

# Step 3: Install fonts (OS-specific)
if ! $SKIP_OPTIONAL; then
    if is_macos; then
        run_step "Fonts" "macos/install-fonts.sh" "optional"
    elif is_linux; then
        run_step "Fonts" "linux/install-fonts.sh" "optional"
    fi
fi

# Step 3.5: Install Terminal Emulators
if ! $SKIP_OPTIONAL; then
    run_step "Terminal Emulators" "install-terminals.sh" "optional"
fi

# Step 4: Install development runtimes (Python, Node, npm)
run_step "Development Runtimes" "install-runtimes.sh" "optional"

# Step 5: Install development tools (neovim, tmux, starship, etc.) - OS-specific
if is_macos; then
    run_step "Development Tools" "macos/install-dev-tools.sh" "optional"
elif is_linux; then
    run_step "Development Tools" "linux/install-dev-tools.sh" "optional"
fi

# Step 6: Install Docker and Docker Desktop - OS-specific
if ! $SKIP_OPTIONAL; then
    if is_macos; then
        run_step "Docker" "macos/install-docker.sh" "optional"
    elif is_linux; then
        run_step "Docker" "linux/install-docker.sh" "optional"
    fi
fi

# Step 7: Install Claude Code
if ! $SKIP_OPTIONAL; then
    run_step "Claude Code" "install-claude-code.sh" "optional"
fi

# Step 8: Install shell tools (Oh My Zsh, plugins)
run_step "Shell Tools" "install-shell-tools.sh" "optional"

# Step 9: Setup shell configuration
run_step "Shell Configuration" "setup-shell.sh" "required"

# Step 10: Stow dotfiles
run_step "Dotfiles Stow" "setup-stow.sh" "required"

# =============================================================================
# Installation Summary
# =============================================================================

print_header "Installation Summary"
echo ""

# Show what was installed
print_success "Completed Steps:"
while IFS='|' read -r status step_name; do
    if [[ "$status" == "completed" ]]; then
        echo "  ✓ $step_name"
    fi
done < "$INSTALL_STATUS_FILE"

# Show what was skipped
SKIPPED=false
while IFS='|' read -r status step_name; do
    if [[ "$status" == "skipped" ]]; then
        if ! $SKIPPED; then
            echo ""
            print_info "Skipped Steps:"
            SKIPPED=true
        fi
        echo "  ⊘ $step_name"
    fi
done < "$INSTALL_STATUS_FILE"

# Show any failures
FAILED=false
while IFS='|' read -r status step_name; do
    if [[ "$status" == "failed" ]]; then
        if ! $FAILED; then
            echo ""
            print_error "Failed Steps:"
            FAILED=true
        fi
        echo "  ✗ $step_name"
    fi
done < "$INSTALL_STATUS_FILE"

# =============================================================================
# Next Steps
# =============================================================================

echo ""
print_header "Next Steps"

# Shell restart
if grep -q "completed|Shell Configuration" "$INSTALL_STATUS_FILE" 2>/dev/null; then
    echo "1. Restart your shell to apply changes:"
    echo "   exec zsh"
    echo ""
fi

# Tool-specific guidance
STEP=2

if command_exists tmux; then
    echo "$STEP. Launch tmux for terminal multiplexing:"
    echo "   tmux"
    echo ""
    ((STEP++))
fi

if command_exists nvim; then
    echo "$STEP. Launch Neovim (LazyVim will auto-install plugins):"
    echo "   nvim"
    echo ""
    ((STEP++))
fi

if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
    echo "$STEP. Configure Powerlevel10k theme:"
    echo "   p10k configure"
    echo ""
    ((STEP++))
fi

if command_exists claude && ! claude auth status &>/dev/null; then
    echo "$STEP. Authenticate Claude Code:"
    echo "   claude auth"
    echo ""
    ((STEP++))
fi

if is_macos && [[ -d "/Applications/Docker.app" ]]; then
    echo "$STEP. Start Docker Desktop from Applications"
    echo ""
    ((STEP++))
fi

# Additional resources
echo "📚 Resources:"
if [[ -f "$HOME/.config/TERMINAL_README.md" ]]; then
    echo "  • Terminal configs: ~/.config/TERMINAL_README.md"
fi
if [[ -f "$HOME/.config/STATUS_BAR_README.md" ]]; then
    echo "  • Status bar info: ~/.config/STATUS_BAR_README.md"
fi
echo "  • Installation log: $INSTALL_LOG"
echo ""

print_success "Installation complete! 🎉"
echo ""
