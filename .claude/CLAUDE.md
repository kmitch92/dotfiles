# Dotfiles Project - Claude Context

## Project Overview
This is a comprehensive dotfiles repository that provides automated setup for development environments across macOS and Linux systems. The installation is modular and handles system packages, development tools, fonts, shells, and configuration management via GNU Stow.

## Critical Issues Fixed

### Playwright MCP Package Migration (Fixed: 2025-10-30)

**Problem**:
The playwright MCP server was failing to load with error: `'@playwright/mcp-server@*' is not in this registry`. The package doesn't exist on npm.

**Root Cause**:
- The MCP template (`mcp/mcp.json.template:24`) was configured with incorrect package name: `@playwright/mcp-server`
- The correct package is `@modelcontextprotocol/server-puppeteer`
- However, as of 2025, the original package is no longer supported/maintained
- Need to migrate to maintained fork

**Solution Applied**:
1. Updated `mcp/mcp.json.template` line 24 to use `@hisma/server-puppeteer` (maintained fork)
2. Regenerated deployed config: ran `./scripts/setup-mcp.sh`
3. Verified `~/.mcp.json` contains correct package reference
4. Result: Playwright MCP server loads successfully

**Files Modified**:
- `mcp/mcp.json.template` (line 24: `@playwright/mcp-server` → `@hisma/server-puppeteer`)
- `~/.mcp.json` (regenerated from updated template)

**Key Lessons**:
1. **Package naming matters**: `@playwright/mcp-server` never existed; correct name was `@modelcontextprotocol/server-puppeteer`
2. **Maintained fork**: Original package archived/unsupported as of 2025; `@hisma/server-puppeteer` is the maintained fork (v0.6.2+)
3. **Alternative packages available**: `puppeteer-mcp-server` is an experimental alternative
4. **Template changes require redeployment**: Always run `./scripts/setup-mcp.sh` after editing `mcp/mcp.json.template`

### Statusline Config Reversion (Fixed: 2025-10-30)

**Problem**:
The deployed statusline config (`~/.config/ccstatusline/settings.json`) reverted to having `powerline: enabled: false` instead of the intended powerline + gruvbox theme configuration.

**Root Cause**:
The deployed file was a regular file (not symlinked), suggesting it was manually edited or overwritten by a tool/process outside of Stow management. The source of truth in `dotfiles/config/.config/ccstatusline/settings.json` was correct, but the deployed version was wrong.

**Solution Applied**:
1. Copied correct config from source to deployment location: `cp dotfiles/config/.config/ccstatusline/settings.json ~/.config/ccstatusline/settings.json`
2. Verified deployed config now has powerline enabled with gruvbox theme
3. Result: Statusline displays with powerline arrows and gruvbox colors

**Files Modified**:
- `~/.config/ccstatusline/settings.json` (restored from correct source)

**Key Lesson**:
The deployed statusline config can be overwritten by processes outside of Stow. If reversion happens again, investigate what tool/process is modifying `~/.config/ccstatusline/settings.json` and prevent it from doing so. The canonical source is always `dotfiles/config/.config/ccstatusline/settings.json`.

### MCP Server Dependencies - Missing uvx Runtime (Fixed: 2025-10-30)

**Problem**:
MCP servers serena, aws-core, and aws-cdk were failing to load. Claude Code showed errors about uvx command not found, and the deployed configuration at `~/.mcp.json` was out of date with the template.

**Root Cause**:
- **Missing uvx runtime**: uvx (Python/uv package runner) was not installed on the system
- **Out-of-date deployment**: `~/.mcp.json` contained old serena configuration (URL without git+ prefix)
- **Overly strict validation**: setup-mcp.sh required ANTHROPIC_API_KEY even though user didn't need taskmaster server

**Solution Applied**:
1. Installed uv/uvx via Homebrew: `brew install uv` (v0.9.5)
2. Modified `scripts/setup-mcp.sh` to make ANTHROPIC_API_KEY optional:
   - Changed from exit-on-missing to warning-on-missing
   - Allows setup to proceed without taskmaster if user doesn't need it
3. Re-ran `./scripts/setup-mcp.sh` to regenerate `~/.mcp.json` with updated template
4. Verified all MCP servers load correctly (context7, serena, sequential-thinking, playwright, aws-core, aws-cdk)

**Files Modified**:
- `scripts/setup-mcp.sh` (made ANTHROPIC_API_KEY optional)
- `~/.mcp.json` (regenerated from updated template)
- System: Installed uv/uvx v0.9.5

