#!/bin/bash

# Install dotfiles using GNU Stow
# Run from the dotfiles directory: ./install.sh

set -e

echo "Installing dotfiles with GNU Stow..."

# Stow all packages
stow --verbose=2 zsh config claude

echo "✓ Dotfiles installed successfully!"
echo ""
echo "The following are now symlinked to your home directory:"
echo "  - .zshrc (from zsh/)"
echo "  - .config/ (from config/)"
echo "  - .claude/ (from claude/)"
