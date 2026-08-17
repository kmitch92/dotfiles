#!/usr/bin/env bash

# Tmux Work Layout
# Builds a 3-pane development layout rooted at a target directory:
#
#   ┌──────────┬──────────┐
#   │ lazygit  │          │
#   ├──────────┤  claude  │
#   │ terminal │          │
#   └──────────┴──────────┘
#
# Usage: tmux-work-session.sh [directory]   (defaults to $PWD)
# Invoked by the work() shell function in zsh/.zshrc

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# Custom window option used as the reuse marker.
# Window *names* cannot be used for this: .tmux.conf sets automatic-rename on
# with an automatic-rename-format, so tmux rewrites window names continuously.
# Window *indices* are no good either - renumber-windows is on.
readonly WORK_DIR_OPTION="@work_dir"

# Right column (claude) share of the window width - two even columns.
readonly CLAUDE_WIDTH="50%"
# Bottom-left (plain shell) share of the left column height; the top-left
# (lazygit) pane keeps the remaining ~67%.
readonly SHELL_HEIGHT="33%"

# Tools auto-launched into their panes. Missing tools degrade to a plain shell.
readonly GIT_UI_CMD="lazygit"
readonly AGENT_CMD="claude"

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

log_warn() {
    echo "WARN: $*" >&2
    # Also surface it in tmux, where stderr is swallowed by the attach.
    if [[ -n "${TMUX:-}" ]]; then
        tmux display-message "$SCRIPT_NAME: $*" 2>/dev/null || true
    fi
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

require_tmux() {
    command -v tmux >/dev/null 2>&1 || die "tmux is not installed"
}

# Resolve to a physical, absolute path so the reuse marker compares reliably.
canonical_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || die "not a directory: $dir"
    (cd "$dir" && pwd -P)
}

# Deterministic session name from the invocation directory, so sessions created
# outside tmux are identifiable instead of being auto-numbered 0, 1, 2...
# tmux session names may not contain '.' or ':'; spaces are replaced for sanity.
session_name_for() {
    local name
    name="$(basename "$1")"
    name="${name//[.:]/_}"
    name="${name// /_}"
    [[ -n "$name" ]] || name="work"
    printf '%s\n' "$name"
}

# Avoid colliding with an unrelated pre-existing session of the same name.
unique_session_name() {
    local base="$1"
    local candidate="$1"
    local n=2

    # '=' forces an exact name match rather than tmux's prefix matching.
    while tmux has-session -t "=$candidate" 2>/dev/null; do
        candidate="${base}-${n}"
        n=$((n + 1))
    done

    printf '%s\n' "$candidate"
}

# Print the window id of an existing work window for $1, across ALL sessions
# (attached or detached). Returns 1 when there is no match.
find_work_window() {
    local dir="$1"
    local wid marker

    # window_id ("@N") never contains a space, so the rest of the line is the
    # marker value - which means directory paths with spaces survive intact.
    while read -r wid marker; do
        [[ -n "$wid" ]] || continue
        if [[ "$marker" == "$dir" ]]; then
            printf '%s\n' "$wid"
            return 0
        fi
    done < <(tmux list-windows -a -F "#{window_id} #{${WORK_DIR_OPTION}}" 2>/dev/null || true)

    return 1
}

# Bring an existing work window to the foreground.
focus_work_window() {
    local wid="$1"
    local session_id

    session_id="$(tmux display-message -p -t "$wid" '#{session_id}')"

    # Make it the current window within its own session first.
    tmux select-window -t "$wid"

    if [[ -n "${TMUX:-}" ]]; then
        # Inside tmux: only needed when the match lives in another session.
        # Tolerate failure - there is no client to switch when the script is
        # driven non-interactively.
        tmux switch-client -t "$session_id" 2>/dev/null || true
    else
        # Outside tmux: the match may be a detached session from an earlier run.
        tmux attach-session -t "$session_id"
    fi
}

