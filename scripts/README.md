# Installation Scripts

This directory contains all installation scripts for the dotfiles, organized by operating system.

## Directory Structure

```
scripts/
├── macos/                      # macOS-specific scripts
│   ├── install-dev-tools.sh   # Neovim, tmux, etc. via Homebrew
│   ├── install-docker.sh      # Docker Desktop for macOS
│   └── install-fonts.sh       # Fonts via Homebrew casks
├── linux/                      # Linux-specific scripts
│   ├── install-dev-tools.sh   # Neovim AppImage, tools via package manager
│   ├── install-docker.sh      # Docker Engine + optional Docker Desktop
│   └── install-fonts.sh       # Fonts via package manager or manual install
├── utils.sh                    # Shared utility functions
├── install-homebrew.sh         # Homebrew installation (macOS only)
├── install-packages.sh         # System packages (stow, git, curl, etc.)
├── install-runtimes.sh         # Python, Node, npm
├── install-shell-tools.sh      # Oh My Zsh, plugins
├── install-terminals.sh        # Terminal emulators
├── setup-shell.sh              # Shell configuration
└── setup-stow.sh               # GNU Stow dotfile linking
```

## OS-Specific Scripts

### Why Separate Scripts?

Recent changes introduced GNU-specific commands (like `grep -oP` and `stat -c`) that don't work on macOS. Rather than littering scripts with conditionals and workarounds, we've split OS-specific functionality into dedicated directories.

### Benefits

- **No portability hacks**: Each script uses native commands for its OS
- **Cleaner code**: No complex conditionals checking OS type
- **Easier maintenance**: Changes to one OS don't affect the other
- **Better testing**: Each OS script can be tested independently

### What Goes in OS-Specific Scripts?

Scripts go in `macos/` or `linux/` when they:
- Use OS-specific commands (grep -P, stat formats, etc.)
- Install tools differently (Homebrew vs apt/dnf/pacman)
- Have significantly different installation methods (AppImage vs cask)

Examples:
- **Dev tools**: macOS uses Homebrew, Linux uses AppImage for Neovim
- **Docker**: macOS installs Docker Desktop, Linux offers Docker Engine + optional Desktop
- **Fonts**: macOS uses Homebrew casks, Linux uses package manager or manual install

### What Stays Shared?

Scripts remain in the root `scripts/` directory when they:
- Work the same on all platforms
- Only need simple OS detection (e.g., install-homebrew.sh only runs on macOS)
- Don't use OS-specific commands

## Usage

The main `install.sh` orchestrator automatically selects the correct OS-specific scripts:

```bash
# Automatically uses scripts/macos/install-dev-tools.sh on macOS
# Automatically uses scripts/linux/install-dev-tools.sh on Linux
./install.sh
```

## Key Differences

### Neovim Installation

**macOS**:
- Uses Homebrew
- Always gets latest version
- Simple: `brew install neovim`

**Linux**:
- Package managers often have old versions
- Uses AppImage for LazyVim compatibility (>= 0.11.2)
- Includes version checking and upgrade logic
- Portable regex extraction (no `grep -oP`)
- Portable file size check (no `stat -c`)

### Docker Installation

**macOS**:
- Docker Desktop only (includes Docker Engine)
- Simple Homebrew cask installation

**Linux**:
- Docker Engine via official repos
- Optional Docker Desktop
- Distribution-specific package manager handling
- User group management for docker access

### Font Installation

**macOS**:
- Homebrew cask fonts
- System-wide installation via cask

**Linux**:
- Package manager for common fonts
- Manual download/install for JetBrains Mono
- User-level font directory (~/.local/share/fonts)
- Font cache updates with fc-cache

## Adding New OS-Specific Scripts

When creating a new OS-specific script:

1. Create both versions:
   ```bash
   touch scripts/macos/your-script.sh
   touch scripts/linux/your-script.sh
   chmod +x scripts/{macos,linux}/your-script.sh
   ```

2. Use appropriate commands for each OS:
   - **macOS**: BSD commands, Homebrew
   - **Linux**: GNU commands, apt/dnf/pacman

3. Update `install.sh` to use the correct script:
   ```bash
   if is_macos; then
       run_step "Your Feature" "macos/your-script.sh" "optional"
   elif is_linux; then
       run_step "Your Feature" "linux/your-script.sh" "optional"
   fi
   ```

## Deprecated Scripts

Old combined scripts are in `scripts/deprecated/` for reference but should not be used.
