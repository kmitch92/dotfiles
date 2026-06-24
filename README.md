# Dotfiles Installation

Modern, modular dotfiles installation system for bootstrapping development environments on macOS and Linux (Ubuntu/Debian/Fedora/Arch).

## Quick Start
```bash
git clone <your-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer guides you through each component with confirmation prompts.

### Installation Modes
```bash
# Interactive (recommended) - asks before installing each component
./install.sh

# Non-interactive - automatically say yes to all prompts
./install.sh --yes
# or
./install.sh -y

# Minimal - only installs required components, skips optional
./install.sh --skip-optional

# Combine options - non-interactive minimal installation
./install.sh --yes --skip-optional

# Individual scripts - install specific components only
source scripts/utils.sh
source scripts/install-docker.sh
```

## Features

### 🎯 Best-in-Class User Experience

- **Individual Component Control** - Approve each installation separately
- **Progress Tracking** - Visual indicators and comprehensive logging
- **Smart Defaults** - Sensible choices, easy to customize
- **Error Recovery** - Optional components can fail without breaking install
- **Installation Summary** - See exactly what was installed, skipped, or failed
- **Detailed Next Steps** - Context-aware guidance based on what was installed

### 🔧 Robust Foundation

- **Modular Architecture** - Easy to extend and maintain
- **Idempotent** - Safe to run multiple times
- **Comprehensive Logging** - Track everything in `.install.log`
- **Timestamped Backups** - Automatic backup of existing files
- **OS-Aware** - Detects macOS vs Linux and uses appropriate package managers
- **Error Handling** - Required vs optional steps, clear failure messages

### 📦 Complete Bootstrap

Everything needed for modern development work:
- System tools and package managers
- Development runtimes (Python, Node, etc.)
- Essential CLI tools (neovim, tmux, etc.)
- Docker and containerization
- AI coding tools (Claude Code)
- Shell configuration and themes

## What Gets Installed

### Core System Tools
- **Homebrew** (macOS only) - Package manager
- **GNU Stow** - Dotfiles symlink manager
- **Git, curl, wget** - Essential utilities
- **Build tools** - Xcode CLI tools (macOS) or build-essential (Linux)

### Development Runtimes
- **Python 3** - With pip3
- **Node.js & npm** - JavaScript runtime
- **pyenv** (optional) - Python version manager
- **nvm** (optional) - Node version manager
- **Ruby, Go, Rust** (optional) - Additional languages

### Development Tools
- **Neovim** - Modern text editor
- **tmux** - Terminal multiplexer
- **starship** - Modern shell prompt
- **bat** - Syntax-highlighted cat
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **fd** - Fast find alternative
- **eza/exa** - Modern ls replacement
- **jq, yq** (optional) - JSON/YAML processors
- **git-delta** (optional) - Better git diffs
- **lazygit** (optional) - Terminal UI for git

### Fonts
- **JetBrains Mono** - Primary coding font
- **Fira Code, Hack, Source Code Pro** (optional)

### Docker
- **Docker Engine** (Linux) - Container runtime
- **Docker Desktop** (macOS/Linux) - GUI and better integration
- **Docker Compose** - Multi-container orchestration

### Claude Code
- **Claude Code CLI** - Agentic coding assistant

### Shell Configuration
- **Zsh** - Modern shell
- **Oh My Zsh** - Zsh framework
- **zsh-autosuggestions** - Fish-like suggestions
- **zsh-syntax-highlighting** - Real-time syntax highlighting
- **you-should-use** - Alias reminder
- **zsh-bat** (if bat installed) - bat integration
- **Powerlevel10k** (optional) - Alternative theme

## Directory Structure
```
dotfiles/
├── install.sh              # Main orchestrator
├── scripts/                # Modular installation scripts
│   ├── utils.sh           # Common utilities
│   ├── install-homebrew.sh
│   ├── install-packages.sh
│   ├── install-fonts.sh
│   ├── install-terminals.sh
│   ├── install-runtimes.sh
│   ├── install-dev-tools.sh
│   ├── install-docker.sh
│   ├── install-claude-code.sh
│   ├── install-shell-tools.sh
│   ├── setup-shell.sh
│   └── setup-stow.sh
├── zsh/                    # Zsh configuration package
│   └── .zshrc
├── tmux/                   # tmux configuration package
│   └── .tmux.conf
├── config/                 # Unified .config package (all XDG configs)
│   └── .config/
│       ├── nvim/          # Neovim (LazyVim)
│       ├── starship.toml  # Starship prompt
│       ├── alacritty/     # Terminal emulators
│       ├── kitty/
│       ├── wezterm/
│       └── ghostty/
└── claude/                 # Claude Code configuration
    └── .claude/
