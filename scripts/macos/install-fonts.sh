#!/bin/bash

# =============================================================================
# Font Installation - macOS
# =============================================================================
# Installs JetBrains Mono and other developer fonts via Homebrew

print_header "Installing Fonts (macOS)"

FONT_INSTALLED=false

# =============================================================================
# JetBrains Mono (Primary font)
# =============================================================================

if brew list --cask font-jetbrains-mono &> /dev/null; then
    print_success "JetBrains Mono font already installed"
    FONT_INSTALLED=true
else
    print_warning "JetBrains Mono font not installed"
    print_info "This is the recommended font for terminal and coding"
    echo ""

    if confirm "Install JetBrains Mono font?"; then
        print_info "Installing via Homebrew..."

        # Tap the fonts repository if not already tapped
        brew tap homebrew/cask-fonts 2>/dev/null || true

        brew install --cask font-jetbrains-mono
        print_success "JetBrains Mono installed"
        FONT_INSTALLED=true
    else
        print_warning "Skipping JetBrains Mono installation"
    fi
fi

# =============================================================================
# Powerline Fonts (Terminal styling and status bars)
# =============================================================================

echo ""
print_info "Powerline fonts provide special glyphs for terminal prompts and status bars"
if confirm "Install powerline fonts? (Meslo, DejaVu, Inconsolata, Powerline Symbols)"; then
    print_info "Installing powerline fonts via Homebrew..."

    # Ensure fonts tap is available
    brew tap homebrew/cask-fonts 2>/dev/null || true

    # Install commonly used powerline fonts
    brew install --cask \
        font-meslo-for-powerline \
        font-dejavu-sans-mono-for-powerline \
        font-inconsolata-for-powerline \
        font-powerline-symbols

    print_success "Powerline fonts installed"
    FONT_INSTALLED=true
else
    print_warning "Skipping powerline fonts installation"
fi

# =============================================================================
# Optional: Additional Developer Fonts
# =============================================================================

echo ""
if confirm "Install additional developer fonts? (Fira Code, Hack, Source Code Pro)"; then
    print_info "Installing additional fonts..."

    # Ensure fonts tap is available
    brew tap homebrew/cask-fonts 2>/dev/null || true

    # Install additional fonts
    brew install --cask font-fira-code font-hack font-source-code-pro

    print_success "Additional fonts installed"
    FONT_INSTALLED=true
fi

echo ""
print_success "Font setup complete"
print_info "You may need to restart applications to see new fonts"
