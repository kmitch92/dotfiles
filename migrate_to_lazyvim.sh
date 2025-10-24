#!/bin/bash

# Script to replace Packer config with LazyVim in dotfiles

echo "=================================="
echo "Replacing Packer config with LazyVim"
echo "=================================="
echo ""

DOTFILES_DIR="$HOME/dotfiles"
NVIM_DOTFILES="$DOTFILES_DIR/config/.config/nvim"
NVIM_ACTIVE="$HOME/.config/nvim"
BACKUP_DIR="$DOTFILES_DIR/backups/nvim-packer-old"

# Step 1: Move old Packer config to backups
echo "📦 Step 1: Backing up old Packer config..."
if [ -d "$NVIM_DOTFILES" ]; then
    cp -r "$NVIM_DOTFILES"/* "$BACKUP_DIR/"
    echo "✓ Old config backed up to: backups/nvim-packer-old/"
    
    # Remove old config from dotfiles
    rm -rf "$NVIM_DOTFILES"
    echo "✓ Old config removed from dotfiles"
else
    echo "⚠️  No old config found at $NVIM_DOTFILES"
fi

# Step 2: Copy LazyVim to dotfiles
echo ""
echo "📋 Step 2: Copying LazyVim to dotfiles..."
if [ -d "$NVIM_ACTIVE" ]; then
    mkdir -p "$NVIM_DOTFILES"
    cp -r "$NVIM_ACTIVE"/* "$NVIM_DOTFILES/"
    
    # Remove .git if it exists (don't track LazyVim's git history)
    rm -rf "$NVIM_DOTFILES/.git"
    
    echo "✓ LazyVim copied to dotfiles/config/.config/nvim/"
else
    echo "❌ LazyVim not found at $NVIM_ACTIVE"
    exit 1
fi

# Step 3: Create a README in backup
echo ""
echo "📝 Step 3: Creating backup README..."
cat > "$BACKUP_DIR/README.md" << 'EOF'
# Old Packer-based Neovim Config

This is the old Packer-based Neovim configuration that was replaced by LazyVim.

**Backed up on:** $(date)

## Contents

- Packer plugin manager
- Manual LSP configuration with Mason
- Custom settings, keybindings, and plugin configs

## To Restore This Config

If you want to use this old config again:

```bash
# Remove current nvim config
rm -rf ~/.config/nvim

# Copy this backup to active location
cp -r ~/dotfiles/backups/nvim-packer-old ~/.config/nvim

# Install Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
  ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Open nvim and install plugins
nvim +PackerSync
```

## Why Switched to LazyVim?

- LazyVim works out of the box
- Better defaults and pre-configuration
- More modern plugin manager (lazy.nvim)
- Easier to maintain
EOF

echo "✓ README created in backup directory"

# Step 4: Show status
echo ""
echo "=================================="
echo "✓ Migration Complete!"
echo "=================================="
echo ""
echo "What changed:"
echo "  ✓ Old Packer config → dotfiles/backups/nvim-packer-old/"
echo "  ✓ LazyVim config → dotfiles/config/.config/nvim/"
echo ""
echo "Next steps:"
echo "  1. Verify LazyVim is in dotfiles:"
echo "     ls -la ~/dotfiles/config/.config/nvim"
echo ""
echo "  2. Commit to git:"
echo "     cd ~/dotfiles"
echo "     git add -A"
echo "     git commit -m 'Switch from Packer to LazyVim'"
echo ""
echo "  3. The next time you run ./install.sh, it will use LazyVim!"
echo ""
