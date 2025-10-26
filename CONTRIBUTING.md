# Contributing to Dotfiles

This guide explains how to extend and maintain this dotfiles system.

## Design Principles

### 1. User Control
**Always ask permission** before making system changes:
- Use `confirm()` prompts for installations
- Explain what the tool does and why it's useful
- Default to "no" for optional installations
- Make everything skippable

### 2. Idempotency
**Scripts should be safe to run multiple times:**
- Check if tool exists before installing
- Handle "already installed" cases gracefully
- Don't fail if nothing needs to be done
- Offer updates for existing installations

### 3. Clear Communication
**Users should always know what's happening:**
- Use colored output (success, error, warning, info)
- Print step names with `print_step()`
- Show version numbers when available
- Explain errors clearly

### 4. Graceful Degradation
**Failures shouldn't break the whole installation:**
- Mark steps as "required" or "optional"
- Optional steps can fail without stopping
- Log all failures for later review
- Provide recovery suggestions

### 5. Cross-Platform Support
**Support both macOS and Linux:**
- Use `is_macos()` and `is_linux()` checks
- Use appropriate package managers
- Handle Linux distro differences
- Clearly state if tool is OS-specific

## Script Structure

### Standard Script Template

Every installation script should follow this pattern:
```bash
#!/bin/bash

# =============================================================================
# Tool Name Installation
# =============================================================================
# Brief description of what this installs and why

print_header "Installing Tool Name"

# =============================================================================
# Check if already installed
# =============================================================================

if command_exists toolname; then
    VERSION=$(toolname --version 2>&1 | head -n1)
    print_success "Tool Name already installed: $VERSION"
    
    # Optional: Offer update
    if confirm "Update Tool Name?"; then
        print_info "Updating Tool Name..."
        # Update logic here
        print_success "Tool Name updated"
    fi
    
    return 0
fi

# =============================================================================
# Installation prompt
# =============================================================================

print_warning "Tool Name not installed"
print_info "Tool Name provides: [key features]"
print_info "Useful for: [use cases]"
echo ""

if ! confirm "Install Tool Name?"; then
    print_warning "Skipping Tool Name"
    return 0
fi

# =============================================================================
# Installation
# =============================================================================

print_info "Installing Tool Name..."

if is_macos; then
    # macOS installation
    brew install toolname
    
elif is_linux; then
    # Linux installation
    DISTRO=$(detect_linux_distro)
    
    case $DISTRO in
        ubuntu|debian|pop)
            install_linux_package toolname
            ;;
        fedora|rhel|centos)
            sudo dnf install -y toolname
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm toolname
            ;;
        *)
            print_error "Unsupported distribution"
            return 1
            ;;
    esac
fi

# =============================================================================
# Verification
# =============================================================================

if command_exists toolname; then
    print_success "Tool Name installed successfully"
else
    print_error "Tool Name installation failed"
    return 1
fi

# =============================================================================
# Post-installation (optional)
# =============================================================================

if confirm "Run Tool Name post-install configuration?"; then
    print_info "Configuring Tool Name..."
    # Configuration steps here
    print_success "Tool Name configured"
fi

echo ""
print_success "Tool Name setup complete"
```

## Code Style

### Bash Best Practices
```bash
# Use bash strict mode in main scripts
set -e  # Exit on error
set -u  # Error on undefined variables
set -o pipefail  # Catch errors in pipes

# Use local variables in functions
function my_function() {
    local var_name="value"
}

# Quote variables to handle spaces
rm -rf "$HOME/.config/app"

# Use [[ ]] for conditionals (not [ ])
if [[ "$VAR" == "value" ]]; then
    echo "Match"
fi

# Check command exit codes
if command_exists tool; then
    # Tool exists
fi

# Use arrays for lists
TOOLS=("tool1" "tool2" "tool3")
for tool in "${TOOLS[@]}"; do
    echo "$tool"
done
```

### Function Naming
```bash
# Use snake_case for functions
install_my_tool() { }

# Use clear, descriptive names
check_prerequisites() { }
configure_shell() { }
backup_existing_files() { }
```

### Comments
```bash
# Use section headers for organization
# =============================================================================
# Section Name
# =============================================================================

# Explain complex logic
# This loop handles both .zsh and .bash files
for file in ~/.{zsh,bash}*; do
    # Process file
done

# Document why, not what (code shows what)
# Bad:  # Loop through files
# Good: # Check each config file for deprecated settings
```

## Testing

### Manual Testing

Before committing changes:
```bash
# Test on clean VM or container
docker run -it ubuntu:latest /bin/bash

# Clone your branch
git clone -b your-branch https://github.com/user/dotfiles.git
cd dotfiles

# Run installer
./install.sh

# Test each component works
tool --version
```

