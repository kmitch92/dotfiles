#!/bin/bash

# =============================================================================
# System Packages Installation
# =============================================================================
# Installs essential system packages: stow, git, curl, wget, build tools

print_header "Installing System Packages"

PACKAGES_TO_INSTALL=()

# Check for GNU Stow (required)
if ! command_exists stow; then
    print_warning "GNU Stow not installed (required for dotfiles)"
    PACKAGES_TO_INSTALL+=("stow")
else
    print_success "GNU Stow found: $(which stow)"
fi

# Check for git
if ! command_exists git; then
    print_warning "Git not installed"
    PACKAGES_TO_INSTALL+=("git")
else
    print_success "Git found: $(which git)"
fi

# Check for curl
if ! command_exists curl; then
    print_warning "curl not installed"
    PACKAGES_TO_INSTALL+=("curl")
else
    print_success "curl found: $(which curl)"
fi

# Check for wget
if ! command_exists wget; then
    print_warning "wget not installed"
    PACKAGES_TO_INSTALL+=("wget")
else
    print_success "wget found: $(which wget)"
fi

# Check for build tools
if is_macos; then
    if ! xcode-select -p &> /dev/null; then
        print_warning "Xcode Command Line Tools not installed"
        if confirm "Install Xcode Command Line Tools?"; then
            xcode-select --install
            print_info "Please complete the Xcode installation and re-run this script"
            exit 0
        fi
    else
        print_success "Xcode Command Line Tools installed"
    fi
elif is_linux; then
    if ! command_exists gcc; then
        print_warning "Build tools not installed"
        PACKAGES_TO_INSTALL+=("build-essential")
    else
        print_success "Build tools found"
    fi
fi

# Install missing packages
if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo ""
    print_info "The following packages need to be installed:"
    for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    
    if confirm "Install these packages now?"; then
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            print_info "Installing $pkg..."
            
            if is_macos; then
                brew install "$pkg"
            elif is_linux; then
                install_linux_package "$pkg"
            fi
            
            print_success "Installed $pkg"
        done
    else
        if [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " stow " ]]; then
            print_error "GNU Stow is required. Exiting."
            exit 1
        fi
    fi
fi

echo ""
print_success "System packages ready"
