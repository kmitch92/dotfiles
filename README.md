# Dotfiles

Personal dotfiles for development environment configuration, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## 📦 What's Included

This repository contains comprehensive configuration files for:

### 🐚 Shell & Prompt
- **Zsh** (`zsh/.zshrc`) - Shell configuration with Homebrew setup and OS-specific logic
- **Oh My Zsh** - Plugin framework (installed by script, not tracked in repo)
  - Plugins: git, web-search, zsh-autosuggestions, zsh-syntax-highlighting, you-should-use, zsh-bat, zsh-interactive-cd
- **Starship** (`starship/.config/starship.toml`) - Beautiful, fast prompt with git integration, language detection, and status info

### 🖥️ Terminal Emulators
- **Ghostty** (`config/.config/ghostty/config`) - Modern, GPU-accelerated terminal
- **Alacritty** (`config/.config/alacritty/alacritty.toml`) - Cross-platform, blazing fast
- **Kitty** (`config/.config/kitty/kitty.conf`) - Feature-rich with image support
- **WezTerm** (`config/.config/wezterm/wezterm.lua`) - Lua-configured with built-in status bar
- **iTerm2** (`config/.config/iterm2/`) - macOS classic with dynamic profiles

All terminals configured with:
- Catppuccin Mocha theme (beautiful dark theme)
- JetBrains Mono font
- 95% opacity with background blur
- Consistent keybindings

### 🔧 Tools & Utilities
- **Tmux** (`tmux/.tmux.conf`) - Terminal multiplexer with status bar and window management
- **Neovim** (`config/.config/nvim/`) - Complete Neovim configuration
- **Claude Code** (`claude/.claude/`) - Claude Code agent configurations

## 🚀 Quick Start

### One-Command Installation

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The install script will:
1. ✅ Check for and install Homebrew (if needed)
2. ✅ Check for and install GNU Stow (required)
3. ✅ Check for and install Oh My Zsh with custom plugins
4. ✅ Offer to install optional tools (JetBrains Mono font, tmux, starship)
5. ✅ Backup any existing dotfiles
6. ✅ Create symlinks for all packages
7. ✅ Clean up old backups

### After Installation

```bash
# Restart your shell
exec zsh

# Try tmux (if installed)
tmux

# Or just enjoy your new terminal configs!
```

## 📋 Prerequisites

The install script will handle most dependencies automatically, but you need:

**Required:**
- Git (for cloning the repo)
- Zsh shell
  - macOS: Pre-installed
  - Ubuntu/Debian: `sudo apt install zsh`
  - Fedora: `sudo dnf install zsh`
  - Arch: `sudo pacman -S zsh`
- curl or wget (usually pre-installed)

**Installed automatically by script:**
- **macOS**: Homebrew, GNU Stow
- **Linux**: GNU Stow (via apt/dnf/pacman)

**Optional (offered during installation):**
- JetBrains Mono font
- Tmux (terminal multiplexer)
- Starship (enhanced prompt)
- Oh My Zsh + plugins

## 🎯 What You Get

### Terminal Experience
Choose any terminal emulator (Ghostty, Alacritty, Kitty, WezTerm, iTerm2) and get:
- Unified Catppuccin Mocha theme across all terminals
- Consistent keybindings (Cmd+C/V, Cmd+T, etc.)
- Beautiful transparency and blur effects
- 10,000 lines of scrollback

### Status Bar Options
- **WezTerm**: Built-in status bar (shows directory, battery, date, time)
- **iTerm2**: Native status bar (manual setup, shows everything)
- **Other terminals**: Use Tmux or Starship for status information

### Enhanced Prompt (Starship)
When installed, you get an intelligent prompt showing:
- Current directory
- Git branch and status
- Programming language versions (Node, Python, Rust, Go, etc.)
- Command duration
- Battery level and time (on the right)
- Error indicators

## 📖 Documentation

Detailed guides are included:
- **TERMINAL_README.md** - Terminal emulator comparison and setup
- **STATUS_BAR_README.md** - Status bar options for each terminal
- **iTerm2/README.md** - iTerm2-specific setup instructions

## 🗂️ File Structure

```
~/dotfiles/
├── install.sh                    # Smart installation script
├── README.md                     # This file
│
├── zsh/
│   └── .zshrc                    # Shell config (Homebrew, Starship, etc.)
│
├── config/
│   └── .config/
│       ├── alacritty/            # Alacritty terminal config
│       ├── ghostty/              # Ghostty terminal config
│       ├── kitty/                # Kitty terminal config
│       ├── wezterm/              # WezTerm terminal config
│       ├── iterm2/               # iTerm2 dynamic profiles
│       └── nvim/                 # Neovim configuration
│
├── starship/
│   └── .config/
│       └── starship.toml         # Starship prompt config
│
├── tmux/
│   └── .tmux.conf                # Tmux configuration
│
└── claude/
    └── .claude/                  # Claude Code agent configs
```