```

**Note:** All `.config` subdirectories are consolidated in the `config/` package to avoid
stow conflicts. This is because GNU Stow cannot handle multiple packages trying to symlink
into the same parent directory.

## Running Individual Scripts

You can run scripts individually if you only need specific components:
```bash
# Install only development runtimes
source scripts/utils.sh
source scripts/install-runtimes.sh

# Install only Docker
source scripts/utils.sh
source scripts/install-docker.sh

# Setup shell configuration
source scripts/utils.sh
source scripts/setup-shell.sh
```

## Stow Package Structure

Each subdirectory (except `scripts/`) represents a stow package:
```
package_name/
└── .config/
    └── tool/
        └── config.yml
```

When stowed, this creates: `~/.config/tool/config.yml`

## Post-Installation

After installation completes:

1. **Restart your shell:**
```bash
exec zsh
```

The shell will automatically start tmux by default. To disable this:
```bash
# Temporarily disable for one session
export DISABLE_AUTO_TMUX=true
exec zsh

# Permanently disable - add to your ~/.zshrc or environment
echo 'export DISABLE_AUTO_TMUX=true' >> ~/.zshrc
```

2. **Configure Powerlevel10k** (if installed):
```bash
p10k configure
```

3. **Authenticate Claude Code** (if installed):
```bash
claude auth
```

4. **Start Docker Desktop** (if installed on macOS)

5. **Test installations:**
```bash
nvim --version
tmux -V
docker --version
node --version
python3 --version
```

## Extending the System

The modular design makes it easy to add new components. Here's the best-practice pattern:

### Adding a New Tool

1. **Create a new script** in `scripts/`:
```bash
#!/bin/bash
# scripts/install-mytool.sh

print_header "Installing MyTool"

if command_exists mytool; then
    print_success "MyTool already installed: $(mytool --version)"
    return 0
fi

print_warning "MyTool not installed"
print_info "MyTool does XYZ and is useful for ABC"
echo ""

if ! confirm "Install MyTool?"; then
    print_warning "Skipping MyTool"
    return 0
fi

print_info "Installing MyTool..."

if is_macos; then
    brew install mytool
elif is_linux; then
    install_linux_package mytool
fi

if [ $? -eq 0 ]; then
    print_success "MyTool installed"
else
    print_error "MyTool installation failed"
    return 1
fi

# Optional: Post-install configuration
if confirm "Configure MyTool now?"; then
    mytool init
    print_success "MyTool configured"
fi
```

2. **Add to main installer** in `install.sh`:
```bash
# Step N: Install MyTool
if ! $SKIP_OPTIONAL; then
    run_step "MyTool" "install-mytool.sh" "optional"
fi
```

3. **Test your script**:
```bash
source scripts/utils.sh
source scripts/install-mytool.sh
```

### Best Practices for Scripts

1. **Always check if tool exists first** - makes script idempotent
2. **Provide informative messages** - explain what the tool does
3. **Use confirmation prompts** - give users control
4. **Handle both macOS and Linux** - or clearly state OS requirement
5. **Return proper exit codes** - 0 for success, 1 for failure
6. **Log important actions** - helps with debugging
7. **Offer post-install configuration** - but make it optional

### Adding New Stow Packages

1. **Create package directory**:
```bash
mkdir -p myapp/.config/myapp
```

2. **Add configuration files**:
```bash
myapp/.config/myapp/config.yml
```

3. **Stow will automatically discover it** - no code changes needed!

### Modifying Installation Order

Simply reorder the `run_step` calls in `install.sh`:
```bash
# Want Docker before Dev Tools?
run_step "Docker" "install-docker.sh" "optional"
run_step "Development Tools" "install-dev-tools.sh" "optional"
```

## Troubleshooting

### Installation Issues

**Problem: Script fails with "command not found"**
```bash
# Ensure scripts are executable
chmod +x install.sh scripts/*.sh

# Verify you're in the dotfiles directory
cd ~/dotfiles
./install.sh
```

**Problem: "Permission denied" errors**
- Some installations require sudo (Linux)
- You'll be prompted when needed
- Ensure your user has sudo privileges

**Problem: Homebrew not found after installation**
```bash
# Manually add to current session (macOS)
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel

# Then continue installation
./install.sh
```

**Problem: Stow reports conflicts**
- Backup conflicting files manually
- Or let the installer back them up
- Check `~/.dotfiles_backup_*` directories
```bash
# Manual conflict resolution
mv ~/.zshrc ~/.zshrc.backup
./install.sh
```

### Viewing Installation Log

All actions are logged to `.install.log`:
```bash
# View full log
cat ~/dotfiles/.install.log

# Watch log in real-time (different terminal)
tail -f ~/dotfiles/.install.log

# Search for errors
grep -i error ~/dotfiles/.install.log
```

### Common Issues by Component

#### Docker (Linux)
**Issue:** Permission denied when running docker commands
```bash
# Verify docker group membership
groups | grep docker

# If not in docker group, add yourself
sudo usermod -aG docker $USER

# Log out and back in, or run
newgrp docker
```

#### Zsh
**Issue:** Zsh not default after installation
```bash
# Manually set default shell
chsh -s $(which zsh)

# Verify
echo $SHELL
```

**Issue:** Oh My Zsh plugins not working
```bash
# Check plugin installation
ls ~/.oh-my-zsh/custom/plugins/

# Re-run shell tools installer
source scripts/utils.sh
source scripts/install-shell-tools.sh
```

#### Neovim
**Issue:** LazyVim plugins not loading
```bash
# LazyVim installs plugins on first launch
nvim

# Force plugin update
nvim +Lazy sync
```

#### Claude Code
**Issue:** "claude: command not found"
```bash
# Verify installation
which claude

# Re-install if needed
source scripts/utils.sh  
source scripts/install-claude-code.sh

# Ensure PATH includes Claude
echo $PATH | grep claude
```

### Re-running Installation

The installer is idempotent - safe to run multiple times:
```bash
# Re-run full installation (skips already installed)
./install.sh

# Run specific component only
source scripts/utils.sh
source scripts/install-docker.sh

# Force minimal installation
./install.sh --skip-optional
```

### Uninstalling

To remove symlinked dotfiles:
```bash
cd ~/dotfiles

# Unstow all packages
stow -D */

