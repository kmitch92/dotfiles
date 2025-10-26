#!/bin/bash

# =============================================================================
# Utility Functions
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC}  $1"; }
print_info() { echo -e "${BLUE}ℹ${NC}  $1"; }
print_step() { echo -e "${CYAN}▶${NC} ${BOLD}$1${NC}"; }

print_header() {
    echo ""
    echo "=================================="
    echo "$1"
    echo "=================================="
}

is_macos() { [[ "$OSTYPE" == "darwin"* ]]; }
is_linux() { [[ "$OSTYPE" == "linux-gnu"* ]]; }

detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"

    # If AUTO_CONFIRM is set, automatically return yes
    if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
        if [[ "$default" == "y" ]]; then
            echo "$prompt [Y/n] y (auto)"
        else
            echo "$prompt [y/N] y (auto)"
        fi
        return 0
    fi

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi

    read -p "$prompt" -n 1 -r
    echo

    if [[ "$default" == "y" ]]; then
        [[ $REPLY =~ ^[Nn]$ ]] && return 1 || return 0
    else
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

command_exists() { command -v "$1" &> /dev/null; }

install_linux_package() {
    local package="$1"
    local distro=$(detect_linux_distro)
    
    case $distro in
        ubuntu|debian|pop)
            sudo apt update && sudo apt install -y "$package"
            ;;
        fedora|rhel|centos)
            sudo dnf install -y "$package"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm "$package"
            ;;
        *)
            print_error "Unsupported distribution: $distro"
            return 1
            ;;
    esac
}

create_backup_dir() {
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

run_step() {
    local step_name="$1"
    local script_name="$2"
    local required="${3:-optional}"
    
    echo "" | tee -a "$INSTALL_LOG"
    print_step "$step_name" | tee -a "$INSTALL_LOG"
    
    if [[ "$required" == "optional" ]] && ! $SKIP_OPTIONAL; then
        if ! confirm "Install $step_name?"; then
            print_warning "Skipping $step_name" | tee -a "$INSTALL_LOG"
            INSTALL_STATUS["$step_name"]="skipped"
            return 0
        fi
    fi
    
    if source "$SCRIPTS_DIR/$script_name" 2>&1 | tee -a "$INSTALL_LOG"; then
        INSTALL_STATUS["$step_name"]="completed"
        print_success "$step_name completed" | tee -a "$INSTALL_LOG"
    else
        INSTALL_STATUS["$step_name"]="failed"
        print_error "$step_name failed" | tee -a "$INSTALL_LOG"
        
        if [[ "$required" == "required" ]]; then
            print_error "Required step failed. Exiting." | tee -a "$INSTALL_LOG"
            exit 1
        else
            print_warning "Optional step failed. Continuing..." | tee -a "$INSTALL_LOG"
        fi
    fi
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_LOG"; }

export -f print_success print_error print_warning print_info print_step print_header
export -f is_macos is_linux detect_linux_distro confirm command_exists
export -f install_linux_package create_backup_dir log
