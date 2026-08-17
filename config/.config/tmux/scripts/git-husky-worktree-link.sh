#!/usr/bin/env bash

# Git Worktree Husky Link
# Points a linked worktree's .husky at the main repository's .husky directory.
#
# Husky installs its hooks path once, in the main checkout. A linked worktree
# gets its own working tree but shares the main repo's hooks config, so without
# a .husky here every hook invocation in the worktree fails to find its scripts.
# A *relative* symlink is used deliberately: an absolute one breaks the moment
# the repo is moved or the worktree is inspected from a container/other host.
#
# Usage: git-husky-worktree-link.sh [--force] <worktree-path>
#   --force  replace an existing real .husky directory with the symlink
#
# This is the single home for that logic: gwa(), fix-husky-worktree() and
# tmux-worktree-session.sh all call it rather than carrying their own copy.

set -euo pipefail

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

die() {
    echo "❌ $*" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

usage() {
    echo "Usage: $(basename "${BASH_SOURCE[0]}") [--force] <worktree-path>" >&2
}

# Resolve to a physical, absolute path with no trailing slash, so the path
# arithmetic in relative_path() operates on comparable components.
canonical_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || die "not a directory: $dir"
    (cd "$dir" && pwd -P)
}

# Print the path of $1 relative to the directory $2 (both absolute, physical).
# Equivalent to Python's os.path.relpath, without the python3 dependency -
# python3 is not guaranteed present on a fresh Linux box, and the previous
# "../../.husky" fallback silently produced a broken link at any other depth.
relative_path() {
    local target="$1" base="$2"
    local -a target_parts=() base_parts=() out=()
    local i common=0 joined=""

    # A non-whitespace IFS preserves empty fields, so the leading "" produced by
    # the absolute paths' leading "/" lines up in both arrays. Splitting only on
    # "/" also means components containing spaces survive intact.
    IFS='/' read -r -a target_parts <<<"$target"
    IFS='/' read -r -a base_parts <<<"$base"

    while [[ $common -lt ${#target_parts[@]} && $common -lt ${#base_parts[@]} ]] &&
        [[ "${target_parts[common]}" == "${base_parts[common]}" ]]; do
        common=$((common + 1))
    done

    # One ".." per base component below the common ancestor...
    for ((i = common; i < ${#base_parts[@]}; i++)); do
        out+=("..")
    done
    # ...then descend into what is left of the target.
    for ((i = common; i < ${#target_parts[@]}; i++)); do
        out+=("${target_parts[i]}")
    done

    if [[ ${#out[@]} -eq 0 ]]; then
        printf '.\n'
        return 0
    fi

    for i in "${out[@]}"; do
        joined="${joined:+$joined/}$i"
    done
    printf '%s\n' "$joined"
}

# Print the main repository root for the repo containing $1, i.e. the checkout
# holding the real .git directory, even when $1 is itself a linked worktree.
main_repo_root() {
    local dir="$1" common_dir

    common_dir="$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)" ||
        die "not a git repository: $dir"

    # --git-common-dir is relative to the working directory at the top level of
    # a checkout (it prints a bare ".git"), absolute from a linked worktree.
    [[ "$common_dir" == /* ]] || common_dir="$dir/$common_dir"

    dirname "$(cd "$common_dir" && pwd -P)"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    local force="false"
    local -a args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f | --force)
                force="true"
                shift
                ;;
            -h | --help)
                usage
                exit 0
                ;;
            --)
                shift
                args+=("$@")
                break
                ;;
            -*)
                usage
                die "unknown option: $1"
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    [[ ${#args[@]} -eq 1 ]] || {
        usage
        die "expected exactly one worktree path"
    }

    local worktree main_root husky_src rel link
    worktree="$(canonical_dir "${args[0]}")"
    main_root="$(main_repo_root "$worktree")"

    if [[ "$main_root" == "$worktree" ]]; then
        echo "❌ Not a linked worktree (this is the main repo): $worktree" >&2
        echo "   Run this from inside a worktree created by 'git worktree add'" >&2
        exit 1
    fi

    husky_src="$main_root/.husky"
    if [[ ! -d "$husky_src" ]]; then
        echo "ℹ️  No .husky in $main_root - nothing to link"
        exit 0
    fi

    link="$worktree/.husky"
    rel="$(relative_path "$husky_src" "$worktree")"

    if [[ -L "$link" ]]; then
        # Already a symlink: only correct it, never blow it away.
        if [[ "$(readlink "$link")" == "$rel" ]]; then
            echo "✅ Husky already linked: .husky -> $rel"
            exit 0
        fi
        ln -sfn "$rel" "$link"
        echo "✅ Husky symlink repointed: .husky -> $rel"
        exit 0
    fi

    if [[ -e "$link" ]]; then
        if [[ "$force" != "true" ]]; then
            echo "✅ Husky already configured (real .husky present, left alone)"
            echo "   Pass --force to replace it with a symlink"
            exit 0
        fi
        rm -rf "$link"
    fi

    ln -sfn "$rel" "$link"
    echo "✅ Husky symlink created: .husky -> $rel"
}

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------

main "$@"
