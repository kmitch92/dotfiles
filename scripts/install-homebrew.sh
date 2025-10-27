#!/bin/bash

# =============================================================================
# Homebrew Installation (macOS)
# =============================================================================

print_header "Checking Homebrew"

if ! command_exists brew; then
    print_warning "Homebrew is not installed"
    print_info "Homebrew is the package manager for macOS"
    print_info "Website: https://brew.sh"
    echo ""
    
    if confirm "Would you like to install Homebrew now?"; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Set up Homebrew in current session
        if [[ -d "/opt/homebrew/bin" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -d "/usr/local/bin" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed"
    else
        print_error "Homebrew is required for macOS installations"
        exit 1
    fi
else
    # Ensure Homebrew is in PATH for this script
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    print_success "Homebrew found: $(which brew)"
    
    # Optionally update Homebrew
    if confirm "Would you like to update Homebrew?"; then
        print_info "Updating Homebrew..."
        brew update
        print_success "Homebrew updated"
    fi
fi
