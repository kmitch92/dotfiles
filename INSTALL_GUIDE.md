# Cross-Platform Installation Guide

This dotfiles repository works seamlessly across macOS and Linux distributions.

## 🚀 Quick Install (All Platforms)

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## 📦 What Gets Installed Where

### macOS (Apple Silicon & Intel)

**Package Manager:**
- Homebrew (auto-installed if missing)

**Required Tools:**
- GNU Stow (via Homebrew)

**Optional Tools (if you accept):**
- JetBrains Mono font (via Homebrew cask)
- tmux (via Homebrew)
- starship (via Homebrew)

**Shell Configuration:**
- Oh My Zsh + custom plugins
- Zsh configuration with Homebrew PATH setup

### Ubuntu/Debian/Pop!_OS

**Package Manager:**
- apt (system default)

**Required Tools:**
- GNU Stow (via apt)
- Commands: `sudo apt update && sudo apt install -y stow`

**Optional Tools (if you accept):**
- JetBrains Mono font (downloaded from GitHub, installed to `~/.local/share/fonts`)
- tmux (via apt)
- starship (via official installer)

**Shell Configuration:**
- Oh My Zsh + custom plugins
- Zsh configuration with snap package support

### Fedora/RHEL/CentOS

**Package Manager:**
- dnf (system default)

**Required Tools:**
- GNU Stow (via dnf)
- Commands: `sudo dnf install -y stow`

**Optional Tools (if you accept):**
- JetBrains Mono font (downloaded from GitHub, installed to `~/.local/share/fonts`)
- tmux (via dnf)
- starship (via official installer)

**Shell Configuration:**
- Oh My Zsh + custom plugins
- Zsh configuration

### Arch Linux/Manjaro

**Package Manager:**
- pacman (system default)

**Required Tools:**
- GNU Stow (via pacman)
- Commands: `sudo pacman -S --noconfirm stow`

**Optional Tools (if you accept):**
- JetBrains Mono font (downloaded from GitHub, installed to `~/.local/share/fonts`)
- tmux (via pacman)
- starship (via official installer)

**Shell Configuration:**
- Oh My Zsh + custom plugins
- Zsh configuration

## 🔍 Distribution Detection

The script automatically detects your Linux distribution using `/etc/os-release`:

```bash
# Ubuntu/Debian
ID=ubuntu

# Fedora
ID=fedora

# Arch
ID=arch
```

## 📝 Installation Flow

### 1. Prerequisites Check
- ✅ Checks for Git, curl/wget
- ✅ Checks if running on supported OS

### 2. Package Manager Setup
- **macOS**: Offers to install Homebrew
- **Linux**: Uses existing package manager

### 3. Stow Installation
- **macOS**: `brew install stow`
- **Ubuntu/Debian**: `sudo apt install stow`
- **Fedora**: `sudo dnf install stow`
- **Arch**: `sudo pacman -S stow`

### 4. Optional Tools
Offers to install:
- JetBrains Mono font
- tmux
- starship

### 5. Oh My Zsh Setup
- Installs Oh My Zsh framework
- Installs custom plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - you-should-use
  - zsh-bat (if bat is installed)

### 6. Dotfiles Symlinking
- Backs up existing files
- Creates symlinks using GNU Stow
- Cleans up old backups

## 🛠️ Platform-Specific Notes

### macOS
- Homebrew shellenv is added to PATH
- Supports both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`)
- Font installed via Homebrew cask system

### Linux
- Fonts installed to `~/.local/share/fonts`
- `fc-cache -f` rebuilds font cache
- Snap package support in `.zshrc` (Ubuntu)
- Uses `wget` for downloading fonts

### WSL2 (Windows Subsystem for Linux)
- Works via Ubuntu/Debian on WSL
- Follow Ubuntu/Debian instructions
- All Linux features supported

## ⚠️ Common Issues

### Ubuntu: wget not found
```bash
sudo apt install wget
```

### Linux: Font not appearing
```bash
# Rebuild font cache
fc-cache -fv

# Verify installation
fc-list | grep "JetBrains Mono"
```

### Starship not in PATH
```bash
# Add to PATH manually if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
exec zsh
```

### Permission denied on Linux
Make sure the script is executable:
```bash
chmod +x install.sh
```

## 🔄 Updating on Multiple Machines

**First machine (where you make changes):**
```bash
cd ~/dotfiles
git add -A
git commit -m "Update configs"
git push
```

**Other machines:**
```bash
cd ~/dotfiles
git pull
./install.sh  # Re-run if new dependencies added
exec zsh      # Reload shell
```

## 📊 Feature Compatibility Matrix

| Feature | macOS | Ubuntu | Fedora | Arch | WSL2 |
|---------|-------|--------|--------|------|------|
| Auto Stow Install | ✅ | ✅ | ✅ | ✅ | ✅ |
| Font Install | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tmux Install | ✅ | ✅ | ✅ | ✅ | ✅ |
| Starship Install | ✅ | ✅ | ✅ | ✅ | ✅ |
| Oh My Zsh | ✅ | ✅ | ✅ | ✅ | ✅ |
| Terminal Configs | ✅ | ✅ | ✅ | ✅ | ✅ |
| Automatic Backup | ✅ | ✅ | ✅ | ✅ | ✅ |

## 💡 Tips

1. **Run on fresh system**: The script is designed for both fresh installs and existing setups
2. **Multiple runs are safe**: Running the script multiple times is safe - it checks what's already installed
3. **Selective installation**: You can decline optional tools and install them later
4. **Manual installation**: If auto-install fails, the script provides manual commands

## 🎯 Testing Your Installation

After installation, verify everything works:

```bash
# Check zsh is running
echo $SHELL

# Check plugins loaded
echo $plugins

# Check starship
starship --version

# Check tmux
tmux -V

# Check font
fc-list | grep -i jetbrains  # Linux
brew list --cask | grep font  # macOS

# Check stow symlinks
ls -la ~/.zshrc  # Should point to ~/dotfiles/zsh/.zshrc
```

## 📚 Further Reading

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- [Oh My Zsh Documentation](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Starship Configuration](https://starship.rs/config/)
- [Tmux Guide](https://github.com/tmux/tmux/wiki)