**Key Lessons**:
1. **Runtime dependencies are critical** - MCP servers require specific runtimes (npx for Node.js servers, uvx for Python servers)
2. **Template changes require redeployment** - Editing `mcp/mcp.json.template` doesn't automatically update `~/.mcp.json`
3. **Optional dependencies should be optional** - Don't fail setup for API keys the user doesn't need
4. **uvx is relatively new** - Not installed by default, must be explicitly added via `brew install uv`

**Follow-up Actions**:
- Added uv/uvx installation to `scripts/install-runtimes.sh` (2025-10-30)
- Future dotfiles installations will automatically include uv/uvx
- No manual installation required for new users

### MCP Configuration Templating - Stow Conflict (Fixed: 2025-10-29)

**Problem**:
The MCP configuration file (`~/.mcp.json`) was being created as a symlink by GNU Stow, pointing to the template file with unsubstituted environment variables. This caused Claude Code to fail loading MCP servers with error:

```
[Warning] [context7] mcpServers.context7: Missing environment variables: CONTEXT7_API_KEY
```

**Root Cause**:
- GNU Stow treated `mcp/` as a package and created: `~/.mcp.json` → `dotfiles/mcp/.mcp.json`
- This symlink pointed to the **template** with `${CONTEXT7_API_KEY}` placeholder
- `setup-mcp.sh` would remove the symlink and generate proper file, but Stow would recreate it on next run
- **Architectural conflict**: Can't have both a Stow-managed symlink AND a generated file with substituted secrets

**Solution Applied**:
1. Renamed template: `mcp/.mcp.json` → `mcp/mcp.json.template`
2. Updated `scripts/setup-mcp.sh:135` to use new template path
3. Modified `scripts/setup-stow.sh:32` to exclude `mcp/` directory from Stow packages
4. Result: Only `setup-mcp.sh` manages `~/.mcp.json` (no Stow interference)

**Files Modified**:
- `mcp/.mcp.json` → `mcp/mcp.json.template` (git mv)
- `scripts/setup-mcp.sh` (line 135)
- `scripts/setup-stow.sh` (line 32)
- `.claude/CLAUDE.md` (documentation updates)

**Key Lesson**:
- **Templating tool**: `envsubst` from GNU gettext works perfectly for variable substitution
- **Not overcomplicated**: The templating itself is simple and standard
- **Real issue**: Architectural conflict between Stow's symlink management and runtime secret substitution
- **Solution**: Exclude template directories from Stow; manage them separately

### Claude Code Statusline Configuration - Duplicate Config Issue (Fixed: 2025-10-30, Superseded: 2025-10-31)

**Problem**:
Claude Code statusline displayed basic separators and colors instead of powerline display with gruvbox theme. The intended powerline configuration was not being loaded.

**Root Cause**:
- **Intended config**: `config/.config/ccstatusline/settings.json` (powerline enabled, gruvbox theme, custom fields)
- **Problematic duplicate**: `tmux/.config/ccstatusline/settings.json` (untracked, powerline disabled, basic settings)
- When GNU Stow processed packages, `tmux/.config/` contents overwrote `config/.config/` contents
- Claude Code loaded the duplicate config instead of the intended one (confirmed by MD5 hash match)
- The duplicate also included `tmux/.config/git/ignore`, causing additional conflicts

**Solution Applied**:
1. Removed untracked duplicate directories: `tmux/.config/ccstatusline/` and `tmux/.config/git/`
2. Unstowed tmux package to clear conflicting symlinks: `stow --delete tmux`
3. Restowed config package to establish correct configuration: `stow --restow config`
4. Restowed tmux package for tmux-specific configs only: `stow tmux`
5. Verified deployed config matches intended config (MD5 hash match)

**Files Removed**:
- `tmux/.config/ccstatusline/settings.json` (untracked duplicate)
- `tmux/.config/git/ignore` (untracked duplicate)

**Key Lesson**:
- **Configuration ownership**: Each config file should exist in only ONE stow package to prevent conflicts
- **Package separation**: Keep tmux-specific configs in `tmux/.config/tmux/`, keep general configs in `config/.config/`
- **Verify stow order**: Later-processed packages can overwrite earlier ones if they contain overlapping paths
- **Solution**: Maintain strict separation - tmux package should only contain tmux-specific files under `.config/tmux/`

