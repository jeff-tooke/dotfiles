#!/bin/bash

# ============================================================================
# Prerequisites (must be true BEFORE running this script)
# ----------------------------------------------------------------------------
# Arch Linux (primary target):
#   - Base Arch install is complete (archinstall or manual) and booted
#   - A non-root user account exists with sudo privileges (wheel group)
#   - Working internet connection
#   - These packages installed via pacman:  base-devel git sudo
#     (git is needed to clone this repo; base-devel + git are needed by
#      makepkg/yay for AUR builds later in the script)
#   - This repo is cloned to ~/.dotfiles, e.g.:
#       git clone --recurse-submodules https://github.com/<user>/dotfiles ~/.dotfiles
#   - Run as the target user (NOT root); the script will sudo when needed
#
# Debian/Ubuntu/Fedora/RHEL: a working install with sudo + curl + git.
# macOS: a fresh user account; Xcode CLI tools + Homebrew will be installed.
# ============================================================================

set -eE

echo "Starting system provisioning..."

LOG_FILE="/tmp/system-setup-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[x]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }
section() { echo -e "\n${BLUE}--- $1 ---${NC}\n" | tee -a "$LOG_FILE"; }

# Define common packages for Linux
PACKAGES=(
    "bat" "btop" "chezmoi" "curl" "dunst" "eza" "fastfetch" "fd" "foot" "fzf" "git" "grim" "jq" "make" "neovim"
    "podman" "podman-compose" "ripgrep" "slurp" "starship" "tmux" "unzip" "waybar" "wget" "wl-clipboard" "wofi" "zoxide" "zsh"
    "zsh-autosuggestions" "zsh-syntax-highlighting"
)

RUN_STANDARD_LINUX_INSTALL=true
IS_ARCH=false

# =============================================================================
# 1. Detect OS and install dependencies
# =============================================================================

if [[ "$OSTYPE" == "darwin"* ]]; then
    section "Configuring for macOS"
    DISTRO="macos"
    RUN_STANDARD_LINUX_INSTALL=false
    log "Detected macOS. Skipping standard Linux package management loops and installing Homebrew and nix-darwin..."
    if ! command -v brew &> /dev/null; then
        xcode-select --install
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo >> /Users/$USER/.zprofile
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/$USER/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    # brew install chezmoi neovim cmake git eza bat

elif [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID,,}"

    case "$DISTRO" in
        nixos)
            section "Configuring for NixOS"
            RUN_STANDARD_LINUX_INSTALL=false
            log "Detected NixOS. System should be managed via configuration.nix. See README.md for more details"
            ;;

        debian|ubuntu|pop|mint)
            section "Configuring for Debian/Ubuntu"
            PKG_MANAGER="apt-get"
            INSTALL_ARGS="-y install"

            PACKAGES+=("build-essential")
            PACKAGES+=("python3")
            PACKAGES+=("python3-pip")
            ;;

        fedora|rhel|centos|rocky|almalinux)
            section "Configuring for Fedora/RHEL"
            PKG_MANAGER="dnf"
            INSTALL_ARGS="-y install"

            PACKAGES+=("@Development Tools")
            PACKAGES+=("python")
            PACKAGES+=("python-pip")
            ;;

        arch|archarm|cachyos|manjaro)
            section "Configuring for Arch Linux"
            PKG_MANAGER="pacman"
            INSTALL_ARGS="-S --needed --noconfirm"

            # Core tooling (not strictly desktop-essential, kept per user goal)
            PACKAGES+=(
                "base-devel" "greetd-tuigreet" "k9s" "lazydocker" "lazygit"
                "python" "python-pip" "gnupg" "openssh"
            )

            # Hyprland desktop minimum set:
            #   compositor + portals, auth agent, Qt/Wayland, audio (pipewire),
            #   network (NetworkManager), greetd, lock/idle, wallpaper,
            #   fonts/icons, misc desktop glue.
            PACKAGES+=(
                "hyprland" "hyprpaper" "hyprlock" "hypridle"
                "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
                "polkit" "polkit-gnome"
                "qt5-wayland" "qt6-wayland" "gtk3" "gtk4"
                "pipewire" "pipewire-pulse" "wireplumber"
                "networkmanager"
                "noto-fonts" "noto-fonts-emoji" "ttf-jetbrains-mono-nerd"
                "papirus-icon-theme"
                "brightnessctl" "xdg-utils"
            )
            IS_ARCH=true
            ;;

        *)
            err "Unsupported distribution: $DISTRO"
            ;;
    esac
else

    err "Cannot detect OS type. /etc/os-release missing and not running on macOS."
fi

# =============================================================================
# 2. System Sync & Execution Loop (Skipped for macOS and NixOS)
# =============================================================================

if [ "$RUN_STANDARD_LINUX_INSTALL" = true ]; then

    section "Updating Package Repositories"
    case "$PKG_MANAGER" in
        apt-get) sudo apt-get update ;;
        dnf)     sudo dnf check-update || true ;;
        pacman)  sudo pacman -Syu --noconfirm ;;
    esac

    section "Installing Target Core Packages"
    log "Installing: ${PACKAGES[*]}"
    sudo $PKG_MANAGER $INSTALL_ARGS "${PACKAGES[@]}"
    log "Core packages installation complete."

fi

