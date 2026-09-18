#!/usr/bin/env bash
set -uo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

passed=0
failed=0

# Assertion helper: compares expected vs actual and counts results
assert_eq() {
    local expected="$1"
    local actual="$2"
    local label="$3"

    if [[ "$expected" == "$actual" ]]; then
        ((passed++))
        echo "✓ $label"
    else
        ((failed++))
        echo "✗ $label"
        echo "  expected: '$expected'"
        echo "  actual:   '$actual'"
    fi
}

# Source the library (this will fail because it doesn't exist yet)
source /home/kiel/dotfiles/config/.config/tmux/scripts/tmux-state-lib.sh || {
    echo "Error: Could not source tmux-state-lib.sh" >&2
    exit 1
}

# Test 1: tm_resolve_cmd

# Create fixture overrides file
cat > "$tmpdir/overrides.json" <<'EOF'
{"claude": "claude --continue", "btop": null, "docker compose up": "docker compose up -d"}
EOF

# Test exact match (exact beats first-word)
result=$(tm_resolve_cmd "docker compose up" "$tmpdir/overrides.json")
assert_eq "docker compose up -d" "$result" "tm_resolve_cmd: exact match beats first-word"

# Test exact match on single word
result=$(tm_resolve_cmd "claude" "$tmpdir/overrides.json")
assert_eq "claude --continue" "$result" "tm_resolve_cmd: exact match on single word"

# Test first-word match with additional args
result=$(tm_resolve_cmd "claude --resume abc" "$tmpdir/overrides.json")
assert_eq "claude --continue" "$result" "tm_resolve_cmd: first-word match with args"

# Test no match - return unchanged
result=$(tm_resolve_cmd "lazygit" "$tmpdir/overrides.json")
assert_eq "lazygit" "$result" "tm_resolve_cmd: no match returns input unchanged"

# Test null value - return empty string
result=$(tm_resolve_cmd "btop" "$tmpdir/overrides.json")
assert_eq "" "$result" "tm_resolve_cmd: null value returns empty string"

# Test empty saved_cmd - return empty string without lookup
result=$(tm_resolve_cmd "" "$tmpdir/overrides.json")
assert_eq "" "$result" "tm_resolve_cmd: empty input returns empty string"

# Test nonexistent file - return input unchanged, stderr non-empty
stderr_out=$(tm_resolve_cmd "lazygit" "$tmpdir/nonexistent.json" 2>&1 >/dev/null || true)
result=$(tm_resolve_cmd "lazygit" "$tmpdir/nonexistent.json" 2>/dev/null)
assert_eq "lazygit" "$result" "tm_resolve_cmd: nonexistent file returns input unchanged"
if [[ -z "$stderr_out" ]]; then
    ((failed++))
    echo "✗ tm_resolve_cmd: nonexistent file writes warning to stderr"
else
    ((passed++))
    echo "✓ tm_resolve_cmd: nonexistent file writes warning to stderr"
fi

# Test invalid JSON - return input unchanged, stderr non-empty
echo "{not json" > "$tmpdir/invalid.json"
stderr_out=$(tm_resolve_cmd "lazygit" "$tmpdir/invalid.json" 2>&1 >/dev/null || true)
result=$(tm_resolve_cmd "lazygit" "$tmpdir/invalid.json" 2>/dev/null)
assert_eq "lazygit" "$result" "tm_resolve_cmd: invalid JSON returns input unchanged"
if [[ -z "$stderr_out" ]]; then
    ((failed++))
    echo "✗ tm_resolve_cmd: invalid JSON writes warning to stderr"
else
    ((passed++))
    echo "✓ tm_resolve_cmd: invalid JSON writes warning to stderr"
fi

# Test 2: tm_unique_session_name

# No existing names - return base unchanged
result=$(tm_unique_session_name "default-0918-1430")
assert_eq "default-0918-1430" "$result" "tm_unique_session_name: base alone returns unchanged"

# Base is taken - return base-2
result=$(tm_unique_session_name "default-0918-1430" "default-0918-1430")
assert_eq "default-0918-1430-2" "$result" "tm_unique_session_name: base taken appends -2"

# Base and -2 are taken - return base-3
result=$(tm_unique_session_name "default-0918-1430" "default-0918-1430" "default-0918-1430-2")
assert_eq "default-0918-1430-3" "$result" "tm_unique_session_name: base and -2 taken appends -3"

# Test 3: tm_describe_window

# Two-pane window
window_json='{"name":"hou/fea","layout":"x","active":false,"panes":[{"cwd":"/home/kiel/dev/houseworks","cmd":"lazygit","active":false},{"cwd":"/home/kiel/dev/houseworks","cmd":"","active":true}]}'
result=$(tm_describe_window "$window_json")
assert_eq "hou/fea  2 panes  /home/kiel/dev/houseworks" "$result" "tm_describe_window: two panes"

# Single-pane window (no pluralisation - keep literal "1 panes")
window_json='{"name":"test","layout":"x","active":false,"panes":[{"cwd":"/tmp","cmd":"test","active":true}]}'
result=$(tm_describe_window "$window_json")
assert_eq "test  1 panes  /tmp" "$result" "tm_describe_window: single pane uses literal '1 panes'"

# Test 4: Round-trip save file format

cat > "$tmpdir/save.json" <<'EOF'
{
  "saved_at": "2026-09-18T12:45:03+01:00",
  "session": "default",
  "windows": [
    {
      "name": "window1",
      "layout": "x",
      "active": true,
      "panes": [
        {"cwd": "/home", "cmd": "bash", "active": false},
        {"cwd": "/tmp", "cmd": "vim", "active": false},
        {"cwd": "/var", "cmd": "ls", "active": false},
        {"cwd": "/usr", "cmd": "claude --continue", "active": true}
      ]
    },
    {
      "name": "window2",
      "layout": "y",
      "active": false,
      "panes": [
        {"cwd": "/opt", "cmd": "python", "active": true}
      ]
    }
  ]
}
EOF

# Read and verify round-trip format
session=$(jq -r '.session' "$tmpdir/save.json")
assert_eq "default" "$session" "round-trip: .session is correct"

windows_count=$(jq '.windows | length' "$tmpdir/save.json")
assert_eq "2" "$windows_count" "round-trip: (.windows|length) is 2"

pane_cmd=$(jq -r '.windows[0].panes[3].cmd' "$tmpdir/save.json")
assert_eq "claude --continue" "$pane_cmd" "round-trip: .windows[0].panes[3].cmd is correct"

# Summary
echo ""
echo "$passed passed, $failed failed"
if (( failed > 0 )); then
    exit 1
fi
exit 0