**Configuration Location Rules** (Obsolete as of 2025-10-31):
- ✓ `config/.config/ccstatusline/` - Claude Code statusline config (ONLY location)
- ✓ `config/.config/git/` - Git global config (ONLY location)
- ✓ `tmux/.config/tmux/` - Tmux-specific configs and scripts *(moved to config/ package on 2025-10-31)*
- ✓ `tmux/.tmux.conf` - Tmux main configuration
- ✗ `tmux/.config/ccstatusline/` - NEVER (causes conflicts)
- ✗ `tmux/.config/git/` - NEVER (causes conflicts)

**Note**: This fix was temporary. The root cause was resolved permanently on 2025-10-31 through package architecture restructuring. All `.config/` subdirectories now live in the `config/` package only. See "Package Architecture Restructuring - Permanent Fix" section below.

### Technical Enforcement (Added: 2025-10-30, Superseded: 2025-10-31)

**Problem with Documentation-Only Approach**:
The initial fix only removed duplicate files without preventing their return. The `.gitignore` rule `!tmux/**` (line 90) whitelisted ALL files under tmux/, allowing duplicates to be created and tracked again.

**Root Cause of Recurrence**:
- Files were removed but not ignored by git
- No technical barrier prevented recreating `tmux/.config/ccstatusline/` or `tmux/.config/git/`
- Duplicates appeared again as untracked files
- User had to manually notice and remove them again

**Solution Applied - Gitignore Enforcement (Option 3: Aggressive)**:

Added to `.gitignore` after line 90:
```gitignore
# But NEVER track .config/* in tmux package (belongs in config/ package)
tmux/.config/*/
!tmux/.config/tmux/
```

**How It Works**:
1. Blocks ANY subdirectory under `tmux/.config/` from being tracked
2. EXCEPT `tmux/.config/tmux/` (legitimate tmux-specific configs remain whitelisted)
3. Prevents ccstatusline, git, and all future cross-package conflicts
4. Root-level tmux files (`.tmux.conf`) remain tracked normally

**Verification**:
- Test files under `tmux/.config/ccstatusline/` are automatically ignored
- Git check-ignore confirms: `.gitignore:92:tmux/.config/*/`
- Legitimate files (`.tmux.conf`, `tmux/.config/tmux/*`) remain tracked
- Duplicate files physically removed from repository

**Why This Approach**:
- **Automatic enforcement**: Git prevents accidental staging/committing of duplicates
- **Comprehensive**: Blocks ALL potential config conflicts, not just known ones
- **Low maintenance**: No need to add exclusions for each new conflict
- **Aligns with documented rules**: Enforces "tmux/.config/ccstatusline/ NEVER" policy

**Result**:
Configuration separation is now technically enforced, not just documented. Duplicate configs cannot be accidentally committed to the repository.

**Note**: Gitignore rules were removed on 2025-10-31 as part of package architecture restructuring. The problem is now solved architecturally - `tmux/.config/` no longer exists, so there's nothing to ignore. See next section for permanent fix.

### Package Architecture Restructuring - Permanent Fix (Implemented: 2025-10-31)

**Problem**:
The previous fixes (duplicate removal + gitignore rules) addressed symptoms but not the root cause: multiple stow packages trying to own the same directory tree (`~/.config/`). This violated stow's fundamental principle: **"one package owns one directory tree."**

**Architectural Issue**:
```
config/.config/  → tries to create: ~/.config/ → dotfiles/config/.config/
tmux/.config/    → tries to create: ~/.config/ → dotfiles/tmux/.config/
Result: Last package stowed overwrites the first, causing conflicts
```

**Root Cause Analysis**:
- Following "one package per tool" pattern (tmux, zsh, nvim) seemed logical
- But created ownership conflict when multiple packages needed `~/.config/` subdirectories
- Gitignore rules prevented git tracking but didn't prevent stow conflicts
- Duplicates kept reappearing because stow processing order was unpredictable

**Permanent Solution Applied**:

**New Architecture**: `config/` package owns ALL `~/.config/` contents

```
Before (broken):                After (fixed):
tmux/.config/tmux/       →     config/.config/tmux/
tmux/.config/ccstatusline/ →   (deleted - was duplicate)
tmux/.tmux.conf          →     tmux/.tmux.conf (unchanged)

config/.config/tmux/     →     config/.config/tmux/ (moved from tmux/)
config/.config/ccstatusline/ → config/.config/ccstatusline/ (unchanged)
config/.config/nvim/     →     config/.config/nvim/ (unchanged)
...
```

**Changes Made**:
1. Moved `tmux/.config/tmux/` → `config/.config/tmux/` (git mv for history)
2. Deleted duplicate `tmux/.config/ccstatusline/`
3. Removed empty `tmux/.config/` directory
4. Removed gitignore rules (lines 93-95) - no longer needed
5. Updated documentation

