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
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos

. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

**NOTE** During installation be sure to install default nix by answering no when asked to install Determinate Nix.

After installing dependencies for system configuration proceed to next steps

```bash
# Ensure you are in home directory and clone dotfiles repo
cd ~
git clone --recurse-submodules https://github.com/$GITHUB_USERNAME/dotfiles.git ~/.dotfiles

# NOTE: You should just use this if not utilising private git sub-module
# git clone https://github.com/$GITHUB_USERNAME/dotfiles.git ~/.dotfiles

# Apply system default settings
cd ~/.dotfiles/setup/system-settings
sudo nix run nix-darwin -- switch --flake .

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
