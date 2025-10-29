#!/bin/bash

# =============================================================================
# Stow Configuration Setup
# =============================================================================
# Uses GNU Stow to symlink dotfiles to home directory

print_header "Installing Dotfiles with Stow"

# Verify we're in the dotfiles directory
if [[ ! -d "$DOTFILES_DIR" ]]; then
    print_error "DOTFILES_DIR not set or invalid"
    exit 1
fi

cd "$DOTFILES_DIR"

# Create backup directory
BACKUP_DIR=$(create_backup_dir)
print_info "Backup directory: $BACKUP_DIR"

# =============================================================================
# Discover packages to stow
# =============================================================================

PACKAGES=()
for dir in */; do
    package="${dir%/}"

    # Skip hidden directories, scripts, mcp, and README
    # mcp/ is managed separately by setup-mcp.sh (template substitution, not symlinks)
    if [[ "$package" != .* ]] && [[ "$package" != "scripts" ]] && [[ "$package" != "mcp" ]] && [[ "$package" != "README"* ]]; then
        PACKAGES+=("$package")
    fi
done

if [ ${#PACKAGES[@]} -eq 0 ]; then
    print_error "No packages found to stow"
    exit 1
fi

echo ""
print_info "Found packages:"
for package in "${PACKAGES[@]}"; do
    echo "  - $package"
done

echo ""
if ! confirm "Stow these packages to $HOME?"; then
    print_warning "Stow cancelled"
    exit 0
fi

# =============================================================================
# Process each package
# =============================================================================

STOWED_PACKAGES=()
FAILED_PACKAGES=()

for package in "${PACKAGES[@]}"; do
    echo ""
    print_info "Processing: $package"
    
    # Enable dotglob to match hidden files
    shopt -s dotglob nullglob
    
    # Check for conflicts and backup existing files
    for item in "$package"/*; do
        if [[ -e "$item" ]]; then
            item_name=$(basename "$item")
            target="$HOME/$item_name"
            
            if [[ -e "$target" || -L "$target" ]]; then
                if [[ -L "$target" ]]; then
                    # Remove existing symlink
                    rm -f "$target"
                    print_info "  Removed existing symlink: $item_name"
                else
                    # Backup existing file/directory
                    print_info "  Backing up: $item_name"
                    cp -r "$target" "$BACKUP_DIR/"
                    rm -rf "$target"
                fi
            fi
        fi
    done
    
    shopt -u dotglob nullglob
    
    # Run stow
    if stow --verbose=1 "$package" 2>&1; then
        print_success "Stowed: $package"
        STOWED_PACKAGES+=("$package")
    else
        print_error "Failed to stow: $package"
        FAILED_PACKAGES+=("$package")
    fi
done

# =============================================================================
# Clean up old backups
# =============================================================================
echo ""
print_info "Cleaning up old backup directories..."

OLD_BACKUPS=$(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" | grep -v "$BACKUP_DIR" | sort)

if [[ -n "$OLD_BACKUPS" ]]; then
    echo "$OLD_BACKUPS" | while read -r old_backup; do
        print_info "  Removing: $(basename "$old_backup")"
        rm -rf "$old_backup"
    done
    print_success "Old backups cleaned up"
else
    print_info "  No old backups found"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
print_header "Stow Summary"

if [ ${#STOWED_PACKAGES[@]} -gt 0 ]; then
    print_success "Successfully stowed packages:"
    for package in "${STOWED_PACKAGES[@]}"; do
        echo "  ✓ $package"
    done
fi

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    print_error "Failed to stow packages:"
    for package in "${FAILED_PACKAGES[@]}"; do
        echo "  ✗ $package"
    done
fi

echo ""
print_info "Backup location: $BACKUP_DIR"

# Check if backup directory is empty (no conflicts occurred)
if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
    print_info "No files needed backup (clean installation)"
    rmdir "$BACKUP_DIR"
else
    print_warning "Some files were backed up - review backup directory"
fi

echo ""
print_success "Dotfiles installation complete"