### Test Checklist

- [ ] Script runs without errors
- [ ] Handles "already installed" case
- [ ] Prompts user appropriately
- [ ] Works on macOS (if applicable)
- [ ] Works on Linux (if applicable)
- [ ] Logs actions properly
- [ ] Updates installation summary
- [ ] Doesn't break when run multiple times
- [ ] Cleans up after itself
- [ ] Provides helpful error messages

## Adding New Components

### 1. Create the Script
```bash
# Create new script
touch scripts/install-newtool.sh
chmod +x scripts/install-newtool.sh

# Use the template above
# Fill in all sections appropriately
```

### 2. Add to Main Installer

Edit `install.sh`:
```bash
# Step N: Install NewTool
if ! $SKIP_OPTIONAL; then
    run_step "NewTool" "install-newtool.sh" "optional"
fi
```

### 3. Test Thoroughly
```bash
# Test the script individually
source scripts/utils.sh
source scripts/install-newtool.sh

# Test full installation
./install.sh

# Test with skip flag
./install.sh --skip-optional

# Test "already installed" path
./install.sh  # Run again
```

### 4. Update Documentation

Add to `README.md`:
```markdown
### NewTool
- **Description** - What it does
- **Why it's included** - Use cases
- **Optional/Required** - Installation status
```

### 5. Create Stow Package (if needed)
```bash
# Create package directory
mkdir -p newtool/.config/newtool

# Add config files
touch newtool/.config/newtool/config.yml

# Stow will automatically discover it
```

## Common Patterns

### Installing with Different Package Managers
```bash
if is_macos; then
    brew install toolname
elif is_linux; then
    case $(detect_linux_distro) in
        ubuntu|debian|pop)
            sudo apt install -y toolname
            ;;
        fedora|rhel|centos)
            sudo dnf install -y toolname
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm toolname
            ;;
    esac
fi
```

### Installing from Source
```bash
print_info "Installing from source..."
cd /tmp
git clone https://github.com/user/tool.git
cd tool
./configure
make
sudo make install
cd - > /dev/null
rm -rf /tmp/tool
```

### Installing with Custom Installer
```bash
print_info "Running installer script..."
curl -fsSL https://get.tool.sh | bash
```

### Checking Multiple Commands
```bash
if command_exists tool1 && command_exists tool2; then
    print_success "All requirements satisfied"
else
    print_error "Missing required tools"
    return 1
fi
```

### Installing Plugins/Extensions
```bash
PLUGIN_DIR="$HOME/.tool/plugins"
PLUGINS=(
    "plugin1:https://github.com/user/plugin1.git"
    "plugin2:https://github.com/user/plugin2.git"
)

for plugin_def in "${PLUGINS[@]}"; do
    IFS=':' read -r name url <<< "$plugin_def"
    
    if [[ ! -d "$PLUGIN_DIR/$name" ]]; then
        print_info "Installing $name..."
        git clone "$url" "$PLUGIN_DIR/$name"
        print_success "Installed $name"
    else
        print_success "$name already installed"
    fi
done
```

## Debugging

### Enable Debug Output
```bash
# Add to script for debugging
set -x  # Print commands as they execute

# Or run with debug flag
bash -x scripts/install-tool.sh
```

### Common Issues

**Script exits early:**
- Check for `set -e` - it exits on first error
- Use `|| true` for commands that can safely fail
- Check return codes explicitly

**Variables not expanding:**
- Ensure variables are quoted: `"$VAR"`
- Check if variable is in scope
- Use `echo` to debug variable values

**Function not found:**
- Source `utils.sh` first
- Check function is exported
- Verify function name spelling

## Commit Guidelines

### Commit Message Format
```
type(scope): brief description

Longer explanation if needed.

- Bullet points for details
- Multiple changes listed
```

**Types:**
- `feat`: New feature/tool
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code restructuring
- `test`: Testing improvements
- `chore`: Maintenance tasks

**Examples:**
```
feat(docker): add Docker Desktop installation for Linux

Adds support for Docker Desktop on Linux systems.
Includes post-install configuration and health checks.

fix(zsh): handle missing Oh My Zsh gracefully

Previously failed if Oh My Zsh wasn't installed.
Now skips plugin installation and continues.

docs(readme): add troubleshooting section

Added common issues and solutions for:
- Docker permission errors
- Zsh not default shell
- Stow conflicts
```

## Getting Help

- Check the README for documentation
- Look at existing scripts for examples
- Check `.install.log` for detailed error output
- Test changes in a VM or container first

## Questions?

Open an issue or discussion in the repository to ask questions or propose changes.