# Restore from backup
LATEST_BACKUP=$(ls -dt ~/.dotfiles_backup_* | head -1)
cp -r $LATEST_BACKUP/* ~/
```

To remove installed tools, use your package manager:
```bash
# macOS
brew uninstall <tool>

# Linux
sudo apt remove <tool>  # Ubuntu/Debian
```

## Maintenance

### Keeping Everything Updated

#### Update Dotfiles Repository
```bash
cd ~/dotfiles
git pull origin main

# Re-stow to apply changes
stow --restow */
```

#### Update Installed Tools

**macOS:**
```bash
# Update Homebrew
brew update

# Upgrade all packages
brew upgrade

# Check for outdated packages
brew outdated
```

**Linux (Ubuntu/Debian):**
```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade

# Check for upgradable packages
apt list --upgradable
```

#### Update Language Runtimes

**Python:**
```bash
# Update pip
python3 -m pip install --upgrade pip

# Update global packages
pip3 list --outdated
pip3 install --upgrade <package>

# Update pyenv (if installed)
cd ~/.pyenv && git pull
```

**Node.js:**
```bash
# Update npm
npm install -g npm@latest

# Update global packages
npm outdated -g
npm update -g

# Update nvm (if installed)
cd ~/.nvm && git pull
```

#### Update Shell Components

**Oh My Zsh:**
```bash
# Update framework
omz update

# Update custom plugins
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull
cd ~/.oh-my-zsh/custom/plugins/you-should-use && git pull
```

**Starship:**
```bash
# macOS
brew upgrade starship

# Linux
curl -sS https://starship.rs/install.sh | sh
```

#### Update Development Tools
```bash
# Neovim (macOS)
brew upgrade neovim

# Neovim (Linux)
sudo apt update && sudo apt upgrade neovim

# LazyVim plugins
nvim +Lazy sync

# tmux plugins (if using TPM)
~/.tmux/plugins/tpm/bin/update_plugins all
```

### Automated Update Script

Create a convenience script for updates:
```bash
# scripts/update-all.sh
#!/bin/bash

source "$(dirname "$0")/utils.sh"

print_header "Updating All Components"

if is_macos; then
    print_info "Updating Homebrew packages..."
    brew update && brew upgrade
fi

if is_linux; then
    print_info "Updating APT packages..."
    sudo apt update && sudo apt upgrade -y
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_info "Updating Oh My Zsh..."
    omz update
fi

if command_exists nvim; then
    print_info "Updating Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa
fi

print_success "All updates complete!"
```

### Version Checking

Check versions of installed tools:
```bash
# Check all key tools
echo "System: $(uname -s)"
echo "Shell: $SHELL"
zsh --version
nvim --version | head -n1
tmux -V
python3 --version
node --version
npm --version
docker --version
git --version
```

### Cleaning Up
```bash
# Remove old Homebrew versions (macOS)
brew cleanup

# Remove old APT packages (Linux)
sudo apt autoremove
sudo apt autoclean

# Remove old docker images
docker system prune

# Remove old npm cache
npm cache clean --force

# Remove old pip cache
pip3 cache purge
```

## Contributing

To add new functionality:

1. Create a new script in `scripts/`
2. Follow the existing patterns
3. Use utility functions from `utils.sh`
4. Add user confirmation prompts
5. Test on both macOS and Linux if possible
6. Update this README

## License

[Your License]