# Start a tool in a pane.
launch_in_pane() {
    local pane_id="$1"
    local cmd="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_warn "$cmd not found on PATH - leaving that pane as a plain shell"
        return 0
    fi

    # send-keys, deliberately NOT `split-window "$cmd"`: this runs the tool
    # inside the pane's shell, so quitting lazygit or claude drops back to a
    # live shell instead of killing the pane.
    tmux send-keys -t "$pane_id" "$cmd" C-m
}

# -----------------------------------------------------------------------------
# Layout
# -----------------------------------------------------------------------------

# Build the 3-pane layout in an existing single-pane window.
# $1 = directory, $2 = window id, $3 = pane id of that window's only pane.
# Every operation targets a pane/window ID: index arithmetic is fragile here
# because pane-base-index is 1 and renumber-windows is on.
build_layout() {
    local dir="$1"
    local wid="$2"
    local pane_git="$3"
    local pane_agent

    # Right column: claude.
    pane_agent="$(tmux split-window -h -l "$CLAUDE_WIDTH" -t "$pane_git" -c "$dir" \
        -P -F '#{pane_id}')"

    # Left column: new bottom pane is the plain interactive shell, leaving ~67%
    # above it for lazygit. No pane id needed - nothing is sent to this pane.
    tmux split-window -v -l "$SHELL_HEIGHT" -t "$pane_git" -c "$dir"

    # Reuse marker (see WORK_DIR_OPTION).
    tmux set-option -w -t "$wid" "$WORK_DIR_OPTION" "$dir"

    launch_in_pane "$pane_git" "$GIT_UI_CMD"
    launch_in_pane "$pane_agent" "$AGENT_CMD"

    # Explicit final focus: the claude pane.
    tmux select-pane -t "$pane_agent"
}

# Already inside tmux: add a new window to the CURRENT session, rooted at $dir.
# Never splits the current window and never creates a session.
create_work_window() {
    local dir="$1"
    local target out pane_id wid

    # Resolve the invoking window explicitly, via $TMUX_PANE where available.
    # Relying on tmux's implicit "current" target would pick the server's
    # most-recently-used session, which is not necessarily the session the user
    # is sitting in. new-window -t needs a target *window*: passing a pane id
    # fails with "can't specify pane here", hence the pane -> window lookup.
    if [[ -n "${TMUX_PANE:-}" ]]; then
        target="$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')"
    else
        target="$(tmux display-message -p '#{window_id}')"
    fi

    # -a places the new window immediately after the current one.
    out="$(tmux new-window -a -t "$target" -c "$dir" -P -F '#{pane_id} #{window_id}')"
    pane_id="${out%% *}"
    wid="${out##* }"

    build_layout "$dir" "$wid" "$pane_id"
    tmux select-window -t "$wid"
}

# Not inside tmux (the normal case on Linux, where terminals do not auto-start
# tmux): create a named session rooted at $dir, build the layout while it is
# still detached, then attach once. Building after attaching flickers and can
# race with the client.
create_work_session() {
    local dir="$1"
    local name out pane_id wid

    name="$(unique_session_name "$(session_name_for "$dir")")"

    out="$(tmux new-session -d -s "$name" -c "$dir" -P -F '#{pane_id} #{window_id}')"
    pane_id="${out%% *}"
    wid="${out##* }"

    build_layout "$dir" "$wid" "$pane_id"

    tmux attach-session -t "=$name"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    require_tmux

    local dir existing
    dir="$(canonical_dir "${1:-$PWD}")"

    # Idempotent re-run: reuse the work window for this directory if one exists,
    # in this session or any other.
    if existing="$(find_work_window "$dir")"; then
        focus_work_window "$existing"
        return 0
    fi

    if [[ -n "${TMUX:-}" ]]; then
        create_work_window "$dir"
    else
        create_work_session "$dir"
    fi
}

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------

main "$@"
