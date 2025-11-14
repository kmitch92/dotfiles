#!/bin/bash

# =============================================================================
# Development Runtimes Installation
# =============================================================================
# Installs Python, uv/uvx, Node.js, npm, and related tools

print_header "Installing Development Runtimes"

# =============================================================================
# Python Installation
# =============================================================================
echo ""
print_info "Checking Python..."

if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python found: $PYTHON_VERSION"
else
    print_warning "Python 3 not installed"
    
    if confirm "Install Python 3?"; then
        if is_macos; then
            print_info "Installing Python via Homebrew..."
            brew install python3
        elif is_linux; then
            print_info "Installing Python..."
            install_linux_package python3
            install_linux_package python3-pip
        fi
        print_success "Python installed"
    fi
fi

# Check for pip
if command_exists pip3; then
    print_success "pip3 found: $(which pip3)"
else
    print_warning "pip3 not found"
    if is_macos && confirm "Install pip3?"; then
        python3 -m ensurepip --upgrade
    fi
fi

# =============================================================================
# uv/uvx Installation (Python package runner)
# =============================================================================
echo ""
print_info "Checking uv/uvx (Python package runner)..."

if command_exists uvx; then
    UV_VERSION=$(uv --version 2>&1 | awk '{print $2}')
    print_success "uv found: $UV_VERSION"
else
    print_warning "uv not installed"
    print_info "uv is a fast Python package installer and runner"
    print_info "Useful for Python development and package management"

    if confirm "Install uv?"; then
        if is_macos; then
            print_info "Installing uv via Homebrew..."
            brew install uv
        elif is_linux; then
            print_info "Installing uv via official installer..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
            print_info "Note: You may need to restart your shell or source your shell config"
        fi

        # Verify installation
        if command_exists uvx; then
            UV_VERSION=$(uv --version 2>&1 | awk '{print $2}')
            print_success "uv installed: $UV_VERSION"
        else
            print_warning "uv installation may require shell restart"
            print_info "Run: source ~/.bashrc  (or ~/.zshrc for zsh)"
        fi
    fi
fi

# Optional: pyenv for Python version management
if ! command_exists pyenv; then
    echo ""
    print_info "pyenv is a Python version manager (optional but recommended)"
    
    if confirm "Install pyenv?"; then
        if is_macos; then
            brew install pyenv
        elif is_linux; then
            curl https://pyenv.run | bash
        fi
        print_success "pyenv installed"
        print_info "Add pyenv to your shell startup file if not already configured"
    fi
fi

# =============================================================================
# Node.js and npm Installation
# =============================================================================
echo ""
print_info "Checking Node.js..."

if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js found: $NODE_VERSION"
else
    print_warning "Node.js not installed"
    
    if confirm "Install Node.js?"; then
        if is_macos; then
            print_info "Installing Node.js via Homebrew..."
            brew install node
        elif is_linux; then
            print_info "Installing Node.js..."
            # Install from NodeSource for latest LTS
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            install_linux_package nodejs
        fi
        print_success "Node.js installed"
    fi
fi

if command_exists npm; then
    NPM_VERSION=$(npm --version)
    print_success "npm found: $NPM_VERSION"
else
    print_warning "npm not found (usually comes with Node.js)"
fi

# Optional: nvm for Node version management
if ! command_exists nvm; then
    echo ""
    print_info "nvm is a Node version manager (optional but recommended)"
    
    if confirm "Install nvm?"; then
        print_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        print_success "nvm installed"
        print_info "Restart your shell to use nvm"
    fi
fi

# =============================================================================
# Additional runtimes
# =============================================================================
echo ""
if confirm "Install additional language runtimes? (Ruby, Go, Rust)"; then
    
    if ! command_exists ruby && confirm "Install Ruby?"; then
        if is_macos; then
            brew install ruby
        elif is_linux; then
            install_linux_package ruby-full
        fi
        print_success "Ruby installed"
    fi
    
    if ! command_exists go && confirm "Install Go?"; then
        if is_macos; then
            brew install go
        elif is_linux; then
            install_linux_package golang
        fi
        print_success "Go installed"
    fi
    
    if ! command_exists rustc && confirm "Install Rust?"; then
        print_info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        print_success "Rust installed"
    fi
fi

echo ""
print_success "Development runtimes ready"
