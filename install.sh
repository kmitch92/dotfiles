#!/bin/bash

# =============================================================================
# Dotfiles Installation Script (Package-based Structure)
# =============================================================================
# This script uses GNU Stow with a package-based organization where each
# subdirectory represents a package/application to be stowed separately.
#
# Usage: ./install.sh
# =============================================================================

# Get the directory where this script is located (works in both bash and zsh)
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create a timestamped backup directory for any existing files
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "=================================="
echo "Dotfiles Installation"
echo "=================================="
echo "Source: $DOTFILES_DIR"
echo "Target: $HOME"
echo ""

# =============================================================================
# Check for Homebrew (macOS/Linux)
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
        echo "⚠️  Homebrew is not installed."
        echo "Install it from: https://brew.sh"
        echo ""
        read -p "Would you like to install Homebrew now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Set up Homebrew in current session
            if [[ -d "/opt/homebrew/bin" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -d "/usr/local/bin" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            echo "❌ Homebrew is required. Exiting."
            exit 1
        fi
    else
        # Ensure Homebrew is in PATH for this script
        if [[ -d "/opt/homebrew/bin" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -d "/usr/local/bin" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

# =============================================================================
# Check for GNU Stow
# =============================================================================
echo "Checking dependencies..."
echo ""

if ! command -v stow &> /dev/null; then
    echo "⚠️  GNU Stow is not installed."
    echo "Stow is required to create symlinks for your dotfiles."
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        read -p "Would you like to install stow via Homebrew? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install stow
        else
            echo "❌ Stow is required. Exiting."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi
        
        read -p "Would you like to install stow now? (requires sudo) (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            case $DISTRO in
                ubuntu|debian|pop)
                    sudo apt update && sudo apt install -y stow
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y stow
                    ;;
                arch|manjaro)
                    sudo pacman -S --noconfirm stow
                    ;;
                *)
                    echo "Unsupported distribution. Please install stow manually:"
                    echo "  Ubuntu/Debian: sudo apt install stow"
                    echo "  Fedora: sudo dnf install stow"
                    echo "  Arch: sudo pacman -S stow"
                    exit 1
                    ;;
            esac
        else
            echo "❌ Stow is required. Exiting."
            exit 1
        fi
    fi
else
    echo "✓ GNU Stow found: $(which stow)"
fi

# =============================================================================
# Check for optional but recommended tools
# =============================================================================
echo ""
echo "Checking optional dependencies..."
echo ""

MISSING_TOOLS=()

# Check for JetBrains Mono font
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! brew list --cask font-jetbrains-mono &> /dev/null; then
        MISSING_TOOLS+=("font-jetbrains-mono")
        echo "⚠️  JetBrains Mono font not installed"
    else
        echo "✓ JetBrains Mono font installed"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Check if font is installed on Linux
    if ! fc-list | grep -qi "JetBrains Mono"; then
        MISSING_TOOLS+=("font-jetbrains-mono")
        echo "⚠️  JetBrains Mono font not installed"
    else
        echo "✓ JetBrains Mono font installed"
    fi
fi

# Check for tmux
if ! command -v tmux &> /dev/null; then
    MISSING_TOOLS+=("tmux")
    echo "⚠️  tmux not installed (recommended for status bar)"
else
    echo "✓ tmux found: $(which tmux)"
fi

# Check for starship
if ! command -v starship &> /dev/null; then
    MISSING_TOOLS+=("starship")
    echo "⚠️  starship not installed (recommended for enhanced prompt)"
else
    echo "✓ starship found: $(which starship)"
fi

# Check for Neovim
if ! command -v nvim &> /dev/null; then
    MISSING_TOOLS+=("neovim")
    echo "⚠️  Neovim not installed (required for LazyVim config)"
else
    echo "✓ Neovim found: $(which nvim)"
fi

# Check for Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "⚠️  Oh My Zsh not installed (provides zsh plugins and features)"
    OMZ_MISSING=true
else
    echo "✓ Oh My Zsh installed"
    OMZ_MISSING=false
fi

# Offer to install missing tools
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    echo "The following optional tools are recommended:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        read -p "Would you like to install these now via Homebrew? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
        for tool in "${MISSING_TOOLS[@]}"; do
        if [[ $tool == font-* ]]; then
        echo "Installing $tool..."
        brew install --cask "$tool"
        elif [[ $tool == "neovim" ]]; then
        echo "Installing Neovim..."
        brew install neovim
            echo "✓ Installed Neovim"
            else
                    echo "Installing $tool..."
                brew install "$tool"
            fi
        done
    fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        read -p "Would you like to install these now? (requires sudo) (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO=$ID
            fi
            
            for tool in "${MISSING_TOOLS[@]}"; do
                case $tool in
                    font-jetbrains-mono)
                        echo "Installing JetBrains Mono font..."
                        # Download and install font
                        FONT_DIR="$HOME/.local/share/fonts"
                        mkdir -p "$FONT_DIR"
                        cd /tmp
                        wget -q https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip
                        unzip -q JetBrainsMono-2.304.zip -d JetBrainsMono
                        cp JetBrainsMono/fonts/ttf/*.ttf "$FONT_DIR/"
                        fc-cache -f
                        rm -rf JetBrainsMono JetBrainsMono-2.304.zip
                        cd - > /dev/null
                        echo "✓ Installed JetBrains Mono font"
                        ;;
                    tmux)
                        echo "Installing tmux..."
                        case $DISTRO in
                            ubuntu|debian|pop)
                                sudo apt install -y tmux
                                ;;
                            fedora|rhel|centos)
                                sudo dnf install -y tmux
                                ;;
                            arch|manjaro)
                                sudo pacman -S --noconfirm tmux
                                ;;
                        esac
                        echo "✓ Installed tmux"
                        ;;
                    starship)
                        echo "Installing starship..."
                        curl -sS https://starship.rs/install.sh | sh -s -- -y
                        echo "✓ Installed starship"
                        ;;
                    neovim)
                        echo "Installing Neovim..."
                        case $DISTRO in
                            ubuntu|debian|pop)
                                sudo apt install -y neovim
                                ;;
                            fedora|rhel|centos)
                                sudo dnf install -y neovim
                                ;;
                            arch|manjaro)
                                sudo pacman -S --noconfirm neovim
                                ;;
                        esac
                        echo "✓ Installed Neovim"
                        ;;
                esac
            done
        fi
    fi
fi

# Install Oh My Zsh if missing
if [[ "$OMZ_MISSING" == true ]]; then
    echo ""
    read -p "Would you like to install Oh My Zsh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo "✓ Oh My Zsh installed"
        
        # Install custom plugins
        echo ""
        echo "Installing Oh My Zsh custom plugins..."
        
        # zsh-autosuggestions
        if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
            echo "✓ Installed zsh-autosuggestions"
        fi
        
        # zsh-syntax-highlighting
        if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
            echo "✓ Installed zsh-syntax-highlighting"
        fi
        
        # you-should-use
        if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/you-should-use" ]]; then
            git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ~/.oh-my-zsh/custom/plugins/you-should-use
            echo "✓ Installed you-should-use"
        fi
        
        # zsh-bat (only if bat is installed)
        if command -v bat &> /dev/null; then
            if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-bat" ]]; then
                git clone https://github.com/fdellwing/zsh-bat.git ~/.oh-my-zsh/custom/plugins/zsh-bat
                echo "✓ Installed zsh-bat"
            fi
        else
            echo "⚠️  Skipping zsh-bat (bat not installed. Install with: brew install bat)"
        fi
        
        echo "✓ All custom plugins installed"
    fi
else
    # Oh My Zsh exists, check for missing custom plugins
    echo ""
    echo "Checking Oh My Zsh custom plugins..."
    MISSING_PLUGINS=()
    
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        MISSING_PLUGINS+=("zsh-autosuggestions")
    fi
    
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
        MISSING_PLUGINS+=("zsh-syntax-highlighting")
    fi
    
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/you-should-use" ]]; then
        MISSING_PLUGINS+=("you-should-use")
    fi
    
    if command -v bat &> /dev/null && [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-bat" ]]; then
        MISSING_PLUGINS+=("zsh-bat")
    fi
    
    if [ ${#MISSING_PLUGINS[@]} -gt 0 ]; then
        echo "Missing plugins: ${MISSING_PLUGINS[*]}"
        read -p "Would you like to install missing Oh My Zsh plugins? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for plugin in "${MISSING_PLUGINS[@]}"; do
                case $plugin in
                    zsh-autosuggestions)
                        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
                        ;;
                    zsh-syntax-highlighting)
                        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
                        ;;
                    you-should-use)
                        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ~/.oh-my-zsh/custom/plugins/you-should-use
                        ;;
                    zsh-bat)
                        git clone https://github.com/fdellwing/zsh-bat.git ~/.oh-my-zsh/custom/plugins/zsh-bat
                        ;;
                esac
                echo "✓ Installed $plugin"
            done
        fi
    else
        echo "✓ All required plugins are installed"
    fi
fi

echo ""
echo "=================================="
echo "Installing Dotfiles"
echo "=================================="

# Change to the dotfiles directory so stow operates from here
cd "$DOTFILES_DIR"

# Create the backup directory
mkdir -p "$BACKUP_DIR"
echo "Backup directory created: $BACKUP_DIR"

# =============================================================================
# Define packages to stow
# =============================================================================
# List all subdirectories that contain dotfiles to be stowed
# Exclude: .git, and any directories starting with .
PACKAGES=()
for dir in */; do
    # Remove trailing slash
    package="${dir%/}"
    
    # Skip hidden directories and specific exclusions
    if [[ "$package" != .* ]]; then
        PACKAGES+=("$package")
    fi
