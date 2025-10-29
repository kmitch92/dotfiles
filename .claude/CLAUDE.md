# Dotfiles Project - Claude Context

## Project Overview
This is a comprehensive dotfiles repository that provides automated setup for development environments across macOS and Linux systems. The installation is modular and handles system packages, development tools, fonts, shells, and configuration management via GNU Stow.

## Critical Issues Fixed

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
- **Serena** - Semantic code retrieval and editing toolkit

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
CONTEXT7_API_KEY=your_api_key_here
```

**`.env.mcp.local`** - Actual secrets (gitignored, user creates):
```bash
CONTEXT7_API_KEY=ctx7sk-actual-key-here
```

**`scripts/setup-mcp.sh`** - Substitutes env vars from `.env.mcp.local` into template and deploys to `~/.mcp.json`
  - Removes symlinks if present (file must be generated, not symlinked)
  - Validates required runtime tools (npx, uvx)
  - **Note**: `mcp/` directory is excluded from GNU Stow to prevent symlink conflicts

### Setup Process

**First Time Setup:**
```bash
cd ~/dotfiles
./install.sh  # Creates .env.mcp.local from template if missing
# Edit .env.mcp.local with your actual API keys
./scripts/setup-mcp.sh
```

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

### Troubleshooting

**MCP servers not loading:**
1. Check `~/.mcp.json` exists and is valid JSON
2. Verify no `${VAR}` patterns remain (means env var not substituted)
3. Check Claude Code logs: `~/.claude/logs/`
4. Restart Claude Code
5. Try: `claude --mcp-debug` for detailed logging

**Environment variable not substituted:**
1. Check `.env.mcp.local` exists and has correct syntax
2. Verify `envsubst` is installed (setup-mcp.sh will try to install)
3. Re-run `./scripts/setup-mcp.sh`

**AWS servers failing:**
1. Ensure `aws-core` server loads first (it's a dependency)
2. Check AWS CLI is configured: `aws sts get-caller-identity`
3. Verify AWS_REGION is set correctly in `mcp/.mcp.json`

### Adding New MCP Servers

1. Update `mcp/.mcp.json` with new server config
2. If server requires secrets:
   - Add variable to `.env.mcp` template
   - Add actual value to `.env.mcp.local`
   - Use `${VARIABLE_NAME}` in `mcp/.mcp.json`
3. Run `./scripts/setup-mcp.sh` to regenerate
4. Restart Claude Code
5. Document in this file

### DO NOT:
- Commit `.env.mcp.local` (contains secrets)
- Hardcode API keys in `mcp/.mcp.json`
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
| **React Engineer** | Playwright (puppeteer_*), Browser Tools (accessibility, performance audits) | Needs browser automation for testing React components, responsive design verification, and accessibility checks |
| **Test Writer** | Playwright (puppeteer_*) | Writes E2E tests requiring browser automation |
| **Technical Architect** | Sequential Thinking | Complex task decomposition benefits from structured problem-solving |
| **Refactoring Specialist** | Sequential Thinking | Complex refactoring planning requires structured thinking |
| **Performance Specialist** | Browser Tools (performance audit, network/console logs) | Needs browser performance profiling tools |
| **All Other Agents** | Standard tools only | Domain-specific work doesn't require MCP extensions |

**Key Decisions:**
1. **Context7** (documentation lookup) - Not yet configured with agents, pending API key setup
2. **AWS Tools** - Not yet added to agents, can be added when needed
3. **Serena** (code intelligence) - Not yet added to agents, can be added when needed
4. **GitHub CLI Exclusion** - Per user preference, agents should use git commands directly, not `gh` CLI

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
