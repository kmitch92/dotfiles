# Dotfiles

Personal dotfiles for development environment configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

This repository contains configuration files for:

- **Neovim** (`.config/nvim/`) - Complete Neovim configuration with Lua
- **Ghostty** (`.config/ghostty/`) - Terminal emulator configuration
- **iTerm2** (`.config/iterm2/`) - iTerm2 terminal preferences
- **Zsh** (`.zshrc`) - Shell configuration and aliases
- **Claude Code** (`.claude/`) - Claude Code development environment settings

## Prerequisites

Before installing these dotfiles, ensure you have the following installed:

1. **GNU Stow** - Used for managing symbolic links
   ```bash
   # macOS with Homebrew
   brew install stow

   # Ubuntu/Debian
   sudo apt install stow

   # Arch Linux
   sudo pacman -S stow
   ```

2. **Git** - For cloning this repository
3. **Zsh** - Shell (usually pre-installed on macOS)

## Installation

1. **Clone this repository** to your home directory:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Run the installation script**:
   ```bash
   ./install.sh
   ```

   Or install configurations individually:
   ```bash
   # Install specific configurations
   stow config    # For .config directory contents
   stow .         # For root-level dotfiles like .zshrc
   ```

## Manual Installation Steps

If you prefer to install manually or need to troubleshoot:

```bash
# Navigate to the dotfiles directory
cd ~/dotfiles

# Create symlinks for .config directory contents
stow --target=$HOME config

# Create symlinks for root-level dotfiles
stow --target=$HOME --ignore="config|install.sh|README.md|\.git.*" .
```

## Uninstalling

To remove the symlinks created by stow:

```bash
cd ~/dotfiles

# Remove .config symlinks
stow -D --target=$HOME config

# Remove root-level symlinks
stow -D --target=$HOME --ignore="config|install.sh|README.md|\.git.*" .
```

## File Structure

```
~/dotfiles/
├── .config/
│   ├── nvim/           # Neovim configuration
│   ├── ghostty/        # Ghostty terminal config
│   └── iterm2/         # iTerm2 preferences
├── .claude/            # Claude Code settings
├── .zshrc              # Zsh shell configuration
├── zsh/                # Additional zsh files
├── install.sh          # Installation script
└── README.md           # This file
```

## Customization

After installation, you may want to:

1. **Update Git configuration** in `.zshrc` with your personal details
2. **Review Neovim plugins** in `.config/nvim/lua/core/plugins.lua`
3. **Adjust terminal colors** in `.config/ghostty/config`
4. **Modify shell aliases** in `.zshrc`

## Troubleshooting

### Conflicts with existing files

If you have existing dotfiles, stow will not overwrite them. You'll need to:

1. Backup your existing files:
   ```bash
   mv ~/.zshrc ~/.zshrc.backup
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. Then run the installation again

### Stow conflicts

If stow reports conflicts:
- Check for existing files or symlinks in the target locations
- Remove or backup conflicting files
- Re-run stow

### Permission issues

Ensure the dotfiles directory and your home directory have proper permissions:
```bash
chmod -R 755 ~/dotfiles
```

## Contributing

Feel free to fork this repository and adapt it to your needs. If you find improvements or fixes, pull requests are welcome!

## License

This project is available under the MIT License. See the LICENSE file for more details.