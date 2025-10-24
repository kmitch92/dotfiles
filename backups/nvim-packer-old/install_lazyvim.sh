#!/bin/bash

# Backup and Install LazyVim

echo "=================================="
echo "LazyVim Installation"
echo "=================================="
echo ""

# Backup current config
echo "📦 Backing up current Neovim config..."
BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
if [ -d "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$BACKUP_DIR"
    echo "✓ Current config backed up to: $BACKUP_DIR"
else
    echo "✓ No existing config to backup"
fi

# Backup Neovim data
echo ""
echo "📦 Backing up Neovim data..."
BACKUP_DATA="$HOME/.local/share/nvim.backup.$(date +%Y%m%d_%H%M%S)"
if [ -d "$HOME/.local/share/nvim" ]; then
    mv "$HOME/.local/share/nvim" "$BACKUP_DATA"
    echo "✓ Data backed up to: $BACKUP_DATA"
fi

# Backup Neovim state
BACKUP_STATE="$HOME/.local/state/nvim.backup.$(date +%Y%m%d_%H%M%S)"
if [ -d "$HOME/.local/state/nvim" ]; then
    mv "$HOME/.local/state/nvim" "$BACKUP_STATE"
    echo "✓ State backed up to: $BACKUP_STATE"
fi

# Backup Neovim cache
BACKUP_CACHE="$HOME/.cache/nvim.backup.$(date +%Y%m%d_%H%M%S)"
if [ -d "$HOME/.cache/nvim" ]; then
    mv "$HOME/.cache/nvim" "$BACKUP_CACHE"
    echo "✓ Cache backed up to: $BACKUP_CACHE"
fi

# Install LazyVim
echo ""
echo "🚀 Installing LazyVim..."
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove .git folder (so you can make it your own)
rm -rf ~/.config/nvim/.git

echo ""
echo "=================================="
echo "✓ LazyVim Installed!"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Open Neovim: nvim"
echo "  2. Wait for lazy.nvim to install plugins (automatic)"
echo "  3. Restart Neovim"
echo "  4. Run :checkhealth to verify everything works"
echo ""
echo "LazyVim comes with:"
echo "  ✓ Line numbers, colors, beautiful UI"
echo "  ✓ LSP for TypeScript, Python, Lua, and more"
echo "  ✓ Autocompletion, syntax highlighting"
echo "  ✓ File explorer, fuzzy finder"
echo "  ✓ Git integration"
echo "  ✓ And much more!"
echo ""
echo "Documentation: https://www.lazyvim.org"
echo ""
