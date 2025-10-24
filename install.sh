#!/bin/bash

# =============================================================================
# Dotfiles Installation Script (Package-based Structure)
# =============================================================================
# This script uses GNU Stow with a package-based organization where each
# subdirectory represents a package/application to be stowed separately.
#
# Usage: ./install.sh
# =============================================================================

# Get the directory where this script is located (works in both bash and zsh)
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create a timestamped backup directory for any existing files
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "=================================="
echo "Dotfiles Installation"
echo "=================================="
echo "Source: $DOTFILES_DIR"
echo "Target: $HOME"
echo ""

# Change to the dotfiles directory so stow operates from here
cd "$DOTFILES_DIR"

# Create the backup directory
mkdir -p "$BACKUP_DIR"
echo "Backup directory created: $BACKUP_DIR"

# =============================================================================
# Define packages to stow
# =============================================================================
# List all subdirectories that contain dotfiles to be stowed
# Exclude: .git, and any directories starting with .
PACKAGES=()
for dir in */; do
    # Remove trailing slash
    package="${dir%/}"
    
    # Skip hidden directories and specific exclusions
    if [[ "$package" != .* ]]; then
        PACKAGES+=("$package")
    fi
done

echo ""
echo "Found packages: ${PACKAGES[*]}"

# =============================================================================
# Process each package
# =============================================================================
for package in "${PACKAGES[@]}"; do
    echo ""
    echo "Processing package: $package"
    echo "---"
    
    # Find all files that will be stowed from this package
    # and check for conflicts in the home directory
    while IFS= read -r -d '' file; do
        # Get the relative path from the package directory
        rel_path="${file#$package/}"
        target="$HOME/$rel_path"
        
        # Check if target exists and is NOT a symlink
        if [[ -e "$target" && ! -L "$target" ]]; then
            echo "  Backing up: $rel_path"
            # Create parent directory in backup if needed
            mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
            # Copy the existing file to backup directory
            cp -r "$target" "$BACKUP_DIR/$rel_path"
            # Remove the existing file so stow can create a symlink
            rm -rf "$target"
        fi
    done < <(find "$package" -type f -print0)
    
    # Run stow for this package
    stow "$package"
    
    if [[ $? -eq 0 ]]; then
        echo "  ✓ Stowed: $package"
    else
        echo "  ✗ Error stowing: $package"
    fi
done

# =============================================================================
# Clean up old backup directories
# =============================================================================
echo ""
echo "Cleaning up old backup directories..."

# Find all backup directories except the one we just created
OLD_BACKUPS=$(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" | grep -v "$BACKUP_DIR" | sort)

if [[ -n "$OLD_BACKUPS" ]]; then
    echo "$OLD_BACKUPS" | while read -r old_backup; do
        echo "  Removing: $(basename "$old_backup")"
        rm -rf "$old_backup"
    done
    echo "✓ Old backups cleaned up"
else
    echo "  No old backups found"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=================================="
echo "Installation Complete!"
echo "=================================="
echo "Packages installed: ${PACKAGES[*]}"
echo "Current backup: $(basename "$BACKUP_DIR")"
echo ""
