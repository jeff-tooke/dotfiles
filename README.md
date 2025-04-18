# New build guide

This is a guide to bootstrapping a new mac from scratch

## Install dependencies

The first thing to do is install the tools used for system configuration. 
Open the terminal application and run the following commands:

```bash
# Install xcode cli tools
xcode-select --install

# Install homebrew - https://brew.sh/
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /Users/$USER/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$USER/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install nix-darwin - https://mynixos.com/nix-darwin
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```
**NOTE** During installation be sure to install default nix by answering no when asked to install Determinate Nix.

After installing dependencies for system configuration proceed to next steps

```bash
# Ensure you are in home directory and clone dotfiles repo
cd
git clone https://github.com/$GITHUB_USERNAME/dotfiles.git ~/.dotfiles

# Apply system default settings
cd ~/.dotfiles/setup/system-settings
nix run nix-darwin -- switch --flake .

# Install gui apps with homebrew
cd ~/.dotfiles/setup/package-management
brew bundle

# Apply dotfile configuration for apps
cd
chezmoi init --source ~/.dotfiles
chezmoi apply --source ~/.dotfiles
```

## Post-installation configuration
Manually start aerospace from Applications and add to login start items
Run the following to initialise some tools

```bash
# Install catppuccin theme for bat
bat cache --build

# Start borders service
brew services start borders
```

From within tmux session, install plugins by pressing `C-a I`

**TODO** - Script the above and write additional script to perform managed updates