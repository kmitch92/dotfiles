#!/bin/bash

# =============================================================================
# Font Installation - Linux
# =============================================================================
# Installs JetBrains Mono and other developer fonts

print_header "Installing Fonts (Linux)"

FONT_INSTALLED=false
FONT_DIR="$HOME/.local/share/fonts"

# =============================================================================
# Check if JetBrains Mono is already installed
# =============================================================================

if fc-list | grep -qi "JetBrains Mono"; then
    print_success "JetBrains Mono font already installed"
    FONT_INSTALLED=true
else
    print_warning "JetBrains Mono font not installed"
    print_info "This is the recommended font for terminal and coding"
    echo ""

    if confirm "Install JetBrains Mono font?"; then
        print_info "Downloading and installing font..."

        # Create fonts directory if it doesn't exist
        mkdir -p "$FONT_DIR"

        # Download JetBrains Mono
        cd /tmp
        JETBRAINS_VERSION="2.304"
        DOWNLOAD_URL="https://github.com/JetBrains/JetBrainsMono/releases/download/v${JETBRAINS_VERSION}/JetBrainsMono-${JETBRAINS_VERSION}.zip"

        print_info "Downloading JetBrains Mono v${JETBRAINS_VERSION}..."
        if wget -q "$DOWNLOAD_URL" -O JetBrainsMono.zip; then
            print_info "Extracting fonts..."
            unzip -q JetBrainsMono.zip -d JetBrainsMono

            print_info "Installing fonts to $FONT_DIR..."
            cp JetBrainsMono/fonts/ttf/*.ttf "$FONT_DIR/"

            print_info "Updating font cache..."
            fc-cache -f

            # Cleanup
            rm -rf JetBrainsMono JetBrainsMono.zip

            print_success "JetBrains Mono installed"
            FONT_INSTALLED=true
        else
            print_error "Failed to download JetBrains Mono"
            print_info "Please check your internet connection or download manually from:"
            print_info "$DOWNLOAD_URL"
        fi

        cd - > /dev/null
    else
        print_warning "Skipping JetBrains Mono installation"
    fi
fi

# =============================================================================
# Powerline Fonts (Terminal styling and status bars)
# =============================================================================

echo ""
print_info "Powerline fonts provide special glyphs for terminal prompts and status bars"
if confirm "Install powerline fonts? (Meslo, DejaVu, Inconsolata)"; then
    print_info "Installing powerline fonts..."

    # Create fonts directory if it doesn't exist
    mkdir -p "$FONT_DIR"

    local distro=$(detect_linux_distro)

    case $distro in
        ubuntu|debian|pop)
            # Install via package manager
            sudo apt-get install -y fonts-powerline
            print_success "Powerline fonts installed via apt"
            FONT_INSTALLED=true
            ;;
        fedora|rhel|centos)
            # Install via package manager
            sudo dnf install -y powerline-fonts
            print_success "Powerline fonts installed via dnf"
            FONT_INSTALLED=true
            ;;
        arch|manjaro)
            # Install via package manager
            sudo pacman -S --noconfirm powerline-fonts
            print_success "Powerline fonts installed via pacman"
            FONT_INSTALLED=true
            ;;
        *)
            # Manual installation for other distros
            print_info "Downloading powerline fonts from GitHub..."
            cd /tmp
            if git clone --depth=1 https://github.com/powerline/fonts.git powerline-fonts 2>/dev/null; then
                cd powerline-fonts
                ./install.sh
                cd ..
                rm -rf powerline-fonts
                print_success "Powerline fonts installed manually"
                FONT_INSTALLED=true
            else
                print_warning "Failed to download powerline fonts"
                print_info "Install manually from: https://github.com/powerline/fonts"
            fi
            cd - > /dev/null
            ;;
    esac

    print_info "Updating font cache..."
    fc-cache -f
else
    print_warning "Skipping powerline fonts installation"
fi

# =============================================================================
# Optional: Additional Developer Fonts
# =============================================================================

echo ""
if confirm "Install additional developer fonts? (Fira Code, Hack)"; then
    print_info "Installing additional fonts via package manager..."

    local distro=$(detect_linux_distro)

    case $distro in
        ubuntu|debian|pop)
            sudo apt-get install -y fonts-firacode fonts-hack
            ;;
        fedora|rhel|centos)
            sudo dnf install -y fira-code-fonts mozilla-fira-mono-fonts hack-fonts
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm ttf-fira-code ttf-hack
            ;;
        *)
            print_warning "Automatic installation not supported for this distribution"
            print_info "You can download fonts manually from:"
            print_info "  - Fira Code: https://github.com/tonsky/FiraCode"
            print_info "  - Hack: https://sourcefoundry.org/hack/"
            ;;
    esac

    if [ "$distro" = "ubuntu" ] || [ "$distro" = "debian" ] || [ "$distro" = "pop" ] || \
       [ "$distro" = "fedora" ] || [ "$distro" = "rhel" ] || [ "$distro" = "centos" ] || \
       [ "$distro" = "arch" ] || [ "$distro" = "manjaro" ]; then
        print_info "Updating font cache..."
        fc-cache -f
        print_success "Additional fonts installed"
        FONT_INSTALLED=true
    fi
fi

echo ""
print_success "Font setup complete"
print_info "You may need to restart applications to see new fonts"

# Verify installation
echo ""
print_info "Installed fonts:"
fc-list | grep -i "jetbrains\|fira\|hack" | cut -d: -f2 | sort -u | head -10 || print_warning "No developer fonts detected"
