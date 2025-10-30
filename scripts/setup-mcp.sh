#!/bin/bash

# =============================================================================
# MCP Server Configuration Setup
# =============================================================================
# Substitutes environment variables from .env.mcp.local into .mcp.json template
# and deploys to home directory
#
# Usage: ./scripts/setup-mcp.sh
# =============================================================================

set -e

# Get the directory where this script's parent (dotfiles) is located
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Source utilities
source "$DOTFILES_DIR/scripts/utils.sh"

print_header "Setting up MCP Server Configuration"

# =============================================================================
# Validate runtime tool dependencies
# =============================================================================

print_info "Checking for required runtime tools..."

# Track missing tools
MISSING_TOOLS=()

# Check for npx (Node.js/npm)
if ! command -v npx &> /dev/null; then
    MISSING_TOOLS+=("npx (Node.js/npm)")
fi

# Check for uvx (Python/uv)
if ! command -v uvx &> /dev/null; then
    MISSING_TOOLS+=("uvx (Python/uv)")
fi

# If tools are missing, provide guidance and exit
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error "Missing required runtime tools:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  ✗ $tool"
    done
    echo ""
    print_info "MCP servers require these runtime tools:"
    echo "  - npx: Required for context7, sequential-thinking, playwright servers"
    echo "  - uvx: Required for serena, aws-core, aws-cdk servers"
    echo ""
    print_info "To install missing tools, run these installation steps:"
    if [[ " ${MISSING_TOOLS[@]} " =~ "npx" ]]; then
        echo "  • Node.js/npm: ./install.sh (Step 4: Development Runtimes)"
    fi
    if [[ " ${MISSING_TOOLS[@]} " =~ "uvx" ]]; then
        echo "  • Python/uv: ./install.sh (Step 4: Development Runtimes)"
    fi
    echo ""
    exit 1
fi

print_success "All required runtime tools found"

# =============================================================================
# Check for .env.mcp.local
# =============================================================================

if [ ! -f "$DOTFILES_DIR/.env.mcp.local" ]; then
    print_warning ".env.mcp.local not found"
    print_info "Creating from template..."
    
    cp "$DOTFILES_DIR/.env.mcp" "$DOTFILES_DIR/.env.mcp.local"
    
    print_warning "Please edit .env.mcp.local with your actual API keys:"
    print_info "  1. Open: $DOTFILES_DIR/.env.mcp.local"
    print_info "  2. Replace placeholder values with real API keys"
    print_info "  3. Run this script again: ./scripts/setup-mcp.sh"
    echo ""
    exit 1
fi

# =============================================================================
# Source environment variables
# =============================================================================

print_info "Loading environment variables from .env.mcp.local..."
set -a  # Automatically export all variables
source "$DOTFILES_DIR/.env.mcp.local"
set +a  # Disable automatic export

# Validate required environment variables
MISSING_KEYS=()

# Required keys
if [ "$CONTEXT7_API_KEY" = "your_api_key_here" ] || [ -z "$CONTEXT7_API_KEY" ]; then
    MISSING_KEYS+=("CONTEXT7_API_KEY")
fi

# Optional keys (warn but don't fail)
if [ "$ANTHROPIC_API_KEY" = "your_anthropic_api_key_here" ] || [ -z "$ANTHROPIC_API_KEY" ]; then
    print_warning "ANTHROPIC_API_KEY not configured - taskmaster server will not be available"
    print_info "To enable taskmaster later: Add ANTHROPIC_API_KEY to .env.mcp.local and re-run setup-mcp.sh"
    # Set empty value so envsubst doesn't fail
    export ANTHROPIC_API_KEY=""
fi

# Only fail if required keys are missing
if [ ${#MISSING_KEYS[@]} -gt 0 ]; then
    print_error "Missing or invalid API keys in .env.mcp.local:"
    for key in "${MISSING_KEYS[@]}"; do
        echo "  ✗ $key"
    done
    echo ""
    print_info "Please edit $DOTFILES_DIR/.env.mcp.local and set your API keys"
    print_info "  • CONTEXT7_API_KEY: https://console.upstash.com"
    exit 1
fi

# =============================================================================
# Generate .mcp.json from template
# =============================================================================

print_info "Generating ~/.mcp.json from template..."

# Remove existing symlink if present (should be a generated file, not a symlink)
if [ -L "$HOME/.mcp.json" ]; then
    print_warning "Found symlink at ~/.mcp.json, removing..."
    rm "$HOME/.mcp.json"
    print_info "Symlink removed (will generate proper file)"
fi

# Check if envsubst is available
if ! command -v envsubst &> /dev/null; then
    print_warning "envsubst not found, attempting to install gettext..."
    
    if is_macos; then
        brew install gettext
        # Add gettext to PATH for this session
        export PATH="/usr/local/opt/gettext/bin:$PATH"
    elif is_linux; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y gettext-base
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y gettext
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm gettext
        else
            print_error "Could not install gettext. Please install it manually."
            exit 1
        fi
    fi
fi

# Substitute environment variables in template
envsubst < "$DOTFILES_DIR/mcp/mcp.json.template" > "$HOME/.mcp.json"

print_success "MCP configuration deployed to ~/.mcp.json"

# =============================================================================
# Verify configuration
# =============================================================================

print_info "Verifying configuration..."

if [ -f "$HOME/.mcp.json" ]; then
    # Check that env vars were substituted (no ${VAR} patterns remaining)
    if grep -q '${' "$HOME/.mcp.json"; then
        print_warning "Some environment variables may not have been substituted"
        print_info "Please check $HOME/.mcp.json for any remaining \${VAR} patterns"
    else
        print_success "All environment variables substituted successfully"
    fi
    
    # Show configured servers
    echo ""
    print_info "Configured MCP servers:"
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[]' "$HOME/.mcp.json" | while read server; do
            echo "  - $server"
        done
    else
        grep '"' "$HOME/.mcp.json" | grep ':' | head -10 | sed 's/.*"\(.*\)".*/  - \1/'
    fi
else
    print_error "Failed to create ~/.mcp.json"
    exit 1
fi

# =============================================================================
# Next steps
# =============================================================================

echo ""
print_success "MCP setup complete!"
print_info "Next steps:"
print_info "  1. Restart Claude Code to load new MCP servers"
print_info "  2. Verify with: /mcp command in Claude Code"
print_info "  3. Check logs if servers don't load: ~/.claude/logs/"
echo ""