# =============================================================================
# 3. Arch-Specific Installation Block (AUR Helper)
# =============================================================================

if [ "$IS_ARCH" = true ]; then

    section "Installing yay (Arch AUR Helper)"
    if ! command -v yay &>/dev/null; then
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
        log "yay installed"
    else
        warn "yay already installed"
    fi

    section "Installing AUR packages"
    AUR_PKGS=(
        "zen-browser-bin"
        # "catppuccin-gtk-theme-mocha"
        # "catppuccin-papirus-folders-git"
        "claude-code-stable-bin"
        "opencode-bin"
    )

    for pkg in "${AUR_PKGS[@]}"; do
        log "Installing AUR package: $pkg..."
        yay -S --needed --noconfirm "$pkg" 2>>"$LOG_FILE" || warn "Failed: $pkg — install manually if needed"
    done

    # -----------------------------------------------------------------------
    # Arch: Desktop services (greetd + NetworkManager + group membership)
    # -----------------------------------------------------------------------
    section "Enabling NetworkManager"
    sudo systemctl enable NetworkManager.service

    section "Configuring greetd + tuigreet"
    sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --cmd start-hyprland"
user = "greeter"
EOF
    sudo systemctl enable greetd.service
    log "/etc/greetd/config.toml written; greetd.service enabled"

    if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
        warn "No /usr/share/wayland-sessions/hyprland.desktop — tuigreet uses --cmd directly so this is informational only"
    fi
    if ! command -v start-hyprland &>/dev/null; then
        warn "start-hyprland wrapper not on PATH — create it before rebooting, e.g. a script that exports XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=Hyprland then exec Hyprland"
    fi

    section "Adding $USER to video,input groups"
    sudo usermod -aG video,input "$USER"
    if getent group seat &>/dev/null; then
        sudo usermod -aG seat "$USER"
    fi

    section "Setting zsh as login shell"
    if getent passwd "$USER" | grep -q '/zsh$'; then
        warn "Login shell is already zsh"
    else
        sudo chsh -s /usr/bin/zsh "$USER" && log "Login shell set to /usr/bin/zsh"
    fi

    # -----------------------------------------------------------------------
    # Arch: chezmoi bootstrap (uncomment once Hyprland session is verified)
    # -----------------------------------------------------------------------
    # section "Applying dotfiles via chezmoi"
    # chezmoi init --source "$HOME/.dotfiles"
    # chezmoi apply --source "$HOME/.dotfiles"

fi

# Arch installs ttf-jetbrains-mono-nerd via pacman as part of the main package
# list above. Debian/Fedora have no equivalent repo package, so download the
# Nerd Font release zip manually.
if [ "$IS_ARCH" != true ] && [ "$RUN_STANDARD_LINUX_INSTALL" = true ]; then
    section "Installing JetBrainsMono Nerd Font (manual)"
    FONT_NAME="JetBrainsMono"
    FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"

    if [ ! -d "$FONT_DIR" ]; then
        log "Downloading $FONT_NAME Nerd Font..."
        mkdir -p "$FONT_DIR"

        TEMP_ZIP=$(mktemp)
        curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip" -o "$TEMP_ZIP"
        unzip -qo "$TEMP_ZIP" -d "$FONT_DIR"
        rm -f "$TEMP_ZIP"

        log "Rebuilding font cache..."
        fc-cache -f > /dev/null
        log "$FONT_NAME installed successfully."
    else
        warn "$FONT_NAME Nerd Font is already installed in $FONT_DIR. Skipping."
    fi
fi

# =============================================================================
# 4. Independent Tools (Runs everywhere, including macOS/NixOS if applicable)
# =============================================================================

# TPM bootstrap — disabled until chezmoi has applied ~/.config/tmux/tmux.conf.
# Uncomment after running the chezmoi block above; install_plugins is a no-op
# unless the tmux config lists plugins for TPM to manage.
#
# section "Installing TPM (Tmux Plugin Manager)"
# TPM_DIR="$HOME/.tmux/plugins/tpm"
# if [ ! -d "$TPM_DIR" ]; then
#     git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
#     log "TPM installed"
# else
#     warn "TPM already exists"
# fi
#
# section "Bootstrapping tmux plugins"
# if [ -f "$HOME/.config/tmux/tmux.conf" ] || [ -f "$HOME/.tmux.conf" ]; then
#     "$TPM_DIR/bin/install_plugins" 2>>"$LOG_FILE" \
#         && log "Tmux plugins installed" \
#         || warn "TPM auto-install failed — open tmux and press prefix+I"
# else
#     warn "No tmux.conf found — skipping plugin install. Re-run after chezmoi apply."
# fi

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "======================================================================="
echo " System provisioning complete!"
echo " Log: $LOG_FILE"
echo "======================================================================="

if [ "$IS_ARCH" = true ]; then
    cat <<'EOF'

Next steps (Arch):
  1. Ensure a 'start-hyprland' wrapper is on PATH (exports Wayland env vars
     then exec Hyprland). Example: ~/.local/bin/start-hyprland.
  2. Reboot. tuigreet should appear on tty1; log in to enter Hyprland.
  3. Once the desktop is verified, uncomment the chezmoi block in this
     script and re-run to deploy dotfiles to ~/.config.
  4. After chezmoi apply, uncomment the TPM block and re-run to install
     tmux plugins.

EOF
fi