**Package Ownership Rules (Enforced by Structure)**:
- ✓ `config/` owns **ALL** of `~/.config/` (single source of truth)
- ✓ `tmux/` owns root-level tmux files only (`.tmux.conf`)
- ✓ `zsh/` owns root-level zsh files only (`.zshrc`, `.zshenv`)
- ✓ Each package owns completely distinct directory trees (no conflicts possible)

**Key Benefits**:
1. **Stow conflicts physically impossible** - no overlapping ownership
2. **Duplicates physically impossible** - only one location exists for each config
3. **No gitignore rules needed** - architecture prevents the problem
4. **Simpler mental model** - clear ownership boundaries
5. **Deployed paths unchanged** - `~/.config/tmux/scripts/...` still works

**Migration Impact**:
- ✓ No breaking changes to deployed configurations
- ✓ `.tmux.conf` references `~/.config/tmux/scripts/...` (deployed path, unchanged)
- ✓ All other tools reference `~/.config/...` paths (unchanged)
- ✓ Git history preserved (used `git mv`)

**Verification**:
- Tmux package contains only `.tmux.conf`
- Config package contains all `.config/` subdirectories
- Stow processes without conflicts
- Deployed symlinks correct

**Result**:
Problem solved architecturally, not just symptomatically. The duplicate config issue cannot recur because the structure that allowed it no longer exists.

### Main Agent Delegation Enforcement - Technical Limitations (Investigated: 2025-10-30)

**Goal:**
Implement technical enforcement to restrict main agent to orchestration-only role, forcing delegation to specialized subagents for all code implementation (inspired by coygeek's solution in GitHub issue #6800).

**Approaches Tested:**

**Approach 1: Global permissions.deny[]**
```json
{
  "permissions": {
    "deny": ["Edit", "MultiEdit", "Write"]
  }
}
```
- **Result**: ✗ Failed - Blocked ALL agents including subagents
- **Finding**: Global deny list creates hard block that cannot be overridden by agent `tools:` field
- **Conclusion**: Deny list is too aggressive, blocks legitimate subagent operations

**Approach 2: Remove from permissions.allow[]**
```json
{
  "permissions": {
    "allow": [
      "Read", "Grep", "Glob", "Task", "TodoWrite"
      // Removed: "Edit", "Write", "MultiEdit", "NotebookEdit"
    ],
    "defaultMode": "default"  // Changed from "bypassPermissions"
  }
}
```
- **Result**: ✗ Failed - Only added approval prompt, didn't deny access
- **Finding**: Removing from allow list + `defaultMode: "default"` prompts user for approval rather than creating hard block
- **Test**: Main agent successfully used Write tool after user approval
- **Conclusion**: Permission system designed for user control, not agent-specific restrictions

**Root Cause:**
Claude Code's permission model doesn't support agent-specific overrides. The system is designed for:
1. User-controlled approvals (via prompts)
2. Global security constraints (deny dangerous operations)
3. NOT for differential permissions between main agent and subagents

**Solution Implemented:**
**Option 2: Documentation-Only Enforcement**
- Updated `~/.claude/CLAUDE.md` with new section "II. Main Agent Role: Orchestration Only"
- Explicit rules: NEVER write code, edit files, or create files directly
- Training mechanism: User corrects when main agent violates pattern
- Meta-tasks exception: Reading, read-only bash, research, task tracking allowed

**Key Lessons:**
1. **Claude Code permissions are user-centric, not agent-centric** - Designed to protect user/system, not enforce architectural patterns
2. **Agent tools: field doesn't override global restrictions** - Cannot grant back permissions that are globally denied
3. **defaultMode values**:
   - `"bypassPermissions"` - Skip all permission checks
   - `"default"` - Prompt user for approval on disallowed operations
   - `"acceptEdits"` - Auto-accept edit operations
   - `"plan"` - Force plan mode
4. **Documentation-based enforcement is the only viable option** - Rely on clear instructions + user correction

**Files Modified (then reverted):**
- `claude/.claude/settings.json` - Tested both approaches, reverted to original
- `~/.claude/CLAUDE.md` - Added delegation emphasis (permanent change)

**Reference:**
- GitHub issue: anthropics/claude-code#6800 (coygeek's solution)
- Findings suggest the issue author may have misunderstood how permissions work, or Claude Code's permission model changed since their post

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

## Font Management

### Installation Approach
Fonts are installed via **package managers and automated scripts**, NOT tracked as binary files in git.

**Why this approach:**
- Keeps git repository lean (no large binary blobs)
- Declarative: "what to install" not "the files themselves"
- Easy to update via package managers
- Cross-platform support (macOS Homebrew, Linux package managers)

### Installed Fonts

**Primary Coding Font:**
- **JetBrains Mono** - Main font for terminal and code editors
  - macOS: Installed via Homebrew (`font-jetbrains-mono`)
  - Linux: Downloaded from GitHub releases

**Powerline Fonts** (Terminal styling and status bars):
- **Meslo for Powerline** - Popular monospace font with powerline glyphs
- **DejaVu Sans Mono for Powerline** - Classic monospace with powerline support
- **Inconsolata for Powerline** - Clean monospace with powerline glyphs
- **Powerline Symbols** - Universal powerline symbol font
  - macOS: Installed via Homebrew casks
  - Linux: Installed via distro package managers (fonts-powerline, powerline-fonts)

**Optional Developer Fonts:**
- Fira Code - Font with programming ligatures
- Hack - Clean, readable monospace font
- Source Code Pro - Adobe's coding font

### Usage in Configurations

**Kitty Terminal** (`config/.config/kitty/kitty.conf`):
```
font_family      JetBrains Mono
tab_bar_style    powerline
tab_powerline_style slanted
```

**Status Bars/Prompts:**
- Powerline fonts provide special glyphs (arrows, separators, branch symbols)
- Used by: tmux status bars, shell prompts (starship), vim statusline

### Installation Scripts

**macOS**: `scripts/macos/install-fonts.sh`
- Installs fonts via Homebrew casks
- Interactive prompts for each font category

**Linux**: `scripts/linux/install-fonts.sh`
- Uses distro package managers (apt, dnf, pacman)
- Falls back to manual download from GitHub for unsupported distros

### Manual Font Installation

If you manually install fonts to `~/Library/Fonts/` (macOS) or `~/.local/share/fonts/` (Linux), they will NOT be tracked in git. To ensure reproducibility:

1. Add the font to the appropriate installation script
2. Test the installation on a clean system
3. Update this documentation with any new fonts

**DO NOT:**
- Commit binary font files to git
- Create font directories in the dotfiles repo for tracking
- Rely on manual font copying for reproducibility

## Tmux Configuration

### Overview
Tmux configuration with Catppuccin Mocha theme, vim-like keybindings, and smart automatic window naming.

### Window Naming

**Automatic abbreviated window names** based on git repository + branch:

- **Format**: `repo/branch` abbreviated to first 3 chars of each word
- **Examples**:
  - `dotfiles` (main branch) → `dot/mai`
  - `my-awesome-project` (feature-branch) → `my-awe-pro/fea-bra`
  - `/tmp` (non-git directory) → `tmp`

**Implementation**:
- **Script**: `config/.config/tmux/scripts/tmux-window-name.sh` (source), deployed to `~/.config/tmux/scripts/tmux-window-name.sh`
- **Logic**: Extracts git repo root and branch, abbreviates each word (hyphenated, camelCase, underscore-separated)
- **Fallback**: If not in git repo, shows abbreviated directory name
- **Updates**: Automatically as you `cd` between directories

**Configuration** (`tmux/.tmux.conf`):
```bash
set-option -g automatic-rename on
set-option -g automatic-rename-format '#(~/.config/tmux/scripts/tmux-window-name.sh "#{pane_current_path}")'
```

**Manual rename**: Use `Prefix + ,` to manually rename a window (overrides automatic naming for that window)

### Key Features
- **Prefix**: `Ctrl-a` (changed from default `Ctrl-b`)
- **Split panes**: `|` horizontal, `-` vertical
- **Navigate panes**: Vim keys (`h`, `j`, `k`, `l`) or Alt+arrows (no prefix needed)
- **Resize panes**: `Prefix + H/J/K/L` (capital letters)
- **Copy mode**: Vim-like (`v` to select, `y` to yank)
- **Mouse support**: Enabled for pane selection and resizing
- **Catppuccin Mocha theme**: Purple accents, dark background
- **Status bar**: Shows session name, user, date/time, hostname

## MCP Server Configuration

### Overview
Model Context Protocol (MCP) servers extend Claude Code with additional capabilities like documentation lookup, browser automation, AWS management, and structured thinking tools.

### Installation Approach
MCP servers are configured via **template + environment variables**, NOT committed with secrets.

**Why this approach:**
- Secrets (API keys) never committed to git
- Template is version controlled for reproducibility
- Easy to regenerate configuration on new machines
- Cross-platform support (uses standard bash tools)

### Configured MCP Servers

**Documentation & Context:**
- **Context7** - Up-to-date documentation from official sources (requires Upstash API key)

**Code Intelligence:**
- **Serena** - Semantic code retrieval and editing toolkit using LSP (Language Server Protocol). Provides IDE-like symbol analysis, find-references, and code navigation. Supports Python, TypeScript/JavaScript, Java, Go, Rust, C/C++, PHP.

**Task Management:**
- **TaskMaster** - AI-powered task management for development workflows. PRD parsing, task CRUD with dependency tracking, complexity analysis, and context-based organization (requires Anthropic API key).

**Problem Solving:**
- **Sequential Thinking** - Structured problem-solving with dynamic refinement

**Browser Automation:**
- **Playwright** - Cross-browser automation (Chrome, Firefox, Safari, Edge)

**AWS Infrastructure:**
- **AWS Core** - Foundation server for AWS operations (required for other AWS servers)
- **AWS CDK** - Infrastructure as Code with AWS CDK best practices

### Configuration Files

**`mcp/mcp.json.template`** - Template with environment variable placeholders (NOT stowed):
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp", "--api-key", "${CONTEXT7_API_KEY}"]
    }
  }
}
```

**`.env.mcp`** - Template for environment variables (version controlled):
```bash
# Context7 API Key (get from https://console.upstash.com)
# REQUIRED: Context7 server will fail without this
CONTEXT7_API_KEY=your_api_key_here

# Anthropic API Key (get from https://console.anthropic.com)
# OPTIONAL: Only needed if using TaskMaster server for AI-powered task management
# Setup will proceed with warning if missing
ANTHROPIC_API_KEY=your_api_key_here
```

**`.env.mcp.local`** - Actual secrets (gitignored, user creates):
```bash
# Required for Context7 documentation lookup
CONTEXT7_API_KEY=ctx7sk-actual-key-here

# Optional - only add if you want to use TaskMaster
# ANTHROPIC_API_KEY=sk-ant-actual-key-here
```

**`scripts/setup-mcp.sh`** - Substitutes env vars from `.env.mcp.local` into template and deploys to `~/.mcp.json`
  - Removes symlinks if present (file must be generated, not symlinked)
  - Validates required runtime tools (npx, uvx) - exits with helpful message if missing
  - Validates CONTEXT7_API_KEY (required) - exits if missing
  - Warns about ANTHROPIC_API_KEY if missing but continues (optional, only needed for taskmaster)
  - **Note**: `mcp/` directory is excluded from GNU Stow to prevent symlink conflicts

### Setup Process

**First Time Setup:**
```bash
cd ~/dotfiles
./install.sh  # Creates .env.mcp.local from template if missing
# Edit .env.mcp.local with your actual API keys
./scripts/setup-mcp.sh
```

**Note**: Running `./install.sh` will prompt you to install uv/uvx during the "Development Runtimes" step (Step 4). This is required for Python-based MCP servers (serena, aws-core, aws-cdk). Accept the prompt to ensure all MCP servers can load correctly.

**Update Configuration:**
```bash
cd ~/dotfiles
# Edit mcp/mcp.json.template to add/remove/change servers
./scripts/setup-mcp.sh  # Regenerate ~/.mcp.json
# Restart Claude Code to load changes
```

**Verify Setup:**
```bash
# Check deployed configuration
cat ~/.mcp.json

# In Claude Code, run:
/mcp
```

### MCP Server Dependencies

MCP servers require specific runtime environments to execute. Missing dependencies will cause servers to fail loading.

**npx (Node.js/npm)** - Required for Node.js-based servers:
- **Servers**: context7, sequential-thinking, playwright, taskmaster
- **Installation**: Automatically handled by `./install.sh` (Step 4: Development Runtimes)
- **Manual install (if needed)**:
  - macOS: `brew install node`
  - Linux: Use distro package manager (nodejs, npm)
- **Verify**: `which npx` should return a path

**uvx (Python/uv)** - Required for Python-based servers:
- **Servers**: serena, aws-core, aws-cdk
- **Installation**: Automatically handled by `./install.sh` (Step 4: Development Runtimes)
- **Manual install (if needed)**:
  - macOS: `brew install uv`
  - Linux: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Verify**: `which uvx` should return a path
- **Note**: uvx is relatively new (2024+), installation is prompted during dotfiles setup

**setup-mcp.sh Dependency Checking**:
- Script validates both npx and uvx are installed before attempting deployment
- Exits with helpful message if either is missing: "Error: uvx not found. Install with: brew install uv"
- Ensures user knows exactly what to install to fix the issue
- **Recommendation**: If you see this error, re-run `./install.sh` and accept the "Development Runtimes" step

### Getting API Keys

**Context7 (Upstash):**
1. Visit https://console.upstash.com
2. Create account or sign in
3. Generate Context7 API key
4. Add to `.env.mcp.local`

**AWS:**
- Configure AWS CLI: `aws configure`
- Servers use AWS_REGION environment variable (defaults to eu-west-2)
- No API keys needed in MCP config (uses AWS CLI credentials)

**TaskMaster (Anthropic):**
1. Visit https://console.anthropic.com
2. Create account or sign in
3. Generate API key
4. Add to `.env.mcp.local` (optional - only if you want AI-powered task management)

### Understanding Configuration Warnings

**"File does not exist" warning for project-level .mcp.json**:

When working in the dotfiles directory, you may see this warning in Claude Code:
```
[Warning] MCP config file does not exist: /Users/username/dotfiles/.mcp.json
```

**This is expected behavior and NOT a problem:**

1. **Claude Code's configuration hierarchy**: Claude Code checks for MCP configuration in this order:
   - Project-level: `<project-dir>/.mcp.json` (checked first)
   - Global: `~/.mcp.json` (fallback if project-level doesn't exist)

2. **Why the warning appears**:
   - The dotfiles directory doesn't have a project-level `.mcp.json` (by design)
   - Claude Code checks for it, doesn't find it, logs a warning
   - Immediately falls back to global `~/.mcp.json` which DOES exist

3. **How to verify it's working correctly**:
   - Run `/mcp` in Claude Code - you should see all configured servers loaded
   - Check logs: MCP servers should initialize successfully after the warning
   - The warning only appears when working in dotfiles directory, not in other projects

4. **Why we don't create a project-level .mcp.json in dotfiles**:
   - The dotfiles directory is for managing configurations, not a development project
   - Global `~/.mcp.json` is the correct location for system-wide MCP configuration
   - Creating `.mcp.json` in dotfiles would be redundant and confusing

**Bottom line**: If MCP servers load correctly (verify with `/mcp`), the warning is benign. Servers are loading from `~/.mcp.json` as intended.

### Troubleshooting

**MCP servers not loading:**
1. Check `~/.mcp.json` exists and is valid JSON
2. Verify no `${VAR}` patterns remain (means env var not substituted)
3. **Check runtime dependencies installed**:
   - For Node.js servers: `which npx` (install: `brew install node`)
   - For Python servers: `which uvx` (install: `brew install uv`)
4. Check Claude Code logs: `~/.claude/logs/`
5. Restart Claude Code
6. Try: `claude --mcp-debug` for detailed logging

**"File does not exist" warning for .mcp.json:**
- **Expected behavior** when working in dotfiles directory
- Verify servers load correctly: run `/mcp` in Claude Code
- If servers are listed and working, warning is benign
- Servers load from global `~/.mcp.json` (fallback location)
- See "Understanding Configuration Warnings" section above for full explanation

**Environment variable not substituted:**
1. Check `.env.mcp.local` exists and has correct syntax
2. Verify `envsubst` is installed (setup-mcp.sh will try to install)
3. Check `setup-mcp.sh` output for warnings about missing variables
4. Re-run `./scripts/setup-mcp.sh` and review output carefully

**uvx or npx command not found:**
1. **Preferred**: Re-run `./install.sh` and accept the "Development Runtimes" step (installs both uv/uvx and Node.js/npx)
2. **Manual install - uvx**:
   - macOS: `brew install uv`
   - Linux: `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. **Manual install - npx**:
   - macOS: `brew install node`
   - Linux: Use distro package manager (nodejs, npm)
4. Verify installation: `which uvx` and `which npx` should return paths
5. Re-run `./scripts/setup-mcp.sh` after installing missing dependencies
6. Restart Claude Code to reload MCP servers

