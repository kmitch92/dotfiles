#!/bin/bash

# =============================================================================
# Shell Configuration Setup
# =============================================================================
# Configures default shell and verifies zsh setup

print_header "Shell Configuration"

# =============================================================================
# Check current shell
# =============================================================================

CURRENT_SHELL=$(basename "$SHELL")
print_info "Current shell: $CURRENT_SHELL"

if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    print_success "Zsh is already your default shell"
else
    print_warning "Your default shell is $CURRENT_SHELL"
fi

# =============================================================================
# Offer to change default shell to zsh
# =============================================================================

if [[ "$CURRENT_SHELL" != "zsh" ]] && command_exists zsh; then
    echo ""
    print_info "Zsh provides better autocomplete, plugins, and theming"
    print_info "Your dotfiles are configured for Zsh"
    echo ""
    
    if confirm "Would you like to set Zsh as your default shell?"; then
        ZSH_PATH=$(which zsh)
        
        # Add zsh to valid shells if not already there
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            print_info "Adding Zsh to valid shells..."
            echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
        fi
        
        # Change default shell
        print_info "Changing default shell to Zsh..."
        chsh -s "$ZSH_PATH"
        
        if [ $? -eq 0 ]; then
            print_success "Default shell changed to Zsh"
            print_warning "You need to log out and back in for this change to take effect"
            
            echo ""
            if confirm "Would you like to start a Zsh session now (for testing)?"; then
                exec zsh
            fi
        else
            print_error "Failed to change default shell"
            print_info "You may need to restart your system"
        fi
    else
        print_warning "Keeping $CURRENT_SHELL as default shell"
        print_info "You can manually change it later with: chsh -s $(which zsh)"
    fi
elif ! command_exists zsh; then
    print_warning "Zsh is not installed, skipping shell configuration"
fi

# =============================================================================
# Verify Zsh configuration
# =============================================================================

if command_exists zsh; then
    echo ""
    print_info "Verifying Zsh configuration..."
    
    # Check for .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        print_success ".zshrc found"
        
        # Check if Oh My Zsh is configured
        if grep -q "oh-my-zsh" "$HOME/.zshrc"; then
            print_success "Oh My Zsh configured in .zshrc"
        else
            print_warning "Oh My Zsh not configured in .zshrc"
        fi
        
        # Check if starship is configured
        if grep -q "starship" "$HOME/.zshrc"; then
            print_success "Starship configured in .zshrc"
        fi
    else
        print_warning ".zshrc not found"
        print_info "Your dotfiles should provide this when stowed"
    fi
    
    # Check for .zshenv
    if [[ -f "$HOME/.zshenv" ]]; then
        print_success ".zshenv found"
    fi
fi

echo ""
print_success "Shell configuration complete"
