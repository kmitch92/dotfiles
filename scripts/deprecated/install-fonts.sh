#!/bin/bash

# =============================================================================
# Font Installation
# =============================================================================
# Installs JetBrains Mono and other developer fonts

print_header "Installing Fonts"

FONT_INSTALLED=false

if is_macos; then
    if brew list --cask font-jetbrains-mono &> /dev/null; then
        print_success "JetBrains Mono font already installed"
        FONT_INSTALLED=true
    fi
elif is_linux; then
    if fc-list | grep -qi "JetBrains Mono"; then
        print_success "JetBrains Mono font already installed"
        FONT_INSTALLED=true
    fi
fi

if ! $FONT_INSTALLED; then
    print_warning "JetBrains Mono font not installed"
    print_info "This is the recommended font for terminal and coding"
    echo ""
    
    if confirm "Install JetBrains Mono font?"; then
        if is_macos; then
            print_info "Installing via Homebrew..."
            brew tap homebrew/cask-fonts
            brew install --cask font-jetbrains-mono
            print_success "JetBrains Mono installed"
            
        elif is_linux; then
            print_info "Downloading and installing font..."
            FONT_DIR="$HOME/.local/share/fonts"
            mkdir -p "$FONT_DIR"
            
            cd /tmp
            wget -q https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip
            unzip -q JetBrainsMono-2.304.zip -d JetBrainsMono
            cp JetBrainsMono/fonts/ttf/*.ttf "$FONT_DIR/"
            fc-cache -f
            rm -rf JetBrainsMono JetBrainsMono-2.304.zip
            cd - > /dev/null
            
            print_success "JetBrains Mono installed"
        fi
    else
        print_warning "Skipping font installation"
    fi
fi

# Optional: Install additional fonts
if is_macos; then
    echo ""
    if confirm "Install additional developer fonts? (Fira Code, Hack, Source Code Pro)"; then
        print_info "Installing additional fonts..."
        brew install --cask font-fira-code font-hack font-source-code-pro
        print_success "Additional fonts installed"
    fi
fi
