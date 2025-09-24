#!/bin/bash

# Dotfiles Installation Script
# Uses GNU Stow to create symbolic links for configuration files

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}==> ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# Check if stow is installed
check_stow() {
    if ! command -v stow &> /dev/null; then
        print_error "GNU Stow is not installed!"
        echo "Please install stow first:"
        echo "  macOS: brew install stow"
        echo "  Ubuntu: sudo apt install stow"
        echo "  Arch: sudo pacman -S stow"
        exit 1
    fi
    print_success "GNU Stow found"
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "README.md" ]] || [[ ! -f "install.sh" ]]; then
        print_error "This script must be run from the dotfiles directory"
        exit 1
    fi
    print_success "Running from dotfiles directory"
}

# Backup existing files if they exist and aren't symlinks
backup_existing() {
    local file="$1"
    local backup_dir="$HOME/.dotfiles-backup"

    if [[ -e "$file" && ! -L "$file" ]]; then
        print_warning "Backing up existing $file"
        mkdir -p "$backup_dir"
        cp -r "$file" "$backup_dir/$(basename "$file").$(date +%Y%m%d-%H%M%S)"
        rm -rf "$file"
        return 0
    fi
    return 1
}

# Install .config directory contents
install_config() {
    print_step "Installing .config directory contents"

    if [[ -d ".config" ]]; then
        # Backup existing config directories if they're not symlinks
        for config_dir in .config/*/; do
            if [[ -d "$config_dir" ]]; then
                config_name=$(basename "$config_dir")
                target_dir="$HOME/.config/$config_name"
                backup_existing "$target_dir"
            fi
        done

        # Create .config directory if it doesn't exist
        mkdir -p "$HOME/.config"

        # Use stow to symlink .config contents
        if stow --target="$HOME" --ignore="install.sh|README.md|\.git.*|\.DS_Store" .; then
            print_success "Installed .config directory contents"
        else
            print_error "Failed to install .config directory contents"
            return 1
        fi
    else
        print_warning "No .config directory found"
    fi
}

# Install root-level dotfiles
install_dotfiles() {
    print_step "Installing root-level dotfiles"

    # List of potential root-level dotfiles to backup
    local dotfiles=(".zshrc" ".claude")

    for dotfile in "${dotfiles[@]}"; do
        if [[ -e "$dotfile" ]]; then
            backup_existing "$HOME/$dotfile"
        fi
    done

    # Stow will handle the symlinking, but we're already doing it above
    # This is redundant but keeping for clarity
    print_success "Root-level dotfiles processed"
}

# Create additional directories if needed
create_directories() {
    print_step "Creating additional directories"

    # Ensure .config directory exists
    mkdir -p "$HOME/.config"

    print_success "Directories created"
}

# Main installation function
install_dotfiles_main() {
    echo "🏠 Dotfiles Installation Script"
    echo "=============================="
    echo

    check_stow
    check_directory

    print_step "Starting installation..."

    create_directories
    install_config
    install_dotfiles

    echo
    print_success "Dotfiles installation completed!"
    echo
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Review and customize your configurations as needed"
    echo "3. For Neovim, run :PackerSync to install plugins"
    echo

    if [[ -d "$HOME/.dotfiles-backup" ]]; then
        print_warning "Your original files have been backed up to ~/.dotfiles-backup"
    fi
}

# Uninstall function
uninstall_dotfiles() {
    print_step "Uninstalling dotfiles"

    if stow -D --target="$HOME" --ignore="install.sh|README.md|\.git.*|\.DS_Store" .; then
        print_success "Dotfiles uninstalled successfully"
    else
        print_error "Failed to uninstall some dotfiles"
        return 1
    fi
}

# Script arguments handling
case "${1:-install}" in
    "install")
        install_dotfiles_main
        ;;
    "uninstall")
        uninstall_dotfiles
        ;;
    "help")
        echo "Usage: $0 [install|uninstall|help]"
        echo ""
        echo "Commands:"
        echo "  install     Install dotfiles (default)"
        echo "  uninstall   Remove dotfile symlinks"
        echo "  help        Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac