#!/bin/bash

# =============================================================================
# Development Tools Installation - Linux
# =============================================================================
# Installs neovim, tmux, starship, and other essential dev tools for Linux

print_header "Installing Development Tools (Linux)"

TOOLS_TO_INSTALL=()

# =============================================================================
# Essential Tools
# =============================================================================

# Neovim - LazyVim requires >= 0.11.2
NVIM_REQUIRED_VERSION="0.11.2"
NVIM_NEEDS_UPGRADE=false

check_nvim_version() {
    local version_string="$1"
    local required="$2"

    # Extract version numbers (e.g., "NVIM v0.10.4" -> "0.10.4")
    # Using sed instead of grep -oP for portability
    local current=$(echo "$version_string" | sed -n 's/.*v\?\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p' | head -n1)

    # Compare versions
    if [ -z "$current" ]; then
        return 1
    fi

    # Split into major.minor.patch
    IFS='.' read -r curr_major curr_minor curr_patch <<< "$current"
    IFS='.' read -r req_major req_minor req_patch <<< "$required"

    # Compare major.minor.patch
    if [ "$curr_major" -lt "$req_major" ]; then
        return 1
    elif [ "$curr_major" -eq "$req_major" ]; then
        if [ "$curr_minor" -lt "$req_minor" ]; then
            return 1
        elif [ "$curr_minor" -eq "$req_minor" ]; then
            if [ "$curr_patch" -lt "$req_patch" ]; then
                return 1
            fi
        fi
    fi

    return 0
}

if ! command_exists nvim; then
    print_warning "Neovim not installed"
    TOOLS_TO_INSTALL+=("neovim")
else
    NVIM_VERSION=$(nvim --version | head -n1)
    if check_nvim_version "$NVIM_VERSION" "$NVIM_REQUIRED_VERSION"; then
        print_success "Neovim found: $NVIM_VERSION (meets LazyVim requirement >= $NVIM_REQUIRED_VERSION)"
    else
        print_warning "Neovim $NVIM_VERSION found, but LazyVim requires >= $NVIM_REQUIRED_VERSION"
        NVIM_NEEDS_UPGRADE=true
    fi
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

# =============================================================================
# Install Tools
# =============================================================================

if [ ${#TOOLS_TO_INSTALL[@]} -eq 0 ] && ! $NVIM_NEEDS_UPGRADE; then
    echo ""
    print_success "All development tools already installed"
    return 0
fi

if [ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]; then
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
fi

# =============================================================================
# Neovim AppImage Installation
# =============================================================================

install_neovim_appimage() {
    print_info "Installing Neovim via AppImage for LazyVim compatibility..."

    # Detect system architecture
    local arch=$(uname -m)
    local appimage_name=""

    case "$arch" in
        x86_64)
            appimage_name="nvim.appimage"
            ;;
        aarch64|arm64)
            appimage_name="nvim-linux-arm64.appimage"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            print_info "Neovim AppImage is only available for x86_64 and arm64"
            return 1
            ;;
    esac

    print_info "Detected architecture: $arch"

    # Remove old neovim if installed via package manager
    if command_exists apt-get; then
        print_info "Removing old Neovim from apt..."
        sudo apt-get remove -y neovim neovim-runtime 2>/dev/null || true
    elif command_exists dnf; then
        print_info "Removing old Neovim from dnf..."
        sudo dnf remove -y neovim 2>/dev/null || true
    elif command_exists pacman; then
        print_info "Removing old Neovim from pacman..."
        sudo pacman -R --noconfirm neovim 2>/dev/null || true
    fi

    # Remove any existing broken nvim installation
    if [ -f /usr/local/bin/nvim ]; then
        print_info "Removing existing nvim at /usr/local/bin/nvim..."
        sudo rm -f /usr/local/bin/nvim
    fi

    # Download latest Neovim AppImage
    print_info "Downloading latest Neovim AppImage..."
    local tmp_dir=$(mktemp -d)
    local download_url="https://github.com/neovim/neovim/releases/latest/download/$appimage_name"

    cd "$tmp_dir"

    if curl -LO "$download_url"; then
        # Verify the download was successful (file should be > 1MB)
        # Use portable stat command (works on both GNU and BSD)
        local file_size=$(wc -c < "$appimage_name" 2>/dev/null || echo "0")

        if [ -f "$appimage_name" ] && [ "$file_size" -gt 1000000 ]; then
            chmod u+x "$appimage_name"

            # Install to /usr/local/bin
            print_info "Installing to /usr/local/bin/nvim..."
            sudo mv "$appimage_name" /usr/local/bin/nvim

            # Verify installation
            if command_exists nvim && nvim --version >/dev/null 2>&1; then
                local new_version=$(nvim --version | head -n1)
                print_success "Neovim installed: $new_version"
                cd - > /dev/null
                rm -rf "$tmp_dir"
                return 0
            else
                print_error "Neovim AppImage installation failed - executable not working"
                cd - > /dev/null
                rm -rf "$tmp_dir"
                return 1
            fi
        else
            print_error "Downloaded file is invalid or too small"
            print_info "This usually means the download URL returned an error page"
            cd - > /dev/null
            rm -rf "$tmp_dir"
            return 1
        fi
    else
        print_error "Failed to download Neovim AppImage from $download_url"
        cd - > /dev/null
        rm -rf "$tmp_dir"
        return 1
    fi
}

# Handle Neovim upgrade if needed
if $NVIM_NEEDS_UPGRADE; then
    echo ""
    print_warning "Neovim needs to be upgraded for LazyVim compatibility"
    print_info "Current: $(nvim --version | head -n1)"
    print_info "Required: >= $NVIM_REQUIRED_VERSION"
    echo ""

    if confirm "Upgrade Neovim to latest AppImage version?"; then
        if install_neovim_appimage; then
            print_success "Neovim upgraded successfully"
        else
            print_error "Neovim upgrade failed"
            print_warning "LazyVim may not work correctly"
        fi
    else
        print_warning "Skipping Neovim upgrade - LazyVim may not work"
    fi
fi

# =============================================================================
# Install remaining tools via package manager
# =============================================================================

if [ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]; then
    print_info "Installing via package manager..."

    # Special handling for some tools on Linux
    for tool in "${TOOLS_TO_INSTALL[@]}"; do
        case "$tool" in
            "neovim")
                # Install via AppImage for LazyVim compatibility
                if confirm "Install Neovim via AppImage for LazyVim compatibility?"; then
                    install_neovim_appimage
                else
                    install_linux_package neovim
                    print_warning "Package manager Neovim may be too old for LazyVim"
                fi
                ;;
            "bat")
                install_linux_package bat || install_linux_package batcat
                ;;
            "fd")
                install_linux_package fd-find
                # Create symlink if needed
                if ! command_exists fd && command_exists fdfind; then
                    sudo ln -sf $(which fdfind) /usr/local/bin/fd
                fi
                ;;
            "eza")
                # eza might not be in default repos, try cargo or manual install
                if command_exists cargo; then
                    cargo install eza
                else
                    print_warning "eza requires cargo to install, skipping..."
                fi
                ;;
            *)
                install_linux_package "$tool"
                ;;
        esac
    done
fi

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
