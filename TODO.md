# Dotfiles TODO

Planned changes, made via the chezmoi flow: `dfe <file>` to edit the source,
`dfp "msg"` to push, `dfu` on other machines. This file is repo-only (see
`.chezmoiignore`) — it is not applied to `$HOME`.

## Terminal: go native, drop tmux auto-launch
- The tmux auto-attach in `dot_zshrc.tmpl` (the `if [[ -z "$TMUX" ]]` block) makes
  every new terminal attach the *same* session, so multiple windows mirror each
  other (keystrokes/commands run in both). Also why a new terminal shows stale
  config until `exec zsh`.
- Move to native tabs/panes: kitty (`enabled_layouts splits`, nicer tab bar) and
  ghostty (already supports tabs/splits). Keep tmux installed for SSH/remote and
  long-running jobs — just not auto-started locally.
- Trade-offs accepted: lose the tmux status bar (cpu/mem/path) and resurrect/
  continuum process persistence. Approach options: (1) fully native, (2) per-terminal
  independent/grouped tmux session, or (3) opt-in `tmux` alias.
- Files: `dot_zshrc.tmpl`, `dot_config/kitty/kitty.conf`, ghostty config (macOS).

## Linux: refine waybar
- Tidy / refine the waybar setup on Linux.
- Files: `dot_config/waybar/**` (Linux-only; macOS ignores it via `.chezmoiignore`).
