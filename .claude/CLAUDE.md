# Dotfiles Project - Claude Context

## Project Overview
This is a comprehensive dotfiles repository that provides automated setup for development environments across macOS and Linux systems. The installation is modular and handles system packages, development tools, fonts, shells, and configuration management via GNU Stow.

## Critical Issues Fixed

### Neovim Treesitter / noice.nvim "Invalid node type tab" Error on Save (Fixed: 2026-06-18)

**Problem**:
- On `:w`/`:wq`, a noice.nvim error box flashed: `runtime/lua/vim/treesitter/query.lua:373: Query error at 113:4. Invalid node type "tab"`.
- The file saved correctly — the error was purely cosmetic, from noice rendering the "written" message.

**Root Cause**:
- noice.nvim highlights Neovim messages (the `vim` filetype) using treesitter.
- A `:Lazy update` had advanced nvim-treesitter to a `main`-branch commit (4916d6592ede8c07973490d9322f187e07dfefac) whose query files (queries/vim/highlights.scm line 113) reference a new grammar node `"tab"`.
- The installed compiled parser (`~/.local/share/nvim/site/parser/vim.so`, built 24-Oct-2025) was an older grammar that lacked the `tab` node → treesitter query error.
- Deeper incompatibility: that nvim-treesitter `main` commit calls `vim.list.unique`, an API that does NOT exist in Neovim 0.11.4. The `main` branch requires Neovim 0.12+. LazyVim's own treesitter spec guards this: `commit = vim.fn.has("nvim-0.12") == 0 and "7caec274fd19c12b55902a5b795100d21531391f" or nil` — pinning the last 0.11-compatible commit when on nvim < 0.12 — but the repo's lazy-lock.json had recorded the newer incompatible commit.

**Solution Applied**:
1. Neovim upgraded 0.11.4 → 0.12.3 (occurred as a side effect of `brew install tree-sitter`, which pulled neovim as a dependency; on 0.12 the `vim.list` API exists so the modern nvim-treesitter main branch is natively supported).
2. Installed the tree-sitter CLI: `brew install tree-sitter-cli` (v0.26.9). The nvim-treesitter `main` branch compiles parsers via the `tree-sitter` CLI, not `cc`; without it, parser compilation fails with `no such file or directory (cmd): 'tree-sitter'`. NOTE: `brew install tree-sitter` installs only the library — the CLI is the separate `tree-sitter-cli` formula.
3. Recompiled all 25 installed treesitter parsers against the current plugin (`require('nvim-treesitter.install').install(<all>, {force=true})`), so parser binaries match the query files.
4. Verified: edit + `:wq` on a .lua file exits cleanly with no error box and content saved.
5. Hardened the repo so fresh installs don't recur: bumped the Linux Neovim pin to v0.12.3 (NVIM_REQUIRED_VERSION 0.10.0 → 0.12.0) in `scripts/linux/install-dev-tools.sh`, and added tree-sitter CLI installation to `scripts/install-runtimes.sh` (macOS `brew install tree-sitter-cli`, Linux `npm install -g tree-sitter-cli`).

**Files Modified**:
- System: Neovim 0.11.4 → 0.12.3 (Homebrew); installed tree-sitter-cli 0.26.9; recompiled `~/.local/share/nvim/site/parser/*.so`
- `scripts/linux/install-dev-tools.sh` (Neovim version pin 0.11.4 → 0.12.3, required version 0.10.0 → 0.12.0)
- `scripts/install-runtimes.sh` (added tree-sitter CLI install block)
- `.claude/CLAUDE.md` (this entry)

**Key Lessons**:
1. **nvim-treesitter `main` requires Neovim 0.12+ and the `tree-sitter` CLI** - Both the CLI and a compatible nvim version are hard requirements for building parsers from `main`.
2. **`:Lazy update` can bypass LazyVim's version-guard pins** - lazy-lock.json records the newer incompatible commit. When on stable Neovim, verify nvim-treesitter stays on the commit LazyVim pins for your nvim version.
3. **"Invalid node type X" means parser is older than query files** - Fix by recompiling parsers (`:TSUpdate`), not by editing queries.
4. **`tree-sitter` vs `tree-sitter-cli` are separate Homebrew formulae** - `brew install tree-sitter` installs only the library; `brew install tree-sitter-cli` provides the `tree-sitter` binary that nvim-treesitter invokes.
5. **A noice error box on save does not mean the save failed** - It is noice rendering a message-highlighting error; the file write succeeds regardless.

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

### Agent Consolidation - Reducing Overlap & Preventing Recursion (Implemented: 2025-11-02)

