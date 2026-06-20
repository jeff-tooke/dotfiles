# New build guide

This is a guide to bootstrapping a new mac from scratch

## Install dependencies

A clean macOS has no real `git` — only a `/usr/bin/git` stub that opens the
Xcode Command Line Tools GUI installer the first time it runs. To avoid that
chicken-and-egg (no git → can't clone → can't run setup), open the terminal
application and run this single command first. It installs the Command Line
Tools, waits for the GUI install to finish, then clones the repo:

```bash
xcode-select --install 2>/dev/null; \
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done; \
  git clone https://github.com/$GITHUB_USERNAME/dotfiles.git ~/dotfiles
```

From here you can run the scripted bootstrap (`~/.dotfiles/macos/setup.sh`), or
follow the manual steps below.

The next thing to do is install the remaining tools used for system
configuration:

```bash
# Install homebrew - https://brew.sh/
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /Users/$USER/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$USER/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install nix-darwin - https://mynixos.com/nix-darwin
#curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos
curl -L https://nixos.org/nix/install | sh
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

**NOTE** During installation be sure to install default nix by answering no when asked to install Determinate Nix.

After installing dependencies for system configuration proceed to next steps

The repo was already cloned to `~/.dotfiles` in the bootstrap step above (use
the plain `git clone` without `--recurse-submodules` there if you are not using
the private git sub-module).

```bash
# Apply system default settings
cd ~/.dotfiles/setup/system-settings
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .

# Install default packages
cd ~/.dotfiles/setup/package-management
brew bundle

# If installing machine-specific configuration or packages these can be found here:
cd ~/.dotfiles/private

# Switch to the desired submodule branch eg: personal
git checkout personal

# Install machine-specific packages
brew bundle --file=setup/package-management/Brewfile

# Apply dotfiles
cd ~
chezmoi init --source ~/.dotfiles
chezmoi apply --source ~/.dotfiles
```

## Post-installation configuration

- Start aerospace from Applications and check it is added background login items.
- Add Raycast and Hammerspoon to login items
- Allow `corelocationcli` app to run in Privacy and Security settings
- Enable Location Services in System settings and grant `corelocationcli` app access
- Run the following to initialise some tools

```bash
# Install catppuccin theme for bat
bat cache --build

# Start borders service
brew services start borders

# Install tmux plugins
/opt/homebrew/opt/tpm/share/tpm/bin/install_plugins
```

**TODO** - Script the above and write additional script to perform managed updates
