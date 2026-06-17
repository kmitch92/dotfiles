#!/usr/bin/env bash

# Tmux Window Clone Script
# Clones the current tmux window including all panes and their working directories.
# Usage: Run via tmux keybinding (Prefix + C) or directly: ./tmux-clone-window.sh

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

log_error() {
    tmux display-message "ERROR: $*"
}

log_info() {
    tmux display-message "$*"
}

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

cleanup() {
    # Nothing to clean up for this script
    :
}

trap cleanup EXIT ERR

# -----------------------------------------------------------------------------
# Main Functions
# -----------------------------------------------------------------------------

# Get the current window's layout string
get_window_layout() {
    tmux list-windows -F "#{window_layout}" -f "#{==:#{window_active},1}"
}

# Get working directories for all panes in current window (one per line)
get_pane_directories() {
    tmux list-panes -F "#{pane_current_path}"
}

# Count panes in current window
count_panes() {
    tmux list-panes | wc -l | tr -d ' '
}

# Create a new window and return its index
create_new_window() {
    # Create new window, it will be selected automatically
    # Use the first pane's directory as the starting directory
    local first_dir="$1"
    tmux new-window -c "$first_dir"
}

# Split the current window to create additional panes
# We need (n-1) splits to get n panes
create_panes() {
    local pane_count="$1"
    local -a directories=("${@:2}")

    # We already have 1 pane from new-window, create (n-1) more
    local splits_needed=$((pane_count - 1))

    for ((i = 1; i <= splits_needed; i++)); do
        # Split the first pane horizontally (we'll fix layout later)
        # Use the corresponding directory for each new pane
        local dir="${directories[$i]}"
        tmux split-window -h -c "$dir"
    done
}

# Apply a saved layout to the current window
apply_layout() {
    local layout="$1"
    tmux select-layout "$layout"
}

# Send cd commands to each pane to ensure correct directories
# This handles cases where the pane shell might have cd'd elsewhere
sync_pane_directories() {
    local -a directories=("$@")
    local pane_count="${#directories[@]}"

    for ((i = 0; i < pane_count; i++)); do
        local dir="${directories[$i]}"
        # Select pane (0-indexed) and send cd command
        tmux select-pane -t "$i"
        # Clear any partial input and change directory
        tmux send-keys "C-c" "C-u"
        tmux send-keys "cd '$dir'" Enter
        # Clear the screen for cleaner appearance
        tmux send-keys "clear" Enter
    done

    # Return to the first pane
    tmux select-pane -t 0
}

# Main function
main() {
    # Capture current window state BEFORE creating new window
    local original_layout
    original_layout="$(get_window_layout)"

    # Get pane directories as array
    local -a pane_dirs
    mapfile -t pane_dirs < <(get_pane_directories)

    local pane_count="${#pane_dirs[@]}"

    # Validate we have at least one pane
    if [[ "$pane_count" -eq 0 ]]; then
        log_error "No panes found in current window"
        exit 1
    fi

    # Edge case: single pane window
    if [[ "$pane_count" -eq 1 ]]; then
        # Simple case: just create a new window with the same directory
        create_new_window "${pane_dirs[0]}"
        log_info "Window cloned (1 pane)"
        exit 0
    fi

    # Multi-pane window: full clone process

    # Step 1: Create new window starting with first pane's directory
    create_new_window "${pane_dirs[0]}"

    # Step 2: Create additional panes (n-1 splits for n panes)
    create_panes "$pane_count" "${pane_dirs[@]}"

    # Step 3: Apply the original layout
    apply_layout "$original_layout"

    # Step 4: Sync directories in each pane
    # (The -c flag should handle this, but this ensures correctness)
    sync_pane_directories "${pane_dirs[@]}"

    log_info "Window cloned ($pane_count panes)"
}

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------

main "$@"
