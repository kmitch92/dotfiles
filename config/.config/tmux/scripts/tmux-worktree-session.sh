#!/usr/bin/env bash

# Tmux Worktree Work Layout
# Creates (or reuses) a git worktree for a branch, then opens the work layout in
# it by handing off to tmux-work-session.sh. With --vertical, the 4-pane variant
# (lazygit/terminal | nvim | claude) is opened instead of the 3-pane default.
#
#   <main-repo-root>/worktrees/<branch with '/' flattened to '-'>
#
# The branch keeps its real name; only the directory name is flattened, so
# branch "feat/login" lives in "worktrees/feat-login".
#
# Ambiguity is resolved by asking, never by guessing:
#   - local <branch> exists            -> offer to check it out in the worktree
#   - only origin/<branch> exists      -> offer to create a local tracking branch
#   - neither exists                   -> create <branch> from current HEAD
#   - worktree already at the target   -> reuse it, just open the layout
#   - worktree for <branch> elsewhere  -> offer to open that path instead
#
# Usage: tmux-worktree-session.sh [--vertical] [branch]
#        (prompts when the branch is omitted)
# Invoked by the workt() / vworkt() shell functions in zsh/.zshrc

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# Sibling lookup rather than a hardcoded ~/.config path: this keeps the script
# runnable straight out of the dotfiles repo as well as from the stowed copy.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

readonly LAYOUT_SCRIPT="$SCRIPT_DIR/tmux-work-session.sh"
readonly HUSKY_SCRIPT="$SCRIPT_DIR/git-husky-worktree-link.sh"

# What link_husky() may do about a real .husky directory already in the worktree.
# Named rather than a bare flag so no caller can force by accident.
#
# .husky is git-tracked, so `git worktree add` always materialises a real .husky
# in the new worktree, and the link script deliberately leaves a real directory
# alone. Only replacing it gets the worktree a symlink, and without that symlink
# the worktree's hooks never find their scripts. Replacing is safe on the create
# path - a fresh checkout artifact - but never on the reuse path, where the
# directory may hold the user's local edits.
readonly HUSKY_REPLACE_EXISTING="replace-existing"
readonly HUSKY_KEEP_EXISTING="keep-existing"

# Worktrees live in one predictable place under the main checkout.
readonly WORKTREES_DIR="worktrees"

# Only this remote is consulted for the "remote branch exists" case.
readonly REMOTE="origin"

# Empty answers are a slip, not an intent - re-ask, but do not loop forever.
readonly MAX_PROMPT_ATTEMPTS=3

# Layout variant flag. Recognised here only to be forwarded verbatim: what it
# means is entirely the layout script's business.
readonly VERTICAL_FLAG="--vertical"

# Options main() collected for the layout script, forwarded ahead of the
# directory by open_layout(). Empty for the default 3-pane layout.
LAYOUT_ARGS=()

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

info() {
    echo "$*"
}

die() {
    echo "❌ $SCRIPT_NAME: $*" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Prompt Helpers
# -----------------------------------------------------------------------------

# Prompts go to stderr, never stdout: prompt_branch() is read via command
# substitution, so anything on stdout would be swallowed into the branch name.

trim() {
    local s="$1"
    s="${s%$'\r'}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Yes/no question defaulting to yes. Non-zero means "no" (or EOF/abort).
confirm() {
    local reply
    printf '%s [Y/n]: ' "$*" >&2

    if ! IFS= read -r reply; then
        printf '\n' >&2
        return 1
    fi

    case "$(trim "$reply")" in
        "" | y | Y | yes | Yes | YES) return 0 ;;
        *) return 1 ;;
    esac
}

# Ask for a branch name. Prints it on stdout; non-zero when the user gives up.
prompt_branch() {
    local reply attempt=0

    while [[ $attempt -lt $MAX_PROMPT_ATTEMPTS ]]; do
        attempt=$((attempt + 1))
        printf 'Branch name: ' >&2

        if ! IFS= read -r reply; then
            # EOF (Ctrl-D) - a deliberate abort.
            printf '\n' >&2
            return 1
        fi

        reply="$(trim "$reply")"
        if [[ -n "$reply" ]]; then
            printf '%s\n' "$reply"
            return 0
        fi

        echo "Branch name cannot be empty." >&2
    done

    return 1
}

