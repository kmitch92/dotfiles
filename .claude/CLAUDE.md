# Dotfiles Project - Claude Context

## Project Overview
This is a comprehensive dotfiles repository that provides automated setup for development environments across macOS and Linux systems. The installation is modular and handles system packages, development tools, fonts, shells, and configuration management via GNU Stow.

## Critical Issues Fixed

### Neovim Installation - Dev Build Issue (Fixed: 2025-10-28)

**Problem**:
The `scripts/linux/install-dev-tools.sh` script was downloading Neovim from the `latest` GitHub release tag, which was pointing to a development/nightly build (v0.12.0-dev-1027). This dev build had a broken Lua loader that caused the following error:

```
Error in vim/loader.lua:0: attempt to call upvalue '' (a nil value)
```

This error prevented Neovim from starting and made LazyVim completely unusable.

**Root Cause**:
- Line 198 used: `https://github.com/neovim/neovim/releases/latest/download/nvim.appimage`
- The `latest` tag was pointing to an unstable development build
- The Lua loader in v0.12.0-dev had breaking changes incompatible with LazyVim and runtime files

**Solution Applied**:
1. Changed download URL from `latest` to specific stable version tag:
   ```bash
   # OLD (broken):
   local download_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"

   # NEW (fixed):
   local download_url="https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.appimage"
   ```

   **Important**: GitHub no longer has a `stable` tag for Neovim. Use specific version tags like `v0.11.4` instead.

2. Fixed AppImage filename for x86_64:
   ```bash
   # OLD (broken):
   appimage_name="nvim.appimage"

   # NEW (fixed):
   appimage_name="nvim-linux-x86_64.appimage"
   ```

   **Important**: GitHub changed the AppImage naming convention. The generic `nvim.appimage` no longer exists.

3. Enhanced cleanup to remove ALL old Neovim installations:
   - Added removal of `/usr/bin/nvim` (not just `/usr/local/bin/nvim`)
   - Added removal of `/usr/bin/nvim.dev.backup` if present
   - This ensures no leftover broken installations

4. Changed installation target from `/usr/local/bin/nvim` to `/usr/bin/nvim` for consistency with system expectations

5. Updated minimum version requirement from 0.11.2 to 0.10.0 (more realistic for stable channel)

**Files Modified**:
- `scripts/linux/install-dev-tools.sh`

**Testing Required**:
To test the fix, run:
```bash
cd ~/dotfiles
./install.sh -y
# OR specifically run just the dev tools step:
source scripts/utils.sh && source scripts/linux/install-dev-tools.sh
```

**Expected Result**:
- Neovim v0.10.x (stable) should be installed
- `nvim --version` should show a stable version (not dev)
- `nvim` should launch without any Lua loader errors
- LazyVim should bootstrap and install plugins successfully

## Architecture & Key Files

### Installation Flow
1. **install.sh** - Main orchestrator
   - Detects OS (macOS/Linux)
   - Runs installation steps in order
   - Tracks progress in `.install_status` and `.install.log`

2. **scripts/utils.sh** - Shared utility functions
   - Color output helpers
   - Confirmation prompts
   - Package installation helpers
   - Step execution framework

3. **scripts/linux/install-dev-tools.sh** - Linux dev tools
   - Installs Neovim, tmux, starship, bat, fzf, ripgrep, fd, eza
   - **Key function**: `install_neovim_appimage()` - handles Neovim AppImage installation
   - Version checking logic for upgrade decisions

4. **scripts/setup-stow.sh** - GNU Stow configuration
   - Symlinks dotfiles from repo to home directory

### Configuration Structure
```
dotfiles/
├── config/           # Actual config files (source for stow)
│   └── .config/
│       ├── nvim/     # Neovim/LazyVim configuration
│       ├── tmux/     # Tmux configuration
│       └── ...
├── scripts/          # Installation scripts
│   ├── linux/        # Linux-specific installers
│   ├── macos/        # macOS-specific installers
│   └── utils.sh      # Shared utilities
└── install.sh        # Main installer
```

## Common Gotchas

### 1. GitHub Release Tags: `latest` vs `stable` vs specific versions
- **DO NOT** use `/releases/latest/download/` for tools that have separate stable and nightly builds
- GitHub projects may not have a `stable` tag - always check available releases first
- **BEST PRACTICE**: Use specific version tags like `/releases/download/v0.11.4/` for reproducible installations
- The `latest` tag can point to pre-releases, dev builds, or nightly builds
- **Neovim specifically**: No `stable` tag exists; use specific version tags like `v0.11.4`
- AppImage filenames changed: `nvim.appimage` → `nvim-linux-x86_64.appimage` (check GitHub releases for current naming)

### 2. Neovim Installation Paths
- System package managers typically install to: `/usr/bin/nvim`
- Manual/AppImage installs often go to: `/usr/local/bin/nvim`
- Always clean up BOTH locations to avoid conflicts
- Check PATH order: `/usr/local/bin` usually takes precedence over `/usr/bin`

### 3. LazyVim Requirements
- Minimum Neovim version: 0.10.0 (stable)
- Dev/nightly builds may have breaking changes
- Always test with stable versions first

### 4. Sudo in Scripts
- Installation scripts need sudo for:
  - Package manager operations (apt, dnf, pacman)
  - Installing to system directories (/usr/bin, /usr/local/bin)
  - Removing old installations
- Cannot be fully automated without interactive password prompt or NOPASSWD sudo

## Troubleshooting Neovim Issues

### Symptom: Lua loader errors on startup
```
Error in vim/loader.lua:0: attempt to call upvalue '' (a nil value)
```

**Diagnosis**:
1. Check version: `nvim --version`
2. If version shows `dev`, `nightly`, or pre-release: version mismatch
3. Check installation location: `which nvim` and `ls -la $(which nvim)`

**Fix**:
1. Clear caches: `rm -rf ~/.cache/nvim/`
2. Remove plugins: `rm -rf ~/.local/share/nvim/`
3. Reinstall stable Neovim: `cd ~/dotfiles && source scripts/utils.sh && source scripts/linux/install-dev-tools.sh`

### Symptom: Multiple Neovim versions installed
**Check**:
```bash
ls -la /usr/bin/nvim* /usr/local/bin/nvim* 2>/dev/null
which -a nvim
```

**Fix**:
Remove all versions and reinstall:
```bash
sudo rm -f /usr/bin/nvim* /usr/local/bin/nvim*
cd ~/dotfiles && source scripts/utils.sh && source scripts/linux/install-dev-tools.sh
```

## Future Improvements
- [ ] Add version pinning option (e.g., install specific Neovim version)
- [ ] Add automated testing for install scripts
- [ ] Consider using Neovim PPA for Ubuntu instead of AppImage
- [ ] Add rollback mechanism if installation fails
- [ ] Document all optional installation flags
