# macOS provisioning (`macos/setup.sh`)

A best-effort, scripted bootstrap for a fresh macOS user account. It is a
trimmed, macOS-only rewrite of the multi-distro `linux/setup.sh`, kept aligned
with that script's helpers and structure so it can later be folded back into the
unified script's `OSTYPE == darwin*` branch.

## Prerequisites

- A fresh / clean macOS **user account**.
- Working internet connection.
- This repo cloned to `~/.dotfiles`:
  ```bash
  git clone --recurse-submodules https://github.com/<user>/dotfiles ~/.dotfiles
  ```
- Run **as the target user** (not root); the script `sudo`s where needed.

## Run

```bash
~/.dotfiles/macos/setup.sh
```

The full run is logged to `~/system-setup-<timestamp>.log`.

## What it does

1. **sudo keep-alive** — primes `sudo -v` and refreshes the timestamp in the
   background so a multi-minute run isn't interrupted by repeated password
   prompts. The background refresher is killed on exit via a trap.
2. **Xcode Command Line Tools** — `xcode-select --install`, then waits.
3. **Homebrew** — non-interactive install (`NONINTERACTIVE=1`) + `shellenv` in
   `~/.zprofile`.
4. **Nix** — official `nixos.org` installer, driven with `--daemon --yes`.
5. **nix-darwin** — `nix run nix-darwin -- switch --flake .` from
   `setup/system-settings`.
6. **Homebrew packages** — `brew bundle` against `setup/package-management/Brewfile`.
7. **chezmoi** — `init --source` (first run) then `apply --source` from the repo.
8. **Tool init** — `bat cache --build`, start the `borders` service, install
   tmux plugins via TPM.

Every step is idempotent: re-running skips anything already installed.

## Known interactive challenges (why it isn't 100% hands-off)

macOS resists full unattended provisioning. Expect to babysit these:

- **Xcode CLI tools dialog** — `xcode-select --install` pops a GUI dialog that
  must be clicked. The script then polls until the tools appear; it cannot click
  the dialog for you.
- **First sudo password prompt** — unavoidable. The keep-alive loop only
  *maintains* the timestamp after you've entered the password once.
- **Nix installer** — interactive by default; `--daemon --yes` makes it
  non-interactive. NOTE: the top-level `README.md` still says "answer **no** to
  Determinate Nix" — that note is **stale** under the `nixos.org` installer
  (which never asks that). Flag for cleanup when the top-level README is next
  touched.
- **nix-darwin first switch** — slow (builds the system closure) and needs
  `sudo`. If it fails, re-run just that step.
- **Cask TCC / Gatekeeper approvals** — apps installed via `brew bundle`
  (Hammerspoon, Karabiner-Elements, Raycast, `corelocationcli`, aerospace) need
  manual approval in **System Settings → Privacy & Security**
  (Accessibility, Input Monitoring, Location Services). Not scriptable.

## Manual post-install steps

These mirror the top-level `README.md` and **must be done by hand**:

- Start **aerospace** from Applications and confirm it's added to Login Items.
- Add **Raycast** and **Hammerspoon** to Login Items.
- Allow the **`corelocationcli`** app in Privacy & Security.
- Enable **Location Services** in System Settings and grant `corelocationcli`
  access.

## Merge-back note

This script deliberately reuses the unified script's logging helpers
(`log/warn/err/section`), `LOG_FILE`/`tee` setup, and section layout. When the
macOS flow is stable, its body can drop into the `if [[ "$OSTYPE" == "darwin"* ]]`
branch of `linux/setup.sh` with minimal changes.
