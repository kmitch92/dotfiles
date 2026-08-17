#!/bin/bash

# =============================================================================
# Development Tools Installation - macOS
# =============================================================================
# Installs neovim, tmux, starship, and other essential dev tools for macOS

print_header "Installing Development Tools (macOS)"

TOOLS_TO_INSTALL=()

# =============================================================================
# Essential Tools
# =============================================================================

# Neovim
if ! command_exists nvim; then
    print_warning "Neovim not installed"
    TOOLS_TO_INSTALL+=("neovim")
else
    print_success "Neovim found: $(nvim --version | head -n1)"
fi

# tmux
if ! command_exists tmux; then
    print_warning "tmux not installed (recommended for terminal multiplexing)"
    TOOLS_TO_INSTALL+=("tmux")
else
    print_success "tmux found: $(which tmux)"
fi

# starship (modern prompt)
if ! command_exists starship; then
    print_warning "starship not installed (modern shell prompt)"
    TOOLS_TO_INSTALL+=("starship")
else
    print_success "starship found: $(which starship)"
fi

# bat (better cat)
if ! command_exists bat; then
    print_warning "bat not installed (syntax-highlighted cat alternative)"
    TOOLS_TO_INSTALL+=("bat")
else
    print_success "bat found: $(which bat)"
fi

# fzf (fuzzy finder)
if ! command_exists fzf; then
    print_warning "fzf not installed (fuzzy finder)"
    TOOLS_TO_INSTALL+=("fzf")
else
    print_success "fzf found: $(which fzf)"
fi

# ripgrep (better grep)
if ! command_exists rg; then
    print_warning "ripgrep not installed (fast search tool)"
    TOOLS_TO_INSTALL+=("ripgrep")
else
    print_success "ripgrep found: $(which rg)"
fi

# fd (better find)
if ! command_exists fd; then
    print_warning "fd not installed (fast alternative to find)"
    TOOLS_TO_INSTALL+=("fd")
else
    print_success "fd found: $(which fd)"
fi

# eza/exa (modern ls replacement)
if ! command_exists eza && ! command_exists exa; then
    print_warning "eza/exa not installed (modern ls replacement)"
    TOOLS_TO_INSTALL+=("eza")
else
    if command_exists eza; then
        print_success "eza found: $(which eza)"
    else
        print_success "exa found: $(which exa)"
    fi
fi

# lazygit (terminal UI for git)
if ! command_exists lazygit; then
    print_warning "lazygit not installed (terminal UI for git)"
    TOOLS_TO_INSTALL+=("lazygit")
else
    print_success "lazygit found: $(which lazygit)"
fi

# difftastic (structural diff) - Homebrew formula is 'difftastic', binary is 'difft'
if ! command_exists difft; then
    print_warning "difftastic not installed (syntax-aware structural diff)"
    TOOLS_TO_INSTALL+=("difftastic")
else
    print_success "difftastic found: $(which difft)"
fi

# =============================================================================
# Install Tools via Homebrew
# =============================================================================

if [ ${#TOOLS_TO_INSTALL[@]} -eq 0 ]; then
    echo ""
    print_success "All development tools already installed"
    return 0
fi

echo ""
print_info "Tools to install:"
for tool in "${TOOLS_TO_INSTALL[@]}"; do
    echo "  - $tool"
done

echo ""
if ! confirm "Install these development tools?"; then
    print_warning "Skipping development tools"
    return 0
fi

print_info "Installing via Homebrew..."
brew install "${TOOLS_TO_INSTALL[@]}"

# =============================================================================
# Post-Installation Verification
# =============================================================================

echo ""
print_info "Verifying installations..."

ALL_INSTALLED=true
for tool in "${TOOLS_TO_INSTALL[@]}"; do
    # Special cases for tools with different command names
    case "$tool" in
        "neovim")
            cmd="nvim"
            ;;
        "ripgrep")
            cmd="rg"
            ;;
        "difftastic")
            cmd="difft"
            ;;
        "eza")
            # Could be either eza or exa
            if command_exists eza; then
                cmd="eza"
            elif command_exists exa; then
                cmd="exa"
            else
                cmd="eza"
            fi
            ;;
        *)
            cmd="$tool"
            ;;
    esac

    if command_exists "$cmd"; then
        print_success "$tool installed successfully"
    else
        print_error "$tool installation may have failed"
        ALL_INSTALLED=false
    fi
done

echo ""
if $ALL_INSTALLED; then
    print_success "Development tools setup complete"
else
    print_warning "Some tools may not have installed correctly"
    print_info "Check the output above for details"
fi