done

echo ""
echo "Found packages: ${PACKAGES[*]}"

# =============================================================================
# Process each package
# =============================================================================
for package in "${PACKAGES[@]}"; do
    echo ""
    echo "Processing package: $package"
    echo "---"
    
    # Enable dotglob to match hidden files
    shopt -s dotglob nullglob
    
    # Find all top-level items in the package (files and directories)
    # These are what stow will try to create symlinks for
    for item in "$package"/*; do
        if [[ -e "$item" ]]; then
            # Get just the name (e.g., .zshrc, .claude, .config)
            item_name=$(basename "$item")
            target="$HOME/$item_name"
            
            echo "  Checking: $item_name (target: $target)"
            
            # Check if target exists (whether symlink or real file)
            if [[ -e "$target" || -L "$target" ]]; then
                if [[ -L "$target" ]]; then
                    echo "  Removing existing symlink: $item_name"
                else
                    echo "  Backing up: $item_name"
                    # Copy the existing file/directory to backup
                    cp -r "$target" "$BACKUP_DIR/"
                fi
                # Remove the existing file/directory/symlink so stow can create a fresh symlink
                rm -rf "$target"
                echo "  Removed: $target"
            else
                echo "  Does not exist, will create new"
            fi
        fi
    done
    
    # Disable dotglob
    shopt -u dotglob nullglob
    
    # Run stow for this package
    stow "$package"
    
    if [[ $? -eq 0 ]]; then
        echo "  ✓ Stowed: $package"
    else
        echo "  ✗ Error stowing: $package"
    fi
done

# =============================================================================
# Clean up old backup directories
# =============================================================================
echo ""
echo "Cleaning up old backup directories..."

# Find all backup directories except the one we just created
OLD_BACKUPS=$(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" | grep -v "$BACKUP_DIR" | sort)

if [[ -n "$OLD_BACKUPS" ]]; then
    echo "$OLD_BACKUPS" | while read -r old_backup; do
        echo "  Removing: $(basename "$old_backup")"
        rm -rf "$old_backup"
    done
    echo "✓ Old backups cleaned up"
else
    echo "  No old backups found"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=================================="
echo "Installation Complete!"
echo "=================================="
echo "Packages installed: ${PACKAGES[*]}"
echo "Current backup: $(basename "$BACKUP_DIR")"
echo ""
echo "Next steps:"
echo "  1. Restart your shell: exec zsh"
echo ""
if command -v tmux &> /dev/null; then
    echo "  2. Try tmux for status bar: tmux"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  2. Install tmux for status bar: brew install tmux"
    else
        echo "  2. Install tmux: sudo apt install tmux (or your package manager)"
    fi
fi
echo ""
if command -v starship &> /dev/null; then
    echo "  3. Starship prompt is enabled (restart shell to see it)"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  3. Install starship for enhanced prompt: brew install starship"
    else
        echo "  3. Install starship: curl -sS https://starship.rs/install.sh | sh"
    fi
fi
echo ""
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "  4. Oh My Zsh plugins are enabled"
else
    echo "  4. Install Oh My Zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi
echo ""
echo "Terminal configs available for:"
echo "  - Ghostty, Alacritty, Kitty, WezTerm, iTerm2"
echo "  - See ~/.config/TERMINAL_README.md for details"
echo "  - See ~/.config/STATUS_BAR_README.md for status bar info"
echo ""
