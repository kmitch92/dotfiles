# Dotfiles Installation Fixes Applied

## Date: 2025-10-26

### Issues Identified and Fixed

#### 1. **install.sh Script Corruption**
**Problem:**
- Lines 59-65 contained malformed content including `nano ~/dotfiles/install.sh`
- Duplicate installation steps for fonts (lines 62-65)
- Duplicate installation steps for terminal emulators (lines 67-70 and 78-80)

**Fix:**
- Removed all duplicate and malformed content
- Cleaned up the installation flow
- File now has proper sequential installation steps

#### 2. **Package Structure Issues**

**Problem:**
- The `starship` package incorrectly contained configs for multiple tools:
  - nvim configuration (should be separate)
  - dconf (GNOME desktop settings - shouldn't be tracked)
  - pulse (PulseAudio - shouldn't be tracked)
  - org.gnome.Ptyxis (terminal emulator - shouldn't be tracked)
  - tiling-assistant (GNOME extension - shouldn't be tracked)
  - Multiple nvim backup directories
- The `config` package had nvim configuration that belonged in its own package
- System-specific configs were being tracked in git

**Fix:**
- Created separate `nvim` package with proper structure: `nvim/.config/nvim/`
- Removed nvim from the `config` package
- Cleaned up `starship` package to only contain `starship.toml`
- Removed all system-specific configs (dconf, pulse, Ptyxis, tiling-assistant)
- Removed backup directories from starship package
- Updated `.gitignore` to prevent system configs from being committed

#### 3. **Incomplete install-dev-tools.sh Script**

**Problem:**
- The script was truncated at line 69
- Missing the installation logic and verification steps
- Tools were being detected but never installed

**Fix:**
- Added complete installation section with:
  - Platform-specific installation (macOS via Homebrew, Linux via apt/package manager)
  - Special handling for tools with different package names on Linux:
    - `bat` → `bat` or `batcat`
    - `fd` → `fd-find` with symlink creation
    - `eza` → cargo-based installation fallback
  - Post-installation verification
  - Proper error handling and user feedback

#### 4. **zshrc Plugin References**

**Problem:**
- `.zshrc` hardcoded all plugins including `zsh-bat`
- If bat wasn't installed, zsh-bat plugin wouldn't be installed
- Would cause Oh My Zsh errors on startup

**Fix:**
- Changed plugin loading to be dynamic
- Base plugins (git, web-search, zsh-interactive-cd) are always loaded
- Optional plugins (zsh-autosuggestions, zsh-syntax-highlighting, you-should-use, zsh-bat) are only loaded if they exist
- Prevents errors from missing plugins

#### 5. **.gitignore Gaps**

**Problem:**
- No protection against committing system-specific configs
- Backup directories could be committed
- GNOME/Linux desktop configs were being tracked

**Fix:**
- Added comprehensive system-specific config ignores:
  - `*/.config/dconf/` (GNOME settings)
  - `*/.config/pulse/` (PulseAudio)
  - `*/.config/org.gnome.Ptyxis/` (Terminal emulator)
  - `*/.config/tiling-assistant/` (GNOME extension)
  - `*/.config/nvim.backup.*/` (Backup directories)

### Package Structure After Fixes

**IMPORTANT NOTE:** Due to stow conflicts with multiple packages containing `.config/`,
the final structure consolidates all `.config` items into a single `config/` package.

```
dotfiles/
├── zsh/                    # Zsh configuration
│   └── .zshrc
├── tmux/                   # tmux configuration
│   └── .tmux.conf
├── config/                 # ALL .config items (unified to avoid stow conflicts)
│   └── .config/
│       ├── nvim/          # Neovim (LazyVim)
│       ├── starship.toml  # Starship prompt
│       ├── alacritty/     # Terminal emulators
│       ├── kitty/
│       ├── wezterm/
│       └── ghostty/
└── claude/                 # Claude Code
    └── .claude/
```

**Why the change?** GNU Stow cannot handle multiple packages trying to create symlinks
for the same directory (`.config/`). The solution is to keep all `.config` subdirectories
in a single stow package.

### Installation Flow After Fixes

1. ✅ Install Homebrew (macOS only)
2. ✅ Install system packages (stow, git, curl, etc.)
3. ✅ Install fonts (optional)
4. ✅ Install terminal emulators (optional)
5. ✅ Install development runtimes (Python, Node)
6. ✅ Install development tools (neovim, tmux, starship, bat, fzf, ripgrep, fd, eza)
7. ✅ Install Docker (optional)
8. ✅ Install Claude Code (optional)
9. ✅ Install shell tools (Oh My Zsh, plugins)
10. ✅ Setup shell configuration (change default shell to zsh)
11. ✅ Stow dotfiles (symlink all configs)

### Key Improvements

1. **Proper Separation of Concerns**: Each package contains only its relevant configuration
2. **No System-Specific Tracking**: Desktop environment configs are properly ignored
3. **Complete Installation Scripts**: All scripts now have full implementation
4. **Robust Plugin Loading**: Zsh handles missing plugins gracefully
5. **Platform-Aware Installation**: Proper handling of package name differences between macOS and Linux

### Testing Recommendations

1. Test on a fresh Ubuntu installation
2. Test on a fresh macOS installation
3. Verify all symlinks are created correctly
4. Verify neovim LazyVim loads and installs plugins
5. Verify starship prompt shows correctly
6. Verify zsh plugins work (autosuggestions, syntax highlighting)
7. Verify tmux configuration loads

### Next Steps for User

1. **Run the installation**:
   ```bash
   cd ~/dotfiles
   ./install.sh
   ```

2. **Restart your shell**:
   ```bash
   exec zsh
   ```

3. **Verify installations**:
   ```bash
   nvim --version
   tmux -V
   starship --version
   bat --version
   fzf --version
   rg --version
   fd --version
   ```

4. **Launch nvim to install LazyVim plugins**:
   ```bash
   nvim
   # LazyVim will automatically install all plugins
   ```

5. **Optional: Configure Powerlevel10k** (if you prefer it over starship):
   ```bash
   p10k configure
   ```