# -----------------------------------------------------------------------------
# Git Helpers
# -----------------------------------------------------------------------------

require_repo() {
    command -v git >/dev/null 2>&1 || die "git is not installed"

    git rev-parse --git-common-dir >/dev/null 2>&1 ||
        die "not a git repository: $PWD"

    [[ "$(git rev-parse --is-bare-repository)" == "false" ]] ||
        die "this is a bare repository - worktrees need a normal checkout"
}

# The MAIN checkout, i.e. the one holding the real .git directory. Resolving via
# --git-common-dir (not --show-toplevel) is what stops `workt` run from inside a
# worktree producing worktrees/worktrees/...
main_repo_root() {
    local common_dir
    common_dir="$(git rev-parse --git-common-dir)"

    # Relative (a bare ".git") at the top level of a checkout, absolute from a
    # linked worktree.
    [[ "$common_dir" == /* ]] || common_dir="$PWD/$common_dir"

    dirname "$(cd "$common_dir" && pwd -P)"
}

# Reject anything that is not a legal branch name, or that could climb out of
# the worktrees directory once flattened.
validate_branch() {
    local branch="$1"

    case "$branch" in
        "") die "branch name cannot be empty" ;;
        -*) die "branch name may not start with '-': $branch" ;;
        /*) die "branch name may not be an absolute path: $branch" ;;
        */) die "branch name may not end with '/': $branch" ;;
        *..*) die "branch name may not contain '..': $branch" ;;
    esac

    # Authoritative check - covers spaces, control characters, ~ ^ : ? * [ \ etc.
    git check-ref-format "refs/heads/$branch" 2>/dev/null ||
        die "not a valid git branch name: $branch"
}

local_branch_exists() {
    git show-ref --verify --quiet "refs/heads/$1"
}

remote_branch_exists() {
    git show-ref --verify --quiet "refs/remotes/$REMOTE/$1"
}

# Print the path of the existing worktree checked out on branch $1, if any.
worktree_path_for_branch() {
    local branch="$1" path="" line

    while IFS= read -r line; do
        case "$line" in
            "worktree "*) path="${line#worktree }" ;;
            # Quoted pattern: glob metacharacters in the branch stay literal.
            "branch refs/heads/$branch")
                printf '%s\n' "$path"
                return 0
                ;;
        esac
    done < <(git worktree list --porcelain)

    return 1
}

# Commit to branch from when creating a brand new branch. A detached HEAD has no
# branch name to hand to git, so resolve to the commit itself either way.
# Non-zero (and no output) in a repository without commits.
current_head_commit() {
    git rev-parse --verify --quiet HEAD
}

# -----------------------------------------------------------------------------
# Actions
# -----------------------------------------------------------------------------

# link_husky <worktree> <HUSKY_REPLACE_EXISTING|HUSKY_KEEP_EXISTING>
# The policy is a required argument: every caller has to state its own.
link_husky() {
    local worktree="$1" existing_policy="$2"

    if [[ ! -x "$HUSKY_SCRIPT" ]]; then
        echo "⚠️  Husky link skipped - not found or not executable: $HUSKY_SCRIPT" >&2
        return 0
    fi

    # Never fatal: a missing hooks symlink must not stop the layout from opening.
    # An unknown policy is a bug here, not a husky failure, so it does stop.
    case "$existing_policy" in
        "$HUSKY_REPLACE_EXISTING") "$HUSKY_SCRIPT" --force "$worktree" || true ;;
        "$HUSKY_KEEP_EXISTING") "$HUSKY_SCRIPT" "$worktree" || true ;;
        *) die "internal error: unknown husky policy: $existing_policy" ;;
    esac
}

