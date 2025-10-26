#!/bin/bash

# =============================================================================
# Shell Tools Installation
# =============================================================================
# Installs Oh My Zsh and recommended plugins

print_header "Installing Shell Tools"

# =============================================================================
# Zsh Installation
# =============================================================================

if ! command_exists zsh; then
    print_warning "Zsh not installed"
    
    if confirm "Install Zsh?"; then
        if is_macos; then
            print_info "Installing Zsh via Homebrew..."
            brew install zsh
        elif is_linux; then
            print_info "Installing Zsh..."
            install_linux_package zsh
        fi
        print_success "Zsh installed"
    else
        print_warning "Skipping shell tools (Zsh required)"
        return 0
    fi
else
    print_success "Zsh found: $(zsh --version)"
fi

# =============================================================================
# Oh My Zsh Installation
# =============================================================================
echo ""

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_success "Oh My Zsh already installed"
    
    if confirm "Update Oh My Zsh?"; then
        cd "$HOME/.oh-my-zsh" && git pull
        print_success "Oh My Zsh updated"
    fi
else
    print_warning "Oh My Zsh not installed"
    print_info "Oh My Zsh provides plugins and themes for Zsh"
    echo ""
    
    if confirm "Install Oh My Zsh?"; then
        print_info "Installing Oh My Zsh..."
        
        # Install without changing shell or starting zsh
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        
        print_success "Oh My Zsh installed"
    else
        print_warning "Skipping Oh My Zsh plugins"
        return 0
    fi
fi

# =============================================================================
# Oh My Zsh Custom Plugins
# =============================================================================
echo ""
print_info "Checking Oh My Zsh plugins..."

PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"
PLUGINS_TO_INSTALL=()

# Define plugins
declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
)

# Check for zsh-bat only if bat is installed
if command_exists bat; then
    PLUGINS["zsh-bat"]="https://github.com/fdellwing/zsh-bat.git"
fi

# Check which plugins are missing
for plugin in "${!PLUGINS[@]}"; do
    if [[ ! -d "$PLUGIN_DIR/$plugin" ]]; then
        PLUGINS_TO_INSTALL+=("$plugin")
        print_warning "$plugin not installed"
    else
        print_success "$plugin installed"
    fi
done

# Install missing plugins
if [ ${#PLUGINS_TO_INSTALL[@]} -gt 0 ]; then
    echo ""
    if confirm "Install missing Oh My Zsh plugins?"; then
        for plugin in "${PLUGINS_TO_INSTALL[@]}"; do
            print_info "Installing $plugin..."
            git clone "${PLUGINS[$plugin]}" "$PLUGIN_DIR/$plugin"
            print_success "Installed $plugin"
        done
    fi
fi

# =============================================================================
# Powerlevel10k Theme (Optional)
# =============================================================================
echo ""
if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
    print_info "Powerlevel10k is a popular Zsh theme (alternative to starship)"
    
    if confirm "Install Powerlevel10k theme?"; then
        print_info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
        print_success "Powerlevel10k installed"
        print_info "Run 'p10k configure' after restarting your shell to configure it"
    fi
else
    print_success "Powerlevel10k already installed"
fi

echo ""
print_success "Shell tools setup complete"
