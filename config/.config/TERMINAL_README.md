# Terminal Emulator Configurations

This directory contains configuration files for multiple modern terminal emulators. All configs use:

- **Theme**: Catppuccin Mocha (dark theme with excellent contrast)
- **Font**: JetBrains Mono at 13pt
- **Opacity**: 95% with background blur
- **Scrollback**: 10,000 lines
- **Features**: Ligatures disabled, cursor blinking, clipboard integration

## Available Configurations

### 1. **Ghostty** (Recommended for macOS)
- **Config**: `.config/ghostty/config`
- **Website**: https://ghostty.org
- **Install**: `brew install ghostty`
- Modern, GPU-accelerated, native macOS feel

### 2. **Alacritty**
- **Config**: `.config/alacritty/alacritty.toml`
- **Website**: https://alacritty.org
- **Install**: `brew install --cask alacritty`
- Cross-platform, extremely fast, minimal features

### 3. **Kitty**
- **Config**: `.config/kitty/kitty.conf`
- **Website**: https://sw.kovidgoyal.net/kitty/
- **Install**: `brew install --cask kitty`
- Feature-rich, excellent image support, ligatures

### 4. **WezTerm**
- **Config**: `.config/wezterm/wezterm.lua`
- **Website**: https://wezfurlong.org/wezterm/
- **Install**: `brew install --cask wezterm`
- Lua configured, multiplexing, cross-platform

### 5. **iTerm2**
- **Config**: `.config/iterm2/` (see README)
- **Website**: https://iterm2.com
- **Install**: `brew install --cask iterm2`
- macOS classic, feature-complete, tmux integration

## Quick Start

1. Install your preferred terminal emulator (see install commands above)
2. Run the dotfiles install script: `./install.sh`
3. Restart your terminal
4. The configuration should be automatically loaded

## Font Installation

All configs use **JetBrains Mono**. Install it with:

```bash
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono
```

Alternative fonts that work well:
- **Fira Code**: `brew install --cask font-fira-code`
- **Cascadia Code**: `brew install --cask font-cascadia-code`
- **Hack**: `brew install --cask font-hack`
- **Iosevka**: `brew install --cask font-iosevka`

## Customization

### Status Bars
See **STATUS_BAR_README.md** for detailed information about status bar options:
- **WezTerm**: Built-in status bar (already configured)
- **iTerm2**: Built-in status bar (manual setup required)
- **Others**: Use Tmux or Starship prompt

### Changing Colors
All terminals use Catppuccin Mocha. To use a different theme:
- **Catppuccin Latte** (light): https://github.com/catppuccin/catppuccin
- **Nord**: https://www.nordtheme.com
- **Dracula**: https://draculatheme.com
- **Tokyo Night**: https://github.com/tokyo-night/tokyo-night-vscode-theme

### Enabling Ligatures
If you want programming ligatures (like `=>` becoming →):
- **Ghostty**: Remove the `font-feature = -calt` line
- **Alacritty**: Remove the `disable_ligatures` setting
- **Kitty**: Change `disable_ligatures always` to `disable_ligatures never`
- **WezTerm**: Remove the `harfbuzz_features` line

### Adjusting Opacity
Look for these settings in each config:
- **Ghostty**: `background-opacity`
- **Alacritty**: `[window] opacity`
- **Kitty**: `background_opacity`
- **WezTerm**: `window_background_opacity`
- **iTerm2**: Profiles → Window → Transparency

## Comparison

| Terminal | Speed | Features | GPU | Ligatures | Images | Multiplexing |
|----------|-------|----------|-----|-----------|--------|--------------|
| Ghostty  | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | ✅ | ✅ | ❌ |
| Alacritty| ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ❌ | ❌ | ❌ |
| Kitty    | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ | ✅ | ✅ |
| WezTerm  | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | ✅ | ✅ | ✅ |
| iTerm2   | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | ✅ | ✅ | ✅ |

## Troubleshooting

### Colors look wrong
Run: `echo $TERM` - should show `xterm-256color` or similar

### Font not found
Install JetBrains Mono: `brew install --cask font-jetbrains-mono`

### Config not loading
- Check the config file path matches what the terminal expects
- Run the terminal from command line to see error messages
- Verify the dotfiles install script created the symlinks correctly

### iTerm2 not using the profile
- Copy `DynamicProfile.json` to `~/Library/Application Support/iTerm2/DynamicProfiles/`
- Restart iTerm2
- Select the profile in Preferences → Profiles