# Hand off to the existing work layout. exec so that the layout script's
# attach-session inherits this process's terminal directly.
open_layout() {
    local dir="$1"

    [[ -x "$LAYOUT_SCRIPT" ]] ||
        die "layout script not found or not executable: $LAYOUT_SCRIPT
   Run 'stow config' from ~/dotfiles to deploy it"

    info "▶️  Opening work layout in $dir"
    # ${arr[@]+"${arr[@]}"}: bash 3.2 (the system bash on macOS) treats an empty
    # array as unset under `set -u`, so a bare "${LAYOUT_ARGS[@]}" would abort.
    exec "$LAYOUT_SCRIPT" ${LAYOUT_ARGS[@]+"${LAYOUT_ARGS[@]}"} "$dir"
}

# Create the worktree; arguments are passed to `git worktree add` verbatim, in
# git's documented order ([-b <branch>] <path> [<commit-ish>]).
# On failure git's own message is already on stderr, so say nothing more and -
# crucially - do not open a layout for a directory that was never created.
add_worktree() {
    git worktree add "$@" ||
        die "git worktree add failed - no layout opened"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    require_repo

    # Flags are consumed BEFORE the positional branch, so --vertical is never
    # taken for a branch name (validate_branch rejects anything starting '-').
    while [[ $# -gt 0 ]]; do
        case "$1" in
            "$VERTICAL_FLAG")
                # Assignment, not +=, so repeating the flag stays harmless.
                LAYOUT_ARGS=("$VERTICAL_FLAG")
                shift
                ;;
            --)
                shift
                break
                ;;
            -*) die "unknown option: $1" ;;
            *) break ;;
        esac
    done

    local branch
    if [[ $# -gt 0 ]]; then
        branch="$(trim "$1")"
    elif ! branch="$(prompt_branch)"; then
        die "no branch name given - nothing created"
    fi

    validate_branch "$branch"

    local main_root worktrees_root flat target
    main_root="$(main_repo_root)"
    worktrees_root="$main_root/$WORKTREES_DIR"

    # Flatten for the PATH only; the branch keeps its slashes.
    flat="${branch//\//-}"
    case "$flat" in
        "" | . | ..) die "branch name flattens to an unusable directory name: $branch" ;;
        -*) die "branch name flattens to a directory name starting with '-': $branch" ;;
    esac

    target="$worktrees_root/$flat"

    # Defence in depth: the target must be a direct child of worktrees/.
    [[ "$(dirname "$target")" == "$worktrees_root" ]] ||
        die "refusing to create a worktree outside $worktrees_root: $target"

    # A worktree already on this branch somewhere else: git would refuse anyway,
    # so report the real location and offer it instead of failing.
    local existing
    if existing="$(worktree_path_for_branch "$branch")" && [[ "$existing" != "$target" ]]; then
        info "ℹ️  Branch '$branch' is already checked out in a worktree at:"
        info "     $existing"
        if confirm "Open the work layout there instead?"; then
            open_layout "$existing"
        fi
        die "aborted - nothing created"
    fi

    # Target already present: reuse it. The layout script is itself idempotent
    # per directory, so this collapses to "focus the existing window".
    if [[ -e "$target" ]]; then
        if [[ -z "${existing:-}" ]]; then
            echo "⚠️  $target exists but is not a worktree for '$branch' - opening it anyway" >&2
        else
            info "ℹ️  Reusing existing worktree: $target"
        fi
        open_layout "$target"
    fi

    # Decide how the worktree gets its branch.
    if local_branch_exists "$branch"; then
        info "ℹ️  Local branch '$branch' already exists."
        confirm "Check it out in the new worktree at $target?" ||
            die "aborted - nothing created"
        add_worktree "$target" "$branch"
    elif remote_branch_exists "$branch"; then
        info "ℹ️  No local branch '$branch', but $REMOTE/$branch exists."
        confirm "Create a local tracking branch from $REMOTE/$branch?" ||
            die "aborted - nothing created"
        add_worktree --track -b "$branch" "$target" "$REMOTE/$branch"
    else
        local head_commit
        head_commit="$(current_head_commit)" ||
            die "repository has no commits yet - commit something before creating worktrees"
        info "ℹ️  Creating new branch '$branch' from current HEAD (${head_commit:0:12})."
        add_worktree -b "$branch" "$target" "$head_commit"
    fi

    # Create path only - the reuse branch above exec'd into open_layout already.
    link_husky "$target" "$HUSKY_REPLACE_EXISTING"
    open_layout "$target"
}

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------

main "$@"