**AWS servers failing:**
1. Ensure `aws-core` server loads first (it's a dependency)
2. Check AWS CLI is configured: `aws sts get-caller-identity`
3. Verify AWS_REGION is set correctly in `mcp/.mcp.json`

**TaskMaster server failing:**
- TaskMaster requires ANTHROPIC_API_KEY
- If you don't need AI-powered task management, ignore the warning
- setup-mcp.sh will proceed without it (ANTHROPIC_API_KEY is optional)
- To enable: Add `ANTHROPIC_API_KEY=sk-ant-...` to `.env.mcp.local` and re-run setup

### Adding New MCP Servers

1. Update `mcp/mcp.json.template` with new server config
2. If server requires secrets:
   - Add variable to `.env.mcp` template
   - Add actual value to `.env.mcp.local`
   - Use `${VARIABLE_NAME}` in `mcp/mcp.json.template`
3. Run `./scripts/setup-mcp.sh` to regenerate `~/.mcp.json`
4. Add MCP tools to relevant agents (update `.claude/agents/*.md`)
5. Restart Claude Code
6. Document in this file

### DO NOT:
- Commit `.env.mcp.local` (contains secrets)
- Hardcode API keys in `mcp/mcp.json.template`
- Edit `~/.mcp.json` directly (regenerate from template)
- Rely on manual copying for reproducibility

## Agent MCP Tool Permissions

### Overview
Agent files (`~/.claude/agents/*.md`) specify which MCP tools each agent can access via the `tools:` field in YAML frontmatter. This ensures agents only have access to tools relevant to their domain.

### Tool Allocation Strategy

**Standard Tools (All Agents):**
All agents have access to:
- File operations: `Grep`, `Glob`, `Read`, `Edit`, `MultiEdit`, `Write`, `NotebookEdit`
- Shell execution: `Bash` (Note: GitHub CLI `gh` should NOT be used - direct git commands preferred)
- Task tracking: `TodoWrite`
- Web operations: `WebFetch`, `WebSearch`
- MCP resources: `ListMcpResourcesTool`, `ReadMcpResourceTool`
- Background processes: `BashOutput`, `KillShell`

**MCP Tool Allocation by Agent:**

| Agent | MCP Tools | Rationale |
|-------|-----------|-----------|
| **React Engineer** | Playwright (puppeteer_*), Browser Tools (accessibility, performance audits), Serena | Browser automation for testing + semantic code analysis for React components |
| **Test Writer** | Playwright (puppeteer_*) | Writes E2E tests requiring browser automation |
| **Technical Architect** | Sequential Thinking, Serena, TaskMaster | Structured thinking + code intelligence + task management for complex planning |
| **Refactoring Specialist** | Sequential Thinking, Serena | Structured thinking + LSP-based code analysis for refactoring decisions |
| **Code Quality Enforcer** | Serena | Symbol-level code analysis for pattern detection and quality checks |
| **TypeScript Connoisseur** | Serena | LSP-based type analysis and symbol navigation for TypeScript |
| **Backend TypeScript Developer** | Serena | Semantic code analysis for backend implementation |
| **AWS CDK Expert** | Serena | Code intelligence for CDK infrastructure code |
| **Performance Specialist** | Browser Tools (performance audit, network/console logs) | Browser performance profiling tools |
| **All Other Agents** | Standard tools only | Domain-specific work doesn't require MCP extensions |

**Key Decisions:**
1. **Serena** (code intelligence) - Added to code-focused agents for LSP-based semantic analysis
2. **TaskMaster** (task management) - Added to Technical Architect for AI-powered task breakdown
3. **Context7** (documentation lookup) - Not yet configured with agents, pending API key setup
4. **AWS Tools** - Not yet added to agents, can be added when needed
5. **GitHub CLI Exclusion** - Per user preference, agents should use git commands directly, not `gh` CLI

### Adding New Tools to Agents

**Process:**
1. Identify which agents need the new MCP tool
2. Update agent frontmatter in `~/.claude/agents/<agent-name>.md`:
   ```yaml
   ---
   name: Agent Name
   description: Agent description
   tools: Grep, Glob, Read, Edit, ..., mcp__server-name__tool-name
   model: inherit
   color: color_name
   ---
   ```
3. Test that agent can access the tool
4. Document the change in this section

**Tool Discovery:**
Run `./scripts/list-mcp-tools.sh` to see available MCP tools from configured servers.

### Tool Naming Convention
MCP tools follow the pattern: `mcp__<server-name>__<tool-name>`

Examples:
- `mcp__puppeteer__puppeteer_navigate`
- `mcp__sequential-thinking__sequentialthinking`
- `mcp__browser-tools__runAccessibilityAudit`

## Future Improvements
- [ ] Add version pinning option (e.g., install specific Neovim version)
- [ ] Add automated testing for install scripts
- [ ] Consider using Neovim PPA for Ubuntu instead of AppImage
- [ ] Add rollback mechanism if installation fails
- [ ] Document all optional installation flags
- [ ] Consider migrating to Nerd Fonts for comprehensive icon support
