#!/bin/bash

# iTerm2 Dynamic Profile Setup Script
# This script copies the iTerm2 dynamic profile to the correct location

ITERM_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
SOURCE_PROFILE="$HOME/.config/iterm2/DynamicProfile.json"

echo "Setting up iTerm2 Dynamic Profile..."
echo ""

# Check if iTerm2 is installed
if ! command -v iTerm2 &> /dev/null && ! [ -d "/Applications/iTerm.app" ]; then
    echo "⚠️  iTerm2 doesn't appear to be installed."
    echo "Install it with: brew install --cask iterm2"
    echo ""
    exit 1
fi

# Create the DynamicProfiles directory if it doesn't exist
if [ ! -d "$ITERM_PROFILES_DIR" ]; then
    echo "Creating DynamicProfiles directory..."
    mkdir -p "$ITERM_PROFILES_DIR"
fi

# Check if source profile exists
if [ ! -f "$SOURCE_PROFILE" ]; then
    echo "❌ Source profile not found at: $SOURCE_PROFILE"
    echo "Make sure your dotfiles are properly installed."
    exit 1
fi

# Copy the profile
echo "Copying dynamic profile..."
cp "$SOURCE_PROFILE" "$ITERM_PROFILES_DIR/catppuccin-mocha.json"

if [ $? -eq 0 ]; then
    echo "✅ Dynamic profile installed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Restart iTerm2 (Cmd+Q and reopen)"
    echo "2. Open Preferences (Cmd+,)"
    echo "3. Go to Profiles"
    echo "4. Select 'Default (Catppuccin Mocha)'"
    echo "5. Click 'Other Actions' → 'Set as Default'"
    echo ""
else
    echo "❌ Failed to copy dynamic profile"
    exit 1
fi
