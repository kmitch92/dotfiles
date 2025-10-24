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
