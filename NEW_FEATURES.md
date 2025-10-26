# New Features Added

## 1. Non-Interactive Installation Mode

You can now run the installation script without any prompts using the `--yes` or `-y` flag.

### Usage

```bash
# Interactive mode (asks for confirmation)
./install.sh

# Non-interactive mode (auto-confirms everything)
./install.sh --yes
# or
./install.sh -y

# Combine with skip-optional for fast minimal install
./install.sh --yes --skip-optional
```

### Perfect For:
- **CI/CD pipelines** - Automated deployments
- **Docker containers** - Building images
- **Remote provisioning** - Setting up multiple machines
- **Scripts** - Bootstrapping new systems

### How It Works
- The `AUTO_CONFIRM` environment variable is exported from `install.sh`
- The `confirm()` function in `utils.sh` checks this variable
- When set to `true`, all prompts automatically return "yes"
- Visual feedback shows `(auto)` next to confirmations

### Example Output
```
Install Neovim? [y/N] y (auto)
Install tmux? [y/N] y (auto)
Install starship? [y/N] y (auto)
```

## 2. tmux Auto-Start

Your shell now automatically starts tmux by default!

### Behavior

When you open a new terminal:
1. **If tmux is installed** → Automatically attaches to `default` session (or creates it)
2. **If already in tmux** → Does nothing (no nesting)
3. **If in IDE terminal** → Skips auto-start (VS Code, etc. detected)
4. **If disabled** → Respects `DISABLE_AUTO_TMUX` variable

### Smart Detection

Auto-start is **skipped** in these cases:
- Already inside a tmux session
- VS Code integrated terminal
- JetBrains IDE terminal
- Non-interactive shells (scripts)
- When `DISABLE_AUTO_TMUX=true`

### Disabling tmux Auto-Start

#### Temporary (one session)
```bash
export DISABLE_AUTO_TMUX=true
exec zsh
```

#### Permanent (all sessions)
Add to your `~/.zshrc` or `~/.zshenv`:
```bash
echo 'export DISABLE_AUTO_TMUX=true' >> ~/.zshrc
```

Or edit the dotfiles and remove/comment the auto-start section:
```bash
# Edit ~/dotfiles/zsh/.zshrc
# Comment out or remove the "tmux Auto-Start" section
```

### Why Auto-Start tmux?

**Benefits:**
- ✅ Never lose your work (sessions persist)
- ✅ Detach/attach from anywhere
- ✅ Multiple windows in one terminal
- ✅ Consistent environment across SSH sessions
- ✅ Split panes for productivity

**Session Management:**
```bash
# Detach from session (keeps it running)
Ctrl-b d

# List sessions
tmux ls

# Attach to specific session
tmux attach -t session-name

# Create new named session
tmux new -s my-project

# Kill session
tmux kill-session -t session-name
```

### Customization

The auto-start configuration is in `~/dotfiles/zsh/.zshrc`:

```bash
# ============================================================================
# tmux Auto-Start
# ============================================================================
if command -v tmux &> /dev/null; then
    if [[ -z "$TMUX" ]] && \
       [[ "${DISABLE_AUTO_TMUX:-false}" != "true" ]] && \
       [[ $- == *i* ]] && \
       [[ -z "$VSCODE_INJECTION" ]] && \
       [[ -z "$TERM_PROGRAM" ]]; then
        tmux attach-session -t default || tmux new-session -s default
    fi
fi
```

You can customize:
- Session name (change `default` to your preferred name)
- Add additional conditions
- Run commands before/after tmux starts

## 3. Enhanced Help System

The install script now has a help flag:

```bash
./install.sh --help
# or
./install.sh -h
```

Output:
```
Usage: ./install.sh [OPTIONS]

Options:
  --skip-optional    Skip all optional installations
  --yes, -y          Automatically answer yes to all prompts
  --help, -h         Show this help message
```

## Implementation Details

### Files Modified

1. **install.sh**
   - Added argument parsing loop
   - Added `--yes/-y` flag support
   - Added `--help/-h` flag
   - Export `AUTO_CONFIRM` environment variable

2. **scripts/utils.sh**
   - Updated `confirm()` function
   - Check `AUTO_CONFIRM` variable
   - Return early with visual feedback when auto-confirming

3. **zsh/.zshrc**
   - Added tmux auto-start section
   - Smart detection of tmux/IDE/environment
   - Attach to existing or create new session

4. **README.md**
   - Documented all new flags
   - Added tmux auto-start instructions
   - Added disable instructions

## Testing

### Test --yes Flag
```bash
# Should complete without any prompts
./install.sh --yes --skip-optional
```

### Test tmux Auto-Start
```bash
# Should automatically enter tmux
exec zsh

# Should not nest tmux
# (already in tmux, so no second tmux starts)
```

### Test Disable tmux
```bash
export DISABLE_AUTO_TMUX=true
exec zsh
# Should NOT start tmux
```

## Future Enhancements

Potential additions:
- [ ] `--dry-run` flag to show what would be installed
- [ ] `--verbose` flag for detailed output
- [ ] `--config <file>` to specify custom configuration
- [ ] Auto-save/restore tmux sessions with tmux-resurrect
- [ ] Conditional tmux auto-start based on hostname/environment

## Backwards Compatibility

All changes are **fully backwards compatible**:
- Default behavior unchanged (interactive prompts)
- Old scripts still work exactly as before
- New flags are optional
- tmux auto-start can be disabled