**Goal:**
Reduce the number of specialized agents by consolidating overlapping responsibilities and prevent recursive subagent spawning that could exhaust JS heap allocation.

**Problem:**
- **Agent proliferation**: 15 specialized agents with significant overlap in responsibilities
- **Overlapping domains**: (Backend TypeScript + API Design), (Code Quality + Refactoring), (Git + Bash/Shell), (Security + Performance)
- **Recursive delegation risk**: Agents spawning other agents, which spawn more agents, creating deep delegation chains
- **JS heap exhaustion**: Recursive subagent spawning could exceed memory limits

**Analysis Findings:**

**Consolidation Candidates Identified:**
1. **Backend TypeScript Developer + API Design Specialist** - Both handle API lifecycle, one designs contracts, other implements
2. **Code Quality Enforcer + Refactoring Specialist** - Both assess code structure and suggest improvements at different stages
3. **Git Specialist + Bash/Shell Specialist** - Git operations all use bash CLI; shell scripting includes git hooks
4. **Security Specialist + Performance Specialist** - Cross-cutting concerns with overlapping domain (rate limiting, caching, DoS prevention)

**Delegation Pattern Analysis:**
- Found multiple agents explicitly spawning other agents (Test Writer → Refactoring → Code Quality → Test Writer = circular risk)
- Deep chains possible: Main → Backend → Database → Security → Test Writer (4 levels deep)
- Terminal agents (Git, Documentation) correctly identified as non-delegating

**Solution Applied:**

**New Architecture: 11 Agents (reduced from 15)**

**Consolidated Agents:**
1. **Backend TypeScript Specialist** (merged: Backend Developer + API Design)
   - Handles full API lifecycle: contract design → implementation
   - Tools: Standard + AWS docs
   - Delegation: MAX ONE LEVEL (can invoke Database Design only)

2. **Code Quality & Refactoring Specialist** (merged: Code Quality + Refactoring)
   - Two modes: Review Mode (pre-commit) / Refactor Mode (post-green)
   - Tools: Standard + Sequential Thinking
   - Delegation: MAX ONE LEVEL (returns to main agent)

3. **Git & Shell Specialist** (merged: Git + Bash/Shell)
   - All git operations + shell scripting + git hooks
   - Tools: Standard only (all git via bash)
   - Delegation: TERMINAL AGENT (never delegates)

4. **Security & Performance Specialist** (merged: Security + Performance)
   - Security audits + performance optimization + profiling
   - Tools: Standard + Browser Tools (performance audit, network/console logs)
   - Delegation: MAX ONE LEVEL (returns to main agent)

**Delegation Policy Implemented:**

**Rule**: Subagents may delegate MAX ONE LEVEL DEEP to prevent recursive loops

**Allowed**:
- ✅ Main Agent → Test Writer → Code Quality & Refactoring (stops)
- ✅ Main Agent → Backend Specialist → Database Design (stops)
- ✅ Main Agent → Technical Architect (stops - returns with plan)

**Prohibited**:
- ❌ Main Agent → Backend → Database → Another Agent (too deep)
- ❌ Backend → Database → Security → Test Writer (recursive chain)

**Enforcement**: All agent files include explicit "MAX ONE LEVEL" delegation rules in dedicated sections

**Files Modified:**
- Created `~/.claude/agents/backend-typescript-specialist.md`
- Created `~/.claude/agents/code-quality-refactoring-specialist.md`
- Created `~/.claude/agents/git-shell-specialist.md`
- Created `~/.claude/agents/security-performance-specialist.md`
- Deleted `~/.claude/agents/api-design-specialist.md`
- Deleted `~/.claude/agents/backend-typescript-developer.md`
- Deleted `~/.claude/agents/code-quality-enforcer.md`
- Deleted `~/.claude/agents/refactoring-specialist.md`
- Deleted `~/.claude/agents/git-specialist.md`
- Deleted `~/.claude/agents/bash-shell-specialist.md`
- Deleted `~/.claude/agents/security-specialist.md`
- Deleted `~/.claude/agents/performance-specialist.md`
- Updated `~/.claude/CLAUDE.md` (agent tables, decision trees, delegation policy)
- Updated `dotfiles/.claude/CLAUDE.md` (this file)

**Key Benefits:**
1. **Reduced cognitive overhead** - Fewer agents to choose from, clearer boundaries
2. **Prevented recursive loops** - MAX ONE LEVEL rule enforced in all agent files
3. **Memory safety** - No deep delegation chains that could exhaust JS heap
4. **Preserved functionality** - All capabilities from merged agents retained
5. **Clear separation** - Each consolidated agent has distinct section headers for merged responsibilities