## 📝 What Goes in the Repo?

**✅ Track these (configuration files):**
- `.zshrc` - Your shell configuration
- `.config/` - Application configs (terminal, nvim, etc.)
- `.tmux.conf` - Tmux configuration
- Any other dotfiles you create

**❌ Don't track these (installed software):**
- `~/.oh-my-zsh/` - Oh My Zsh installation (installed by script)
- `~/.oh-my-zsh/custom/plugins/*` - Plugin installations (installed by script)
- `/opt/homebrew/` - Homebrew itself
- Any binary applications or compiled software

**Why this separation?**
- Configs are small text files that change frequently
- Software installations are large and managed by package managers
- This keeps your repo lightweight and portable
- Installation script handles all the software dependencies

## 🔄 How Stow Works

GNU Stow creates symlinks from your home directory to files in this repository.

**For example:**
```
~/.zshrc           → ~/dotfiles/zsh/.zshrc
~/.config/ghostty/ → ~/dotfiles/config/.config/ghostty/
~/.tmux.conf       → ~/dotfiles/tmux/.tmux.conf
```

**This means:**
- ✅ Edit files in `~/dotfiles/` → changes appear in your home directory
- ✅ Edit files in your home directory → changes are in the git repo
- ✅ Commit and push from `~/dotfiles/` → sync across machines
- ✅ Pull on another machine → configs update automatically

## 🎨 Customization

### Change Terminal Theme
All configs use Catppuccin Mocha. To use a different theme:
- **Catppuccin Latte** (light): https://github.com/catppuccin/catppuccin
- **Nord**: https://www.nordtheme.com
- **Dracula**: https://draculatheme.com
- **Tokyo Night**: https://github.com/tokyo-night

### Change Font
Edit the font family in terminal configs. Popular alternatives:
```bash
brew install --cask font-fira-code
brew install --cask font-cascadia-code
brew install --cask font-hack
```

### Enable Ligatures
If you want programming ligatures (→, ≥, etc.):
- Remove `disable_ligatures` or `font-feature` lines from configs
- Requires a font with ligature support

### Customize Prompt
Edit `~/.config/starship.toml` to add/remove modules or change colors.
See: https://starship.rs/config/

## 🆘 Troubleshooting

### Stow Conflicts
If stow reports conflicts with existing files:
```bash
cd ~/dotfiles
# Remove existing files manually or back them up
rm ~/.zshrc  # or mv ~/.zshrc ~/.zshrc.backup

# Then run install again
./install.sh
```

### Shell Not Loading Configs
Make sure `.zshrc` is symlinked:
```bash
ls -la ~/.zshrc
# Should show: .zshrc -> /Users/you/dotfiles/zsh/.zshrc

# If not, re-run install
cd ~/dotfiles && ./install.sh
```

### Stow Not Found After Install
Restart your shell to load Homebrew's PATH:
```bash
exec zsh
```

### Font Not Working
Make sure JetBrains Mono is installed:
```bash
brew install --cask font-jetbrains-mono
# Then restart your terminal app
```

## 🔧 Manual Installation (Without Script)

If you prefer to install manually:

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Install dependencies
brew install stow tmux starship
brew install --cask font-jetbrains-mono

# 3. Stow packages
stow zsh
stow config
stow tmux
stow starship
stow claude

# 4. Restart shell
exec zsh
```

## 🗑️ Uninstalling

To remove symlinks:
```bash
cd ~/dotfiles

# Remove all packages
stow -D zsh config tmux starship claude

# Or remove specific packages
stow -D zsh    # Remove .zshrc symlink
stow -D config # Remove .config symlinks
```

## 💻 Cross-Platform Support

The install script fully supports:
- ✅ **macOS** (Apple Silicon & Intel)
  - Auto-installs Homebrew
  - Auto-installs all tools via Homebrew
  
- ✅ **Linux**
  - **Ubuntu/Debian**: Uses apt
  - **Fedora/RHEL/CentOS**: Uses dnf
  - **Arch/Manjaro**: Uses pacman
  - Auto-installs fonts, tmux, starship
  
- ✅ **Windows (WSL2)**: Works via Ubuntu/Debian on WSL

**Platform-specific features:**
- Homebrew PATH setup (macOS)
- Snap package support (Ubuntu)
- Automatic distribution detection (Linux)
- Font installation via fontconfig (Linux)

The `.zshrc` includes OS-specific logic that automatically adapts to your platform.

## 🤝 Contributing

Feel free to fork and adapt this to your needs! If you find improvements:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details.

---

**Happy dotfiles-ing!** 🎉
