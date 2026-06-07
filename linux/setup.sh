#!/bin/bash

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
    "bat" "btop" "chezmoi" "curl" "dunst" "eza" "fastfetch" "fd" "flameshot" "foot" "fzf" "git" "jq" "make" "neovim"
    "podman" "podman-compose" "ripgrep" "starship" "tmux" "unzip" "waybar" "wget" "wl-clipboard" "wofi" "zoxide" "zsh"
    "zsh-autosuggestions" "zsh-syntax-highlighting"
)

RUN_STANDARD_LINUX_INSTALL=true

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

            PACKAGES+=("base-devel")
            PACKAGES+=("hyprland")
            PACKAGES+=("hyprpaper")
            PACKAGES+=("k9s")
            PACKAGES+=("lazydocker")
            PACKAGES+=("lazygit")
            PACKAGES+=("python")
            PACKAGES+=("python-pip")
            PACKAGES+=("qt6-wayland")
            PACKAGES+=("xdg-desktop-portal-hyprland")

            # Arch-only desktop environment additions
            # PACKAGES+=(
            #     "hypridle" "hyprlock" "base-devel"
            #     "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk" "polkit-gnome"
            #       "gnupg"
            #     "noto-fonts" "noto-fonts-emoji"
            #     "papirus-icon-theme" "gtk3" "gtk4" "qt5-wayland" "qt6-wayland"
            #     "brightnessctl" "xdg-utils" "openssh"
            # )
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

fi

section "Installing JetBrainsMono Nerd Font"

if [ "$IS_ARCH" = true ] || [ "$RUN_STANDARD_LINUX_INSTALL" = true ]; then
    log "Arch detected. Installing ttf-jetbrains-mono-nerd via pacman..."
    sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd

else
    FONT_NAME="JetBrainsMono"
    FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"

    if [ ! -d "$FONT_DIR" ]; then
        log "Debian/Fedora detected. Downloading $FONT_NAME Nerd Font manually..."
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

section "Installing TPM (Tmux Plugin Manager)"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    log "TPM installed"
else
    warn "TPM already exists"
fi

section "Bootstrapping tmux plugins"
tmux new-session -d -s _install 2>/dev/null || true
sleep 1
"$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>>"$LOG_FILE" && log "Tmux plugins installed" || warn "TPM auto-install failed — open tmux and press prefix+I"
tmux kill-session -t _install 2>/dev/null || true

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "======================================================================="
echo " System provisioning complete!"
echo " Log: $LOG_FILE"
echo "======================================================================="
