# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

The chezmoi source layout lives here (`dot_*`, `dot_config/`, `dot_hammerspoon/`,
`dot_local/`, `.chezmoitemplates/`). OS-conditional ignores are in
`.chezmoiignore`.

## Apply

```bash
chezmoi init --apply jeff-tooke
```

This clones the repo into `~/.local/share/chezmoi` and applies it.

## Provisioning

Machine setup (packages, system settings, desktop session, fonts) is **not** in
this repo — it lives in
[`system-builder`](https://github.com/jeff-tooke/system-builder). Its `setup.sh`
provisions the OS and then runs the `chezmoi init --apply` above for you, so on a
fresh machine you only clone `system-builder`.