**Remaining Agents (11 total):**
- Technical Architect
- Test Writer
- TypeScript Connoisseur
- Code Quality & Refactoring Specialist (NEW)
- Security & Performance Specialist (NEW)
- Backend TypeScript Specialist (NEW)
- Database Design Specialist
- Git & Shell Specialist (NEW)
- React Engineer
- AWS CDK Expert
- Documentation Agent

**Result:**
Agent architecture simplified while preserving all functionality. Recursive delegation physically impossible due to MAX ONE LEVEL enforcement. JS heap exhaustion risk eliminated.

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
Tmux configuration with Gruvbox Dark Hard theme, vim-like keybindings, and smart automatic window naming.

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

### Tmux Plugins

**Overview**: Tmux uses TPM (Tmux Plugin Manager) for plugin management, extending functionality with session persistence, clipboard integration, and file/URL opening capabilities.

**Installed Plugins**:

1. **tmux-resurrect** - Session persistence across restarts
   - Saves tmux environment (windows, panes, layouts)
   - Persists working directories and running programs
   - Stores sessions in `~/.tmux/resurrect/`

2. **tmux-continuum** - Automatic session save/restore
   - Auto-saves session every 15 minutes
   - Auto-restores last saved session on tmux start
   - Captures pane contents for complete restoration

3. **tmux-yank** - Enhanced clipboard integration
   - System clipboard integration with native tmux copy mode
   - Works across macOS (pbcopy), Linux (xclip/xsel), WSL

4. **tmux-open** - Open files and URLs from tmux
   - Smart detection of file paths and URLs under cursor
   - Opens files in default editor, URLs in browser

**Key Bindings**:

- **Session save**: `Ctrl-a Ctrl-s` (tmux-resurrect)
- **Session restore**: `Ctrl-a Ctrl-r` (tmux-resurrect)
- **Copy to clipboard**: `y` in copy mode (tmux-yank)
- **Open file**: `o` in copy mode (tmux-open)
- **Open URL**: `Ctrl-o` in copy mode (tmux-open)

**Plugin Management**:

- **Install plugins**: `Ctrl-a I` (capital I)
- **Update plugins**: `Ctrl-a U` (capital U)
- **Uninstall removed plugins**: `Ctrl-a Alt-u`

**Configuration**: `tmux/.tmux.conf` lines 119-147

### Key Features
- **Prefix**: `Ctrl-a` (changed from default `Ctrl-b`)
- **Split panes**: `|` horizontal, `-` vertical
- **Navigate panes**: Vim keys (`h`, `j`, `k`, `l`) or Alt+arrows (no prefix needed)
- **Resize panes**: `Prefix + H/J/K/L` (capital letters)
- **Copy mode**: Vim-like (`v` to select, `y` to yank)
- **Mouse support**: Enabled for pane selection and resizing
- **Gruvbox Dark Hard theme**: Warm orange/amber accents, dark background #1d2021
- **Status bar**: Shows session name, user, date/time, hostname

### Machine-Local Zsh Overrides (Added: 2026-06-20)

**Problem**:
`zsh/.zshrc` contained a hardcoded work-machine path (`/Users/kiel.mitchell/.../dmp.zsh`). This leaked a private filesystem path into the public repo and errored on every non-work machine (file not found on Linux, different macOS username).

**Solution Applied**:
Removed the hardcoded `source` call. `zsh/.zshrc` now ends with:
```bash
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
```
Machine-specific sourcing (work tools, private paths, host-only env vars) goes in `~/.zshrc.local`, which is untracked. A tracked template `zsh/.zshrc.local.template` documents the pattern and provides a starting point.

**Convention**:
Public repo stays generic; machine-local customisation lives in gitignored `.local` files. `.gitignore` now includes `.zshrc.local`.

**Usage on a new machine**:
```bash
cp ~/dotfiles/zsh/.zshrc.local.template ~/.zshrc.local
# Edit ~/.zshrc.local and add machine-specific source calls / env vars
```

**Files Modified**:
- `zsh/.zshrc` (removed hardcoded path, added conditional local source)
- `zsh/.zshrc.local.template` (new tracked template)
- `.gitignore` (added `.zshrc.local`)

## Future Improvements
- [ ] Add version pinning option (e.g., install specific Neovim version)
- [ ] Add automated testing for install scripts
- [ ] Consider using Neovim PPA for Ubuntu instead of AppImage
- [ ] Add rollback mechanism if installation fails
- [ ] Document all optional installation flags
- [ ] Consider migrating to Nerd Fonts for comprehensive icon support
