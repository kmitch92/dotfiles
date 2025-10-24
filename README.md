# Dotfiles

Personal dotfiles for development environment configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Contents

This repository contains configuration files for:

- **Neovim** (`config/.config/nvim/`) - Complete Neovim configuration with Lua
- **Ghostty** (`config/.config/ghostty/`) - Terminal emulator configuration
- **iTerm2** (`config/.config/iterm2/`) - iTerm2 terminal preferences
- **Zsh** (`zsh/.zshrc`) - Shell configuration and aliases
- **Claude Code** (`claude/.claude/`) - Claude Code development environment settings

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

   This will create symlinks from your home directory to the dotfiles repo.

   Or install packages individually:
   ```bash
   # Install specific packages
   stow zsh       # Symlink .zshrc
   stow config    # Symlink .config directory
   stow claude    # Symlink .claude directory
   ```

## How It Works

GNU Stow creates symlinks from your home directory to files in this repository.

For example:
- `~/.zshrc` → `~/dotfiles/zsh/.zshrc`
- `~/.config/nvim/` → `~/dotfiles/config/.config/nvim/`
- `~/.claude/` → `~/dotfiles/claude/.claude/`

**This means changes work automatically in both directions:**
- Edit files in `~/dotfiles/` → changes appear in your home directory immediately
- Edit files in your home directory → changes are tracked in the git repo
- Commit and push from `~/dotfiles/` to sync across machines

## Uninstalling

To remove the symlinks created by stow:

```bash
cd ~/dotfiles

# Remove all symlinks
stow -D zsh config claude

# Or remove specific packages
stow -D zsh    # Remove .zshrc symlink
stow -D config # Remove .config symlinks
stow -D claude # Remove .claude symlinks
```

## File Structure

```
~/dotfiles/
├── zsh/
│   └── .zshrc          # Zsh shell configuration
├── config/
│   └── .config/
│       ├── nvim/       # Neovim configuration
│       ├── ghostty/    # Ghostty terminal config
│       └── iterm2/     # iTerm2 preferences
├── claude/
│   └── .claude/        # Claude Code settings
├── install.sh          # Installation script
└── README.md           # This file
```

Each top-level directory (`zsh`, `config`, `claude`) is a "package" for stow.
The contents of each package are symlinked to your home directory.

## Customization

After installation, you may want to:

1. **Update Git configuration** in `zsh/.zshrc` with your personal details
2. **Review Neovim plugins** in `config/.config/nvim/lua/core/plugins.lua`
3. **Adjust terminal colors** in `config/.config/ghostty/config`
4. **Modify shell aliases** in `zsh/.zshrc`

You can edit files either in `~/dotfiles/` or directly in your home directory - changes sync automatically!

## Troubleshooting

### Conflicts with existing files

If you have existing dotfiles, stow will not overwrite them. You can use stow's `--adopt` flag to move your existing files into the repo and create symlinks:

```bash
cd ~/dotfiles
stow --adopt zsh config claude
```

This will:
1. Move your existing files from `~` into the dotfiles repo
2. Create symlinks from `~` back to the repo
3. You can then review and commit the changes with git

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