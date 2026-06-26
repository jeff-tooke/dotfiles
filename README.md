# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

The chezmoi source layout lives here (`dot_*`, `dot_config/`, `dot_hammerspoon/`,
`dot_local/`, `.chezmoitemplates/`). OS-conditional ignores are in
`.chezmoiignore`; machine-specific overrides live in the `private` submodule.

## Apply

```bash
chezmoi init --apply jeff-tooke
```

This clones the repo into `~/.local/share/chezmoi` and applies it. The `private`
submodule uses an SSH URL, so on a keyless machine add
`--recurse-submodules=false` and pull it once SSH keys are in place.

## Provisioning

Machine setup (packages, system settings, desktop session, fonts) is **not** in
this repo — it lives in
[`system-builder`](https://github.com/jeff-tooke/system-builder). Its `setup.sh`
provisions the OS and then runs the `chezmoi init --apply` above for you, so on a
fresh machine you only clone `system-builder`.
