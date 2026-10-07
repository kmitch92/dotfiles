#!/usr/bin/env bash

# Tmux Session State Library
# Provides functions for capturing, saving, and restoring tmux session state.
# Safe to source (no side effects, no code that runs at source time).

# Default paths for save directory and overrides file.
# These may be overridden by pre-setting environment variables.
readonly TM_SAVE_DIR="${TM_SAVE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/tmsave}"
readonly TM_OVERRIDES="${TM_OVERRIDES:-$HOME/.config/tmux/tmux-overrides.json}"

# Optional internal tmux args for testing (e.g., "-L tmtest").
# Not intended for normal use, only when explicitly exported by test harness.
readonly TM_TMUX_ARGS="${TM_TMUX_ARGS:-}"

# ==============================================================================
# tm_resolve_cmd
# ==============================================================================
# Resolve a pane command using an overrides JSON file.
#
# Args:
#   $1 = saved_cmd (the command string to resolve)
#   $2 = overrides_path (path to JSON file with command mappings)
#
# Outputs:
#   Resolved command (or empty string if JSON value is null)
#
# Returns:
#   0 on success (including when file is missing/invalid)
#   1 only on genuine errors (not applicable here)
#
# Behavior:
#   - Empty saved_cmd: print nothing, return 0, do not read file
#   - Missing/invalid JSON: print saved_cmd unchanged, write warning to stderr
#   - Lookup priority: exact match > first-word match > no match (return unchanged)
#   - JSON null value: print nothing (run a plain shell)
#
tm_resolve_cmd() {
    local saved_cmd="$1"
    local overrides_path="$2"

    # Empty saved_cmd: return empty string without reading file.
    if [[ -z "$saved_cmd" ]]; then
        return 0
    fi

    # Try to read and parse the overrides file.
    if [[ ! -f "$overrides_path" ]]; then
        echo "$saved_cmd"
        echo "warning: overrides file not found: $overrides_path" >&2
        return 0
    fi

    # Parse JSON. We need to check both:
    # 1. Exact match on the full saved_cmd
    # 2. First-word match (first space-separated word)
    # jq -e 'has($k)' returns 0 if key exists, 1 if not.

    local resolved
    local first_word

    # Try exact match first.
    if resolved=$(jq -r --arg k "$saved_cmd" '.[$k]?' "$overrides_path" 2>/dev/null); then
        # jq succeeded. Now check if the key actually exists (not null vs missing).
        if jq -e --arg k "$saved_cmd" 'has($k)' "$overrides_path" >/dev/null 2>&1; then
            # Key exists. Check if it's null.
            if [[ "$resolved" == "null" ]]; then
                # Null value means run a plain shell (empty output).
                return 0
            else
                # Non-null value: print it.
                echo "$resolved"
                return 0
            fi
        fi
    else
        # jq failed (invalid JSON). Print warning and return input unchanged.
        echo "$saved_cmd"
        echo "warning: invalid JSON in overrides file: $overrides_path" >&2
        return 0
    fi

    # No exact match. Try first-word match.
    first_word="${saved_cmd%% *}"
    if [[ "$first_word" != "$saved_cmd" ]]; then
        # saved_cmd has whitespace, so first_word is different.
        if resolved=$(jq -r --arg k "$first_word" '.[$k]?' "$overrides_path" 2>/dev/null); then
            if jq -e --arg k "$first_word" 'has($k)' "$overrides_path" >/dev/null 2>&1; then
                # Key exists.
                if [[ "$resolved" == "null" ]]; then
                    return 0
                else
                    echo "$resolved"
                    return 0
                fi
            fi
        fi
    fi

    # No match: return input unchanged.
    echo "$saved_cmd"
    return 0
}

# ==============================================================================
# tm_unique_session_name
# ==============================================================================
# Find a unique session name by appending -2, -3, etc. if the base is taken.
#
# Args:
#   $1 = base (the desired session name)
#   $2, $3, ... = existing session names (to check against)
#
# Outputs:
#   The first available name (base, base-2, base-3, ...)
#
tm_unique_session_name() {
    local base="$1"
    shift
    local existing=("$@")
    local candidate="$base"
    local n=2

    # Check if candidate is in the existing list.
    while printf '%s\n' "${existing[@]}" | grep -q "^${candidate}$"; do
        candidate="${base}-${n}"
        n=$((n + 1))
    done

    echo "$candidate"
}

# ==============================================================================
# tm_describe_window
# ==============================================================================
# Generate a human-readable description of a window.
#
# Args:
#   $1 = window JSON object (as a string)
#
# Outputs:
#   "<name>  <n> panes  <first pane cwd>" (exactly two spaces between fields)
#
tm_describe_window() {
    local window_json="$1"

    local name
    local pane_count
    local first_pane_cwd

    name=$(jq -r '.name' <<< "$window_json")
    pane_count=$(jq '.panes | length' <<< "$window_json")
    first_pane_cwd=$(jq -r '.panes[0].cwd' <<< "$window_json")

    printf '%s  %d panes  %s\n' "$name" "$pane_count" "$first_pane_cwd"
}

