# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **zoxide** integration in `.zshrc`: `z` for frecency-based directory jumping, `zi` for interactive fzf pick; fzf key-bindings and completion also enabled; `zsh-interactive-cd` retained alongside
- **Telescope** Neovim plugin: find files (`<leader><space>` / `<leader>ff`), live grep (`<leader>/`), buffer list (`<leader>,`); depends on `fd` (added as Homebrew dependency)
- **neo-tree** Neovim file explorer: toggle with `<leader>e`, follows the current file automatically

### Changed
- **Theme**: Replaced Catppuccin Mocha with **Gruvbox Dark Hard** (`bg #1d2021`) across all 5 terminal emulators (Alacritty, Ghostty, Kitty, WezTerm, iTerm2), tmux status bar, Starship prompt, and Neovim colorscheme (`gruvbox.nvim`, hard contrast)
- **Starship prompt**: Converted from two-line Catppuccin layout to single-line Gruvbox powerline style

### Removed
- `example.lua` no-op plugin stub from Neovim config

## [2.0.0] - 2025-10-27

### Added
- OS-specific installation script directories (`scripts/macos/` and `scripts/linux/`)
- macOS-specific scripts for dev tools, Docker, and fonts (Homebrew-based)
- Linux-specific scripts for dev tools, Docker, and fonts (package manager + AppImage)
- Comprehensive documentation in `scripts/README.md`
- File-based installation status tracking for bash 3.2 compatibility
- Automated OS detection in main install script

### Changed
- **BREAKING**: Restructured installation scripts into OS-specific directories
- Replaced bash 4+ associative arrays with file-based tracking (bash 3.2 compatible)
- Updated `install.sh` to automatically route to correct OS-specific scripts
- Modified `scripts/utils.sh` `run_step()` function for file-based status tracking

### Fixed
- macOS compatibility issues with GNU-specific commands:
  - Removed `grep -oP` (Perl regex - not available in BSD grep)
  - Removed `stat -c%s` (GNU stat format - BSD uses different syntax)
  - Replaced with portable alternatives (`sed` for regex, `wc -c <` for file size)
- Bash 3.2 compatibility for macOS default shell:
  - Fixed corrupted shebang line (`X#!/bin/bash` → `#!/bin/bash`)
  - Removed `declare -A` (requires bash 4+)
  - Implemented file-based status tracking compatible with bash 3.2
- Linux Neovim installation now properly checks version for LazyVim compatibility (>= 0.11.2)
- AppImage installation logic no longer runs on macOS

### Deprecated
- Combined OS installation scripts moved to `scripts/deprecated/`:
  - `install-dev-tools.sh`
  - `install-docker.sh`
  - `install-fonts.sh`

### Technical Details

#### macOS Scripts
- Use Homebrew exclusively for all installations
- Simple, streamlined installation logic
- BSD command compatible
- No version checking needed (Homebrew provides latest)

#### Linux Scripts
- Neovim: AppImage installation with version checking and upgrade logic
- Docker: Full Docker Engine setup with optional Docker Desktop
- Fonts: Multi-distribution support (apt/dnf/pacman) with manual fallback
- Portable command usage throughout

#### Bash Compatibility
- All scripts now compatible with bash 3.2 (macOS default)
- Status tracking uses pipe-delimited file format: `status|step_name`
- No bash 4+ features required

### Migration Guide

For users upgrading from previous versions:

1. The installation experience remains identical - just run `./install.sh`
2. Old combined scripts are preserved in `scripts/deprecated/` for reference
3. No configuration changes required
4. Installation status now tracked in `.install_status` file instead of in-memory

### Testing
- ✅ Verified on macOS with bash 3.2
- ✅ Syntax validation passed for all scripts
- ✅ macOS detection working correctly
- ⚠️  Linux scripts created but not yet tested on Ubuntu

---

## [1.0.0] - 2025-10-24

### Added
- Initial modular installation script system
- Homebrew installation for macOS
- System package installation (stow, git, curl, wget)
- Development runtimes (Python, Node, npm)
- Development tools (Neovim, tmux, starship, bat, fzf, ripgrep, fd, eza)
- Docker and Docker Desktop installation
- Font installation (JetBrains Mono)
- Shell tools (Oh My Zsh, plugins)
- GNU Stow integration for dotfile management
- Installation logging and status tracking
- Terminal emulator installation
- Claude Code CLI installation

### Features
- Interactive prompts with confirmation
- Optional vs required step designation
- Comprehensive error handling
- Installation summary and next steps
- Auto-confirm mode (`--yes` flag)
- Skip optional installations (`--skip-optional` flag)

---

[Unreleased]: https://github.com/kmitch92/dotfiles/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/kmitch92/dotfiles/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/kmitch92/dotfiles/releases/tag/v1.0.0
