# Status Bar Configurations

Different terminal emulators have different approaches to status bars. Here's what's available for each:

## 📊 Built-in Status Bars

### **WezTerm** ✅ (Fully Configured)
**Status**: Already configured in `~/.config/wezterm/wezterm.lua`

Shows on the right side of the tab bar:
- Current working directory
- Battery status with icon
- Current date
- Current time

No additional setup needed - just use WezTerm!

### **iTerm2** ✅ (Manual Setup Required)
**Status**: Instructions in `~/.config/iterm2/README.md`

To enable:
1. Open iTerm2 Preferences (Cmd+,)
2. Profiles → Session
3. Enable "Status bar enabled"
4. Click "Configure Status Bar"
5. Add components: Directory, Git, CPU, Memory, Network, Battery, Clock

## 🔧 Alternative Solutions

### **Option 1: Tmux** (Recommended for Ghostty, Alacritty, Kitty)
**Status**: Configured in `~/.tmux.conf`

Tmux provides a persistent status bar at the bottom showing:
- Session name and user
- Window list
- Hostname, date, and time

**Setup:**
```bash
# Install tmux
brew install tmux

# Install the config (run install.sh if you haven't)
cd ~/dotfiles
./install.sh

# Start tmux
tmux

# Or create a new named session
tmux new -s mysession
```

**Useful tmux commands:**
- `Ctrl-a d` - Detach from session
- `tmux attach` - Reattach to session
- `Ctrl-a c` - Create new window
- `Ctrl-a |` - Split pane vertically
- `Ctrl-a -` - Split pane horizontally
- `Ctrl-a h/j/k/l` - Navigate panes (vim style)

### **Option 2: Starship Prompt** (Works with ALL terminals)
**Status**: Configured in `~/.config/starship.toml`

Starship provides a beautiful, informative command prompt with:
- Git branch and status
- Current directory
- Programming language versions (Node, Python, Rust, Go, etc.)
- Command duration
- Time and battery on the right side

**Setup:**
```bash
# Install starship
brew install starship

# Already enabled in .zshrc if installed
# Just restart your shell
exec zsh
```

The prompt automatically shows:
- Git status when in a git repo
- Language versions when project files are detected (package.json, etc.)
- AWS/Docker/Kubernetes context when relevant
- Error indicators when commands fail

## 📋 Comparison

| Terminal   | Built-in Status Bar | Tmux Compatible | Starship Compatible |
|------------|---------------------|-----------------|---------------------|
| WezTerm    | ✅ (configured)     | ✅              | ✅                  |
| iTerm2     | ✅ (manual setup)   | ✅              | ✅                  |
| Ghostty    | ❌                  | ✅              | ✅                  |
| Alacritty  | ❌                  | ✅              | ✅                  |
| Kitty      | ❌                  | ✅              | ✅                  |

## 🎯 Recommended Setup by Terminal

**WezTerm:**
- Use built-in status bar (already configured)
- Optionally add Starship for enhanced prompt

**iTerm2:**
- Enable built-in status bar (follow manual setup)
- Optionally add Starship for enhanced prompt

**Ghostty/Alacritty/Kitty:**
- Use **Tmux** for persistent status bar and window management
- OR use **Starship** for enhanced prompt with status info
- OR use both together!

## 🚀 Quick Start

### Just want a nice prompt? Use Starship:
```bash
brew install starship
exec zsh  # Restart shell
```

### Want a persistent status bar with window management? Use tmux:
```bash
brew install tmux
cd ~/dotfiles && ./install.sh
tmux
```

### Want both? Install both!
```bash
brew install starship tmux
cd ~/dotfiles && ./install.sh
exec zsh
tmux
```

## 🎨 Customization

All configs use the Catppuccin Mocha theme to match your terminal colors.

### Starship
Edit `~/.config/starship.toml` to:
- Add/remove modules
- Change colors
- Adjust format
- See all options: https://starship.rs/config/

### Tmux
Edit `~/.tmux.conf` to:
- Customize status bar content
- Change keybindings (currently uses Ctrl-a as prefix)
- Modify colors
- Add plugins via TPM (instructions in file)

## 💡 Tips

**Starship + Tmux together:**
When using both, Starship provides context-aware info at the prompt level, while tmux provides persistent system info at the bottom. They complement each other perfectly!

**Performance:**
Starship is extremely fast (written in Rust). Tmux has minimal overhead. Both are suitable for daily use.

**Portability:**
Both Starship and tmux configs are in your dotfiles, so your setup follows you to any machine!
