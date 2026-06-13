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
# Arch first-boot bootstrap — run ONCE as root if sudo/git are missing
# (typical on a fresh archinstall before any user provisioning):
#
#   # 1. Switch to the root account (use the root password set in archinstall)
#   su -
#
#   # 2. Install the bare minimum needed to run this script
#   pacman -Sy --needed sudo git base-devel
#
#   # 3. Add your existing user to the wheel group (archinstall always
#   #    creates a user, but does not always add them to wheel).
#   #    Replace <user> with your username.
#   usermod -aG wheel <user>
#
#   # 4. Allow members of the wheel group to use sudo.
#   #    Uncomment the line:  %wheel ALL=(ALL:ALL) ALL
#   EDITOR=nano visudo
#
#   # 5. Drop back to your user, clone the dotfiles, run the script.
#   exit                    # leave the root shell
#   su - <user>             # log in as your user (or just reboot + log in)
#   git clone --recurse-submodules https://github.com/<user>/dotfiles ~/.dotfiles
#   bash ~/.dotfiles/linux/setup.sh
#
# Debian/Ubuntu/Fedora/RHEL: a working install with sudo + curl + git.
# macOS: a fresh user account; Xcode CLI tools + Homebrew will be installed.
# ============================================================================

set -eE

echo "Starting system provisioning..."

LOG_FILE="$HOME/system-setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

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
IS_VM=false

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

  # --- VM detection -------------------------------------------------------
    # systemd-detect-virt returns 0 (and prints the hypervisor) inside a guest,
    # non-zero on bare metal. Gate all guest-only steps on this so a hardware
    # install is never touched by the VM display fixes below.
    if command -v systemd-detect-virt &>/dev/null && systemd-detect-virt --quiet; then
        IS_VM=true
        log "Hypervisor detected ($(systemd-detect-virt)) — VM-specific steps will run"
    else
        log "No hypervisor detected — treating as bare metal"
    fi

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

           if [ "$IS_VM" = true ]; then
                PACKAGES+=("mesa-utils" "libgl1-mesa-dri")
            fi
            ;;

        fedora|rhel|centos|rocky|almalinux)
            section "Configuring for Fedora/RHEL"
            PKG_MANAGER="dnf"
            INSTALL_ARGS="-y install"

            PACKAGES+=("@Development Tools")
            PACKAGES+=("python")
            PACKAGES+=("python-pip")

            if [ "$IS_VM" = true ]; then
                PACKAGES+=("mesa-dri-drivers" "mesa-demos")
            fi
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
            #   fonts/icons, misc desktop glue, uwsm session manager.
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
                "uwsm"
            )

            if [ "$IS_VM" = true ]; then
                log "VM detected — adding mesa + mesa-utils for virtio-gpu GL"
                PACKAGES+=("mesa" "mesa-utils")
            fi

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

    # -----------------------------------------------------------------------
    # Arch: Desktop services (greetd + NetworkManager + group membership)
    # -----------------------------------------------------------------------
    section "Enabling NetworkManager"
    sudo systemctl enable NetworkManager.service

    section "Configuring greetd + tuigreet (uwsm-managed Hyprland session)"
    sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --cmd 'uwsm start hyprland.desktop'"
user = "greeter"
EOF
    sudo systemctl enable greetd.service
    log "/etc/greetd/config.toml written; greetd.service enabled"

    if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
        warn "No /usr/share/wayland-sessions/hyprland.desktop — uwsm needs this session file (shipped by the hyprland package)"
    fi
    if ! command -v uwsm &>/dev/null; then
        warn "uwsm not found on PATH — package install likely failed; re-run the pacman step"
    fi

 if [ "$IS_VM" = true ]; then

        # 1) Kernel console: make tty0 a console so the greeter renders on the
        #    virtio-gpu display (systemd-boot type-1 entries only).
        case "$(uname -m)" in
            aarch64) SERIAL_CON="ttyAMA0" ;;
            *)       SERIAL_CON="ttyS0" ;;
        esac

        ENTRIES_DIR=""
        for d in /boot/loader/entries /efi/loader/entries /boot/efi/loader/entries; do
            if [ -d "$d" ]; then ENTRIES_DIR="$d"; break; fi
        done

        if [ -n "$ENTRIES_DIR" ]; then
            shopt -s nullglob
            cmdline_changed=false
            for entry in "$ENTRIES_DIR"/*.conf; do
                if ! grep -q '^options ' "$entry"; then continue; fi
                if grep -q 'console=tty0' "$entry"; then
                    warn "$(basename "$entry"): console=tty0 already set — skipping"
                    continue
                fi
                sudo sed -i "/^options /s|\$| console=${SERIAL_CON} console=tty0|" "$entry"
                log "$(basename "$entry"): appended 'console=${SERIAL_CON} console=tty0'"
                cmdline_changed=true
            done
            shopt -u nullglob
            if [ "$cmdline_changed" != true ]; then
                warn "No type-1 systemd-boot entries with an 'options' line found (UKI/EFISTUB?)."
                warn "Add 'console=${SERIAL_CON} console=tty0' to your kernel cmdline manually."
            fi
        else
            warn "No systemd-boot entries dir found."
            warn "GRUB: add 'console=${SERIAL_CON} console=tty0' to GRUB_CMDLINE_LINUX_DEFAULT then regenerate grub.cfg."
            warn "UKI:  add it to /etc/kernel/cmdline then rebuild (mkinitcpio/ukify)."
        fi

        # 2) Stop kmscon stealing tty1 from greetd.
        if systemctl list-unit-files | grep -q 'kmsconvt@'; then
            sudo systemctl disable --now kmsconvt@tty1.service 2>/dev/null || true
            sudo systemctl mask kmsconvt@tty1.service
            log "Masked kmsconvt@tty1.service so greetd owns tty1"
        else
            warn "kmsconvt@tty1 not present — nothing to mask (good)"
        fi
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
  1. Reboot. tuigreet should appear on tty1; logging in launches Hyprland
     via 'uwsm start hyprland.desktop' as a managed systemd user session.
  2. Once the desktop is verified, uncomment the chezmoi block in this
     script and re-run to deploy dotfiles to ~/.config.
  3. After chezmoi apply, uncomment the TPM block and re-run to install
     tmux plugins.

EOF
fi
