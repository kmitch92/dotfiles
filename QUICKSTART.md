# Quick Reference

Fast commands for common dotfiles operations.

## Installation
```bash
# Full interactive installation
./install.sh

# Minimal installation (required only)
./install.sh --skip-optional

# Individual component
source scripts/utils.sh
source scripts/install-docker.sh
```

## Updating
```bash
# Update dotfiles from git
cd ~/dotfiles && git pull

# Re-apply dotfiles
cd ~/dotfiles && stow --restow */

# Update all packages (macOS)
brew update && brew upgrade

# Update all packages (Linux)
sudo apt update && sudo apt upgrade -y
```

## Stow Operations
```bash
# Stow a package
cd ~/dotfiles
stow zsh

# Unstow a package
stow -D zsh

# Restow (refresh) a package
stow -R zsh

# Stow all packages
stow */

# Unstow all packages
stow -D */

# Dry run (see what would happen)
stow -n -v zsh
```

## Troubleshooting
```bash
# View installation log
cat ~/dotfiles/.install.log

# Check what's installed
command -v nvim tmux docker node python3

# Find stow conflicts
stow -n -v zsh  # Shows conflicts without making changes

# Check shell
echo $SHELL

# Change default shell
chsh -s $(which zsh)

# Restart shell
exec zsh
```

## Shell
```bash
# Update Oh My Zsh
omz update

# Update all zsh plugins
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull

# Configure Powerlevel10k
p10k configure

# Reload zsh config
source ~/.zshrc
```

## Development Tools
```bash
# Update Neovim plugins
nvim +Lazy sync

# Update Python packages
pip3 list --outdated
pip3 install --upgrade <package>

# Update npm packages
npm outdated -g
npm update -g

# Update Docker images
docker pull <image>

# Claude Code authentication
claude auth
```

## Backup & Recovery
```bash
# List backups
ls -lah ~/.dotfiles_backup_*

# Restore from backup
cp -r ~/.dotfiles_backup_20250126_143052/* ~/

# Create manual backup before changes
cp ~/.zshrc ~/.zshrc.backup
```

## Utility Functions

When writing scripts, use these helpers from `utils.sh`:
```bash
# Source utilities first
source scripts/utils.sh

# Print messages
print_success "Done!"
print_error "Failed"
print_warning "Careful"
print_info "FYI"
print_header "Section Title"
print_step "Installing something"

# Check OS
if is_macos; then
    # macOS code
fi

if is_linux; then
    # Linux code
fi

# Get Linux distro
DISTRO=$(detect_linux_distro)  # ubuntu, debian, fedora, arch, etc

# Ask user
if confirm "Do this?"; then
    # User said yes
fi

# Check command
if command_exists docker; then
    # Docker is installed
fi

# Install Linux package (handles distro differences)
install_linux_package toolname

# Create backup directory
BACKUP_DIR=$(create_backup_dir)
```

## File Structure
```
dotfiles/
├── install.sh              # Main installer
├── scripts/                # Installation scripts
│   ├── utils.sh           # Utility functions
│   ├── install-*.sh       # Component installers
│   └── setup-*.sh         # Configuration scripts
├── zsh/                    # Zsh config package
│   └── .zshrc
├── nvim/                   # Neovim config package
│   └── .config/nvim/
└── .install.log           # Installation log
```

## Quick Checks
```bash
# What's installed?
which nvim tmux starship docker node python3 claude

# What versions?
nvim --version
tmux -V
node --version
python3 --version
docker --version

# Is everything working?
nvim --version && \
tmux -V && \
docker --version && \
node --version && \
python3 --version && \
echo "✓ All tools working"

# Check Oh My Zsh plugins
ls ~/.oh-my-zsh/custom/plugins/
```

## Common Tasks

### Add a new tool
```bash
# 1. Create script
cp scripts/install-dev-tools.sh scripts/install-mytool.sh

# 2. Edit script (update tool name, install commands)
vim scripts/install-mytool.sh

# 3. Add to install.sh
vim install.sh
# Add: run_step "MyTool" "install-mytool.sh" "optional"

# 4. Test
./install.sh
```

### Add new dotfiles
```bash
# 1. Create package directory
mkdir -p mytool/.config/mytool

# 2. Add config file
echo "config: value" > mytool/.config/mytool/config.yml

# 3. Stow it
cd ~/dotfiles
stow mytool

# 4. Verify
ls -la ~/.config/mytool
```

### Update existing config
```bash
# 1. Edit in dotfiles repo
vim ~/dotfiles/zsh/.zshrc

# 2. Re-stow to apply
cd ~/dotfiles
stow -R zsh

# 3. Reload shell
source ~/.zshrc
```

### Remove a stowed package
```bash
# Unstow
cd ~/dotfiles
stow -D zsh

# Verify removal
ls -la ~/.zshrc  # Should no longer be a symlink

# Optionally remove package
rm -rf zsh/
```

## Emergency Recovery
```bash
# Unstow everything
cd ~/dotfiles
stow -D */

# Restore from latest backup
LATEST=$(ls -dt ~/.dotfiles_backup_* | head -1)
cp -r $LATEST/* ~/

# Or restore from git (if configs committed)
git checkout .zshrc .bashrc .config/

# Reboot if shell is broken
# Press Ctrl+Alt+F2 (Linux) or reboot to recovery mode
```

## Links

- **Full Documentation**: [README.md](README.md)
- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Installation Log**: `.install.log`
- **Backups**: `~/.dotfiles_backup_*`

---

**Pro Tip**: Bookmark this file for quick reference!