# ==============================================================================
# tm_capture_session
# ==============================================================================
# Capture the complete state of a tmux session into JSON format.
#
# Args:
#   $1 = session name (optional; defaults to current or most-recently-attached)
#
# Outputs:
#   Complete JSON save file structure
#
# Returns:
#   0 on success
#   1 with a stderr message if no tmux server is running or session not found
#
tm_capture_session() {
    local session="${1:-}"

    # Resolve session name if not provided.
    if [[ -z "$session" ]]; then
        # If sandboxed (TM_TMUX_ARGS is set), always use the sandbox server's most-recently-attached session.
        # Otherwise, if inside tmux, use the current session.
        if [[ -n "$TM_TMUX_ARGS" ]]; then
            # Sandboxed: ignore $TMUX, query the sandbox server directly.
            if ! session=$(_tmux_cmd list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null | \
                           sort -rn | head -1 | cut -d' ' -f2-); then
                echo "Error: no tmux server is running" >&2
                return 1
            fi
            [[ -n "$session" ]] || {
                echo "Error: no tmux sessions found" >&2
                return 1
            }
        elif [[ -n "${TMUX:-}" ]]; then
            # Not sandboxed and inside tmux: use the current session.
            session="$(_tmux_cmd display-message -p '#{session_name}')"
        else
            # Not sandboxed and outside tmux: find the most-recently-attached session.
            # list-sessions fails if no server is running; that's fine.
            if ! session=$(_tmux_cmd list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null | \
                           sort -rn | head -1 | cut -d' ' -f2-); then
                echo "Error: no tmux server is running" >&2
                return 1
            fi
            [[ -n "$session" ]] || {
                echo "Error: no tmux sessions found" >&2
                return 1
            }
        fi
    fi

    # Build the JSON.
    local saved_at
    saved_at="$(date -Iseconds)"

    # Collect windows.
    local windows_json=""

    while IFS='|' read -r window_id window_name window_layout window_active; do
        [[ -n "$window_id" ]] || continue

        # Collect panes for this window.
        local panes_json=""

        while IFS='|' read -r pane_pid pane_cwd pane_active; do
            [[ -n "$pane_pid" ]] || continue

            # Get the running command: newest direct child of the pane shell.
            local pane_cmd
            pane_cmd=$(ps --ppid "$pane_pid" -o args= --sort=start_time 2>/dev/null | tail -1)
            [[ -n "$pane_cmd" ]] || pane_cmd=""

            # Build pane JSON.
            if [[ -n "$panes_json" ]]; then
                panes_json="${panes_json},"
            fi

            panes_json+=$(jq -n \
                --arg cwd "$pane_cwd" \
                --arg cmd "$pane_cmd" \
                --argjson active "$(if [[ $pane_active -eq 1 ]]; then echo "true"; else echo "false"; fi)" \
                '{cwd: $cwd, cmd: $cmd, active: $active}')

        done < <(_tmux_cmd list-panes -t "$window_id" \
                 -F '#{pane_pid}|#{pane_current_path}|#{pane_active}')

        # Build window JSON.
        if [[ -n "$windows_json" ]]; then
            windows_json="${windows_json},"
        fi

        windows_json+=$(jq -n \
            --arg name "$window_name" \
            --arg layout "$window_layout" \
            --argjson active "$(if [[ $window_active -eq 1 ]]; then echo "true"; else echo "false"; fi)" \
            --argjson panes "[$panes_json]" \
            '{name: $name, layout: $layout, active: $active, panes: $panes}')

    done < <(_tmux_cmd list-windows -t "$session" \
             -F '#{window_id}|#{window_name}|#{window_layout}|#{window_active}')

    # Build final JSON.
    jq -n \
        --arg saved_at "$saved_at" \
        --arg session "$session" \
        --argjson windows "[$windows_json]" \
        '{saved_at: $saved_at, session: $session, windows: $windows}'
}

# ==============================================================================
# tmux wrapper - convenience for using TM_TMUX_ARGS
# ==============================================================================
# Internal: wraps tmux with TM_TMUX_ARGS flags.
# When TM_TMUX_ARGS is non-empty, unsets $TMUX to prevent redirection to the live server.
_tmux_cmd() {
    if [[ -n "$TM_TMUX_ARGS" ]]; then
        # Sandboxed: unset TMUX to prevent using live server.
        # shellcheck disable=SC2086
        env -u TMUX tmux $TM_TMUX_ARGS "$@"
    else
        # Normal mode: use tmux with any inherited $TMUX.
        # shellcheck disable=SC2086
        command tmux "$@"
    fi
}
