# tmux Auto-Start Troubleshooting (Open — Ubuntu)

## Symptom

- **Ubuntu**: opening a terminal does NOT auto-start tmux.
- **macOS**: user IS in tmux, but the live session is named `0`, not `default` — suggesting it wasn't the auto-start block that created it.

## The auto-start block

`zsh/.zshrc` lines 121-135:

```bash
if command -v tmux &> /dev/null; then
    # Only start tmux if:
    # 1. Not already in tmux
    # 2. Not disabled via environment variable
    # 3. This is an interactive shell
    # 4. Not in an IDE terminal (VS Code, etc.)
    if [[ -z "$TMUX" ]] && \
       [[ "${DISABLE_AUTO_TMUX:-false}" != "true" ]] && \
       [[ $- == *i* ]] && \
       [[ -z "$VSCODE_INJECTION" ]] && \
       [[ -z "$TERM_PROGRAM" ]]; then
        # Attach to existing session or create new one
        tmux attach-session -t default || tmux new-session -s default
    fi
fi
```

All six conditions must hold: `tmux` on PATH, `$TMUX` empty, `DISABLE_AUTO_TMUX` not `"true"`, interactive shell (`$-` has `i`), `$VSCODE_INJECTION` empty, `$TERM_PROGRAM` empty.

## Hypotheses (unverified — confirm before acting)

1. **`[[ -z "$TERM_PROGRAM" ]]` is over-broad.** Presumably meant to skip IDE/embedded terminals, but Ghostty, kitty, WezTerm, iTerm2, and Apple Terminal all set `TERM_PROGRAM` — so on macOS this guard suppresses auto-start in essentially every real terminal emulator. This repo ships configs for `kitty`, `ghostty`, `wezterm`, and `alacritty` under `config/.config/`, so this is directly relevant here.

2. **The macOS session may be continuum's, not auto-start's.** The live session is named `0`, but the auto-start block only ever creates/attaches a session named `default` — mismatch. `tmux/.tmux.conf` line 144 sets `@continuum-restore 'on'`. Likely explanation: tmux-continuum restored a prior session rather than the auto-start block creating one. Not confirmed.

3. **Ubuntu may never source `.zshrc` at all.** GNOME Terminal does not normally set `TERM_PROGRAM`, so that guard shouldn't be the blocker there. More likely: the Ubuntu login shell is still bash, so `.zshrc` is never read. **This is unverified — the Ubuntu machine was not accessible when this doc was written.**

## Diagnostic to run first (on Ubuntu)

```bash
echo "shell=$SHELL / running=$0"; echo "TERM_PROGRAM=[$TERM_PROGRAM]"; echo "DISABLE_AUTO_TMUX=[$DISABLE_AUTO_TMUX]"; command -v tmux
```

| Result | Cause | Fix |
|---|---|---|
| `$SHELL`/`$0` is `bash`, not `zsh` | `.zshrc` never sourced | `chsh -s $(which zsh)`, log out/in, then re-run `scripts/setup-shell.sh` |
| `TERM_PROGRAM` non-empty | Over-broad guard suppressing auto-start | Narrow the guard to the specific IDE case(s) it was meant to catch, or drop the condition |
| `DISABLE_AUTO_TMUX=true` | Set deliberately somewhere | Check `~/.zshrc.local` (machine-local override file, see project `CLAUDE.md`) |
| `command -v tmux` empty | tmux not installed | Re-run the dev-tools install step |

## Open decision: is auto-start still wanted?

A `work` command is being added in this repo (zsh function + `config/.config/tmux/scripts/tmux-work-session.sh`) that builds a multi-pane tmux layout and handles the not-already-in-tmux case itself by creating/attaching a session. If `work` becomes the habitual entry point, auto-start may be redundant — removing the block entirely is a legitimate resolution here, not just fixing the `TERM_PROGRAM` guard. Left as an open decision for the user, not a recommendation.
