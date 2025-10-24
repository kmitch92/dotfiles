# iTerm2 Configuration Instructions

iTerm2 stores its configuration in `~/Library/Preferences/com.googlecode.iterm2.plist`, which is managed by macOS and not ideal for dotfiles.

## Recommended Approach: Dynamic Profiles

Create a dynamic profile that iTerm2 will automatically load:

1. Create the directory (if it doesn't exist):
   ```bash
   mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
   ```

2. Save the profile (copy the JSON from the file below to the DynamicProfiles folder)

3. Open iTerm2 → Preferences → Profiles
4. Select "Default" profile
5. Choose "Other Actions" → "Set as Default"

## Manual Configuration (Alternative)

If you prefer to configure manually:

### Theme: Catppuccin Mocha
1. Download from: https://github.com/catppuccin/iterm
2. Open iTerm2 → Preferences → Profiles → Colors
3. Import the downloaded color preset

### Font
- **Font**: JetBrains Mono
- **Size**: 13pt
- Location: Preferences → Profiles → Text

### Window
- **Transparency**: 5% (Preferences → Profiles → Window)
- **Blur**: 20 (Preferences → Profiles → Window)
- **Columns**: 120, Rows: 35

### General Settings
- Preferences → General → Selection → "Copy to clipboard on selection"
- Preferences → General → Window → Uncheck "Native full screen windows"
- Preferences → Profiles → Terminal → Scrollback lines: 10000
- Preferences → Profiles → Keys → Left Option Key: Esc+
- Preferences → Profiles → Keys → Right Option Key: Esc+

### Status Bar Setup
1. Preferences → Profiles → Session
2. Check "Status bar enabled"
3. Click "Configure Status Bar" button
4. Drag these components to the status bar:
   - **Current Directory** (left side)
   - **git state** (left side)
   - **CPU Utilization** (right side)
   - **Memory Utilization** (right side)
   - **Network Throughput** (right side)
   - **Battery Level** (right side)
   - **Clock** (right side)
5. Click "Auto-Rainbow" for nice colors
6. Set Status Bar Position: Bottom

### Keyboard Shortcuts
- CMD+D: Split pane horizontally
- CMD+Shift+D: Split pane vertically
- CMD+W: Close pane/tab
- CMD+T: New tab
- CMD+[: Previous tab
- CMD+]: Next tab
