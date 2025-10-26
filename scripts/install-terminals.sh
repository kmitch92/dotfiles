#!/bin/bash

# =============================================================================
# Terminal Emulators Installation
# =============================================================================
# Installs modern terminal emulators: Ghostty, WezTerm, Alacritty, Kitty, iTerm2

print_header "Installing Terminal Emulators"

TERMINALS_TO_INSTALL=()

# =============================================================================
# Check installed terminals
# =============================================================================

# WezTerm
if command_exists wezterm || [[ -d "/Applications/WezTerm.app" ]]; then
    print_success "WezTerm already installed"
else
    print_warning "WezTerm not installed (GPU-accelerated, highly configurable)"
    TERMINALS_TO_INSTALL+=("wezterm")
fi

# Alacritty
if command_exists alacritty || [[ -d "/Applications/Alacritty.app" ]]; then
    print_success "Alacritty already installed"
else
    print_warning "Alacritty not installed (OpenGL, minimal)"
    TERMINALS_TO_INSTALL+=("alacritty")
fi

# Kitty
if command_exists kitty || [[ -d "/Applications/kitty.app" ]]; then
    print_success "Kitty already installed"
else
    print_warning "Kitty not installed (GPU-accelerated, feature-rich)"
    TERMINALS_TO_INSTALL+=("kitty")
fi

# Ghostty
if command_exists ghostty || [[ -d "/Applications/Ghostty.app" ]]; then
    print_success "Ghostty already installed"
else
    print_warning "Ghostty not installed (newest, GPU-accelerated)"
    TERMINALS_TO_INSTALL+=("ghostty")
fi

# iTerm2 (macOS only)
if is_macos; then
    if [[ -d "/Applications/iTerm.app" ]]; then
        print_success "iTerm2 already installed"
    else
        print_warning "iTerm2 not installed (most popular macOS terminal)"
        TERMINALS_TO_INSTALL+=("iterm2")
    fi
fi

# =============================================================================
# Installation
# =============================================================================

if [ ${#TERMINALS_TO_INSTALL[@]} -eq 0 ]; then
    echo ""
    print_success "All terminal emulators already installed"
    return 0
fi

echo ""
print_info "Terminal Emulators Available:"
echo ""
echo "  • WezTerm   - Highly configurable, GPU-accelerated (Recommended)"
echo "  • Alacritty - Minimal, OpenGL-based, very fast"
echo "  • Kitty     - Feature-rich, GPU-accelerated, extensible"
echo "  • Ghostty   - Newest, GPU-accelerated, native feel"
if is_macos; then
    echo "  • iTerm2    - Most popular macOS terminal, feature-complete"
fi
echo ""

if ! confirm "Install terminal emulators?"; then
    print_warning "Skipping terminal emulators"
    return 0
fi

echo ""
print_info "Select which terminals to install:"
echo ""

SELECTED_TERMINALS=()

for terminal in "${TERMINALS_TO_INSTALL[@]}"; do
    case $terminal in
        wezterm)
            if confirm "Install WezTerm? (Recommended)"; then
                SELECTED_TERMINALS+=("wezterm")
            fi
            ;;
        alacritty)
            if confirm "Install Alacritty?"; then
                SELECTED_TERMINALS+=("alacritty")
            fi
            ;;
        kitty)
            if confirm "Install Kitty?"; then
                SELECTED_TERMINALS+=("kitty")
            fi
            ;;
        ghostty)
            if confirm "Install Ghostty?"; then
                SELECTED_TERMINALS+=("ghostty")
            fi
            ;;
        iterm2)
            if confirm "Install iTerm2?"; then
                SELECTED_TERMINALS+=("iterm2")
            fi
            ;;
    esac
done

if [ ${#SELECTED_TERMINALS[@]} -eq 0 ]; then
    print_warning "No terminals selected"
    return 0
fi

# =============================================================================
# Install selected terminals
# =============================================================================

for terminal in "${SELECTED_TERMINALS[@]}"; do
    echo ""
    print_info "Installing $terminal..."
    
    if is_macos; then
        case $terminal in
            wezterm)
                brew install --cask wezterm
                if [ $? -eq 0 ]; then
                    print_success "WezTerm installed"
                else
                    print_error "WezTerm installation failed"
                fi
                ;;
            alacritty)
                brew install --cask alacritty
                if [ $? -eq 0 ]; then
                    print_success "Alacritty installed"
                else
                    print_error "Alacritty installation failed"
                fi
                ;;
            kitty)
                brew install --cask kitty
                if [ $? -eq 0 ]; then
                    print_success "Kitty installed"
                else
                    print_error "Kitty installation failed"
                fi
                ;;
            ghostty)
                brew install --cask ghostty
                if [ $? -eq 0 ]; then
                    print_success "Ghostty installed"
                else
                    print_error "Ghostty installation failed"
                fi
                ;;
            iterm2)
                brew install --cask iterm2
                if [ $? -eq 0 ]; then
                    print_success "iTerm2 installed"
                else
                    print_error "iTerm2 installation failed"
                fi
                ;;
        esac
        
    elif is_linux; then
        case $terminal in
            wezterm)
                print_info "Installing WezTerm from GitHub releases..."
                WEZTERM_VERSION="20230712-072601-f4abf8fd"
                
                wget -q "https://github.com/wez/wezterm/releases/download/${WEZTERM_VERSION}/wezterm-${WEZTERM_VERSION}.Ubuntu22.04.deb" -O /tmp/wezterm.deb
                sudo dpkg -i /tmp/wezterm.deb
                sudo apt-get install -f -y
                rm /tmp/wezterm.deb
                
                if command_exists wezterm; then
                    print_success "WezTerm installed"
                else
                    print_error "WezTerm installation failed"
                fi
                ;;
            alacritty)
                install_linux_package alacritty
                if command_exists alacritty; then
                    print_success "Alacritty installed"
                else
                    print_error "Alacritty installation failed"
                fi
                ;;
            kitty)
                install_linux_package kitty
                if command_exists kitty; then
                    print_success "Kitty installed"
                else
                    print_error "Kitty installation failed"
                fi
                ;;
            ghostty)
                print_warning "Ghostty requires building from source on Linux"
                print_info "Visit: https://github.com/ghostty-org/ghostty"
                ;;
        esac
    fi
done

# =============================================================================
# Post-installation info
# =============================================================================

echo ""
print_success "Terminal emulators setup complete"
echo ""

if is_macos; then
    print_info "To open:"
    for terminal in "${SELECTED_TERMINALS[@]}"; do
        case $terminal in
            wezterm) echo "  • WezTerm:   open -a WezTerm" ;;
            alacritty) echo "  • Alacritty: open -a Alacritty" ;;
            kitty) echo "  • Kitty:     open -a kitty" ;;
            ghostty) echo "  • Ghostty:   open -a Ghostty" ;;
            iterm2) echo "  • iTerm2:    open -a iTerm" ;;
        esac
    done
elif is_linux; then
    print_info "To launch:"
    for terminal in "${SELECTED_TERMINALS[@]}"; do
        case $terminal in
            wezterm) echo "  • WezTerm:   wezterm" ;;
            alacritty) echo "  • Alacritty: alacritty" ;;
            kitty) echo "  • Kitty:     kitty" ;;
        esac
    done
fi

echo ""
