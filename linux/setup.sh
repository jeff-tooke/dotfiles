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
    "alacritty" "bat" "btop" "curl" "dunst" "eza" "fastfetch" "flatpak" "foot" "fzf" "git" "grim" "jq" "kitty" "make" "neovim"
    "podman" "podman-compose" "ripgrep" "slurp" "starship" "tmux" "unzip" "waybar" "wget" "wl-clipboard" "wofi" "zoxide" "zsh"
    "zsh-autosuggestions" "zsh-syntax-highlighting"
)

RUN_STANDARD_LINUX_INSTALL=true
IS_ARCH=false
IS_DEBIAN=false
IS_FEDORA=false
IS_VM=false

# --- Architecture detection ------------------------------------------------
# Normalize uname output into release-artifact form (x64 / arm64). Used by
# any step that downloads architecture-specific binaries (opencode CLI etc.).
# Empty $ARCH means "unsupported" — downstream steps should skip cleanly.
case "$(uname -m)" in
    x86_64|amd64)  ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)             ARCH="" ;;
esac
if [ -n "$ARCH" ]; then
    log "Detected architecture: $ARCH ($(uname -m))"
else
    warn "Unsupported architecture: $(uname -m) — arch-specific downloads will be skipped"
fi

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

            PACKAGES+=("build-essential" "fd-find" "greetd" "npm" "python3" "python3-pip" "tuigreet")

            if [ "$IS_VM" = true ]; then
                PACKAGES+=("mesa-utils" "libgl1-mesa-dri" "spice-vdagent")
            fi

            IS_DEBIAN=true
            ;;

        fedora|rhel|centos|rocky|almalinux)
            section "Configuring for Fedora/RHEL"
            PKG_MANAGER="dnf"
            INSTALL_ARGS="-y install"

            PACKAGES+=("@Development Tools" "chezmoi" "fd-find" "greetd" "nodejs24-npm" "python" "python-pip" "tuigreet")

            if [ "$IS_VM" = true ]; then
                PACKAGES+=("mesa-dri-drivers" "mesa-demos" "spice-vdagent")
            fi

            # Hyprland is not in Fedora base repos. lionheartp/Hyprland COPR
            # provides it, but only builds for Fedora 43+ (and rawhide).
            # COPR is Fedora-only — skip on RHEL/CentOS clones.
            if [ "$DISTRO" = "fedora" ] && [ "${VERSION_ID%%.*}" -ge 43 ] 2>/dev/null; then
                log "Enabling lionheartp/Hyprland COPR..."
                sudo dnf -y install dnf-plugins-core
                sudo dnf -y copr enable lionheartp/Hyprland

                PACKAGES+=(
                    "hyprland" "hyprpaper" "hyprlock" "hypridle"
                    "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
                    "polkit" "polkit-gnome"
                    "qt5-qtwayland" "qt6-qtwayland" "gtk3" "gtk4"
                    "pipewire" "pipewire-pulseaudio" "wireplumber"
                    "NetworkManager"
                    "google-noto-sans-fonts" "google-noto-emoji-fonts"
                    "jetbrains-mono-fonts" "papirus-icon-theme"
                    "brightnessctl" "xdg-utils"
                    "uwsm"
                )
            elif [ "$DISTRO" = "fedora" ]; then
                warn "Fedora ${VERSION_ID:-?} is older than 43 — lionheartp/Hyprland COPR has no build for this release; Hyprland packages will not be installed"
            fi

            IS_FEDORA=true
            ;;

        arch|archarm|cachyos|manjaro)
            section "Configuring for Arch Linux"
            PKG_MANAGER="pacman"
            INSTALL_ARGS="-S --needed --noconfirm"

            # Core tooling
            PACKAGES+=(
                "base-devel" "chezmoi" "fd" "greetd-tuigreet" "k9s" "lazydocker" "lazygit"
                "python" "python-pip" "gnupg" "openssh" "npm"
            )

            # Hyprland desktop minimal set:
            PACKAGES+=(
                "hyprland" "hyprpaper" "hyprlock" "hypridle"
                "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
                "polkit" "polkit-gnome"
                "qt5-wayland" "qt6-wayland" "gtk3" "gtk4"
                "pipewire" "pipewire-pulse" "wireplumber"
                "networkmanager"
                "noto-fonts" "noto-fonts-emoji" "ttf-jetbrains-mono-nerd"
                "ttf-meslo-nerd" "ttf-nerd-fonts-symbols" "papirus-icon-theme"
                "brightnessctl" "xdg-utils"
                "uwsm"
            )

            if [ "$IS_VM" = true ]; then
                log "VM detected — adding mesa + mesa-utils for virtio-gpu GL"
                PACKAGES+=("mesa" "mesa-utils" "spice-vdagent")
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
# 3. Debian-Specific Installation Block
# =============================================================================

if [ "$IS_DEBIAN" = true ]; then

    section "Configuring greetd + tuigreet"
    sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --asterisks --cmd 'zsh -l'"
user = "_greetd"
EOF
    sudo systemctl enable greetd.service
    log "/etc/greetd/config.toml written; greetd.service enabled"


    if [ "$IS_VM" = true ]; then

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
            sudo systemctl disable kmsconvt@tty1.service 2>/dev/null || true
            sudo systemctl mask kmsconvt@tty1.service
            log "Disabled and masked kmsconvt@tty1.service so greetd owns tty1"
        else
            warn "kmsconvt@tty1 not present — nothing to mask"
        fi
    fi

    section "Adding $USER to video,input groups"
    sudo usermod -aG video,input "$USER"
    if getent group seat &>/dev/null; then
        sudo usermod -aG seat "$USER"
    fi

    section "Installing chezmoi"

    if command -v chezmoi >/dev/null 2>&1; then
        warn "chezmoi already on PATH at $(command -v chezmoi) — skipping"
    elif [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping chezmoi install"
    else
        case "$ARCH" in
            x64)   CZ_ARCH=amd64 ;;
            arm64) CZ_ARCH=arm64 ;;
        esac

        CZ_REPO="twpayne/chezmoi"
        CZ_DST="$HOME/.local/bin/chezmoi"

        log "Resolving latest chezmoi version..."
        # Capture the full API response first, then parse — piping curl straight
        # into `grep -m1` makes grep close the pipe early, which is the curl (23)
        # "failure writing output" noise you saw.
        cz_api=$(curl -fsSL "https://api.github.com/repos/$CZ_REPO/releases/latest" || true)
        cz_version=$(printf '%s' "$cz_api" | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
        if [[ ! "$cz_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            warn "No valid chezmoi version from GitHub API (got: '${cz_version:0:40}') — skipping"
        else
            CZ_ASSET="chezmoi_${cz_version}_linux_${CZ_ARCH}.tar.gz"
            CZ_BASE="https://github.com/$CZ_REPO/releases/download/v$cz_version"
            log "Latest is $cz_version (linux-$CZ_ARCH)"

            tmptar=$(mktemp --suffix=.tar.gz)
            tmpdir=$(mktemp -d)
            log "Downloading chezmoi $cz_version ($CZ_ASSET)..."
            if ! curl -fsSL "$CZ_BASE/$CZ_ASSET" -o "$tmptar"; then
                warn "Download failed: $CZ_BASE/$CZ_ASSET — asset name may have changed — skipping"
            else
                # --- integrity check against signed checksums manifest ---------
                want=$(curl -fsSL "$CZ_BASE/chezmoi_${cz_version}_checksums.txt" \
                    | awk -v f="$CZ_ASSET" '$2==f {print $1}')
                got=$(sha256sum "$tmptar" | cut -d' ' -f1)
                if [[ ! "$want" =~ ^[a-f0-9]{64}$ ]]; then
                    warn "No checksum entry for $CZ_ASSET — refusing install"
                elif [ "$got" != "$want" ]; then
                    warn "Checksum mismatch — expected $want, got $got — refusing install"
                elif ! tar -xzf "$tmptar" -C "$tmpdir"; then
                    warn "Failed to extract $CZ_ASSET"
                else
                    # binary sits at the archive root; find it to be safe
                    czbin=$(find "$tmpdir" -type f -name chezmoi | head -n1)
                    if [ -n "$czbin" ]; then
                        chmod +x "$czbin"
                        mkdir -p "$(dirname "$CZ_DST")"
                        mv "$czbin" "$CZ_DST" \
                            && log "chezmoi installed to $CZ_DST" \
                            || warn "Failed to move chezmoi binary to $CZ_DST"
                    else
                        warn "chezmoi binary not found inside $CZ_ASSET"
                    fi
                fi
            fi
            rm -rf "$tmptar" "$tmpdir"
        fi
    fi

    section "Setting zsh as login shell"
    if getent passwd "$USER" | grep -q '/zsh$'; then
        warn "Login shell is already zsh"
    else
        sudo chsh -s /usr/bin/zsh "$USER" && log "Login shell set to /usr/bin/zsh"
    fi

    section "Setting up bat symlink"
    if command -v batcat >/dev/null 2>&1; then
        if [ ! -e "$HOME/.local/bin/bat" ]; then
            ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
            log "Created bat -> batcat symlink"
        else
            warn "bat symlink already present"
        fi
    fi
fi

# =============================================================================
# 3. Arch-Specific Installation Block
# =============================================================================

if [ "$IS_ARCH" = true ]; then

    section "Enabling NetworkManager"
    sudo systemctl enable NetworkManager.service

    section "Configuring greetd + tuigreet"
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
            sudo systemctl disable kmsconvt@tty1.service 2>/dev/null || true
            sudo systemctl mask kmsconvt@tty1.service
            log "Disabled and masked kmsconvt@tty1.service so greetd owns tty1"
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
fi

# =============================================================================
# 3.c Fedora-Specific Installation Block
# =============================================================================

if [ "$IS_FEDORA" = true ]; then

    section "Enabling NetworkManager"
    # NetworkManager is enabled by Fedora's default preset, but `systemctl
    # enable` is idempotent — re-running is harmless.
    sudo systemctl enable NetworkManager.service

    section "Checking SELinux status"
    # Fedora ships SELinux enforcing by default. greetd + uwsm + hyprland
    # (third-party COPR) is a combination that can hit AVC denials on first
    # login. We don't auto-flip the mode — just leave the user a breadcrumb.
    if command -v getenforce &>/dev/null; then
        case "$(getenforce 2>/dev/null)" in
            Enforcing)
                warn "SELinux is enforcing — greetd/uwsm/hyprland may hit AVC denials on first login"
                warn "If login fails, try 'sudo setenforce 0' first, then inspect /var/log/audit/audit.log"
                warn "Permanent: set SELINUX=permissive in /etc/selinux/config"
                ;;
            Permissive) log "SELinux is permissive" ;;
            Disabled)   log "SELinux is disabled" ;;
        esac
    else
        log "SELinux tools not present — assuming not in use"
    fi

    section "Configuring greetd + tuigreet"
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
        warn "uwsm not found on PATH — package install likely failed; re-run the dnf step"
    fi

    if [ "$IS_VM" = true ]; then

        case "$(uname -m)" in
            aarch64) SERIAL_CON="ttyAMA0" ;;
            *)       SERIAL_CON="ttyS0" ;;
        esac

        # Fedora defaults to GRUB, so the systemd-boot entries search will
        # usually fall through to the GRUB warn-branch below — that is the
        # correct outcome on a stock Fedora install.
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
            warn "No systemd-boot entries dir found (expected on stock Fedora — uses GRUB)."
            warn "GRUB: add 'console=${SERIAL_CON} console=tty0' to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub,"
            warn "      then: sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
        fi

        # Stop kmscon stealing tty1 from greetd. Fedora doesn't ship kmscon
        # by default, but check anyway in case it was installed.
        if systemctl list-unit-files | grep -q 'kmsconvt@'; then
            sudo systemctl disable kmsconvt@tty1.service 2>/dev/null || true
            sudo systemctl mask kmsconvt@tty1.service
            log "Disabled and masked kmsconvt@tty1.service so greetd owns tty1"
        else
            warn "kmsconvt@tty1 not present — nothing to mask"
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

    # Fedora ships `bat` as /usr/bin/bat directly — no batcat rename, no
    # symlink needed (unlike Debian which renames to avoid a binary clash).
fi

# =============================================================================
# 4. Open source system configuration (Runs on standard non-NixOS Linux distros)
# =============================================================================

# Arch installs all required Nerd Fonts via pacman as part of the main package
# list above. Debian/Fedora have no equivalent repo packages, so download the
# Nerd Font release zips manually. Each name below matches the archive name
# under https://github.com/ryanoasis/nerd-fonts/releases/latest/download/.
if [ "$IS_ARCH" != true ] && [ "$RUN_STANDARD_LINUX_INSTALL" = true ]; then
    section "Installing Nerd Fonts (manual)"

    NERD_FONTS=("JetBrainsMono" "Meslo" "NerdFontsSymbolsOnly")
    FONTS_INSTALLED=false

    for FONT_NAME in "${NERD_FONTS[@]}"; do
        FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"

        if [ -d "$FONT_DIR" ]; then
            warn "$FONT_NAME Nerd Font already installed in $FONT_DIR — skipping"
            continue
        fi

        log "Downloading $FONT_NAME Nerd Font..."
        mkdir -p "$FONT_DIR"

        TEMP_ZIP=$(mktemp)
        if ! curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip" -o "$TEMP_ZIP"; then
            warn "Failed to download $FONT_NAME Nerd Font — skipping"
            rm -f "$TEMP_ZIP"
            rmdir "$FONT_DIR" 2>/dev/null || true
            continue
        fi
        unzip -qo "$TEMP_ZIP" -d "$FONT_DIR"
        rm -f "$TEMP_ZIP"

        log "$FONT_NAME installed."
        FONTS_INSTALLED=true
    done

    if [ "$FONTS_INSTALLED" = true ]; then
        log "Rebuilding font cache..."
        fc-cache -f > /dev/null
        log "Font cache rebuilt."
    fi
fi

if [ "$RUN_STANDARD_LINUX_INSTALL" = true ]; then

    section "Configure wallpapers"
    # Resolve source relative to the script, not CWD, so the script works no
    # matter where it is invoked from. The on-disk dir is 'wallpaper' (singular).
    WALLPAPER_SRC="$(cd "$(dirname "$0")" && pwd)/wallpaper"
    WALLPAPER_DST="$HOME/.local/share/wallpaper"

    if [ ! -d "$WALLPAPER_SRC" ]; then
        warn "Wallpaper source $WALLPAPER_SRC not found — skipping wallpaper copy"
    else
        log "Copying wallpapers from $WALLPAPER_SRC to $WALLPAPER_DST..."
        mkdir -p "$WALLPAPER_DST"
        if cp -r "$WALLPAPER_SRC"/. "$WALLPAPER_DST"/ 2>>"$LOG_FILE"; then
            log "Wallpapers copied successfully"
        else
            warn "Failed to copy wallpapers from $WALLPAPER_SRC — continuing"
        fi
    fi

    section "Installing applications for user only"
    FLATPAK_APPS=(
      ai.opencode.opencode
      com.bitwarden.desktop
      app.zen_browser.zen
    )

    if ! command -v flatpak &>/dev/null; then
        err "flatpak command not found — distro package install likely failed; re-run the package step"
    fi

    log "Adding Flathub remote (user scope) if missing..."
    if flatpak remote-list --user | grep -q '^flathub'; then
        warn "Flathub remote already configured for $USER — skipping add"
    else
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
            && log "Flathub remote added for $USER" \
            || err "Failed to add Flathub remote"
    fi

    log "Installing ${#FLATPAK_APPS[@]} flatpak app(s): ${FLATPAK_APPS[*]}"
    flatpak_failed=()
    for APP in "${FLATPAK_APPS[@]}"; do
        log "Installing flatpak: $APP..."
        if flatpak install --user -y --noninteractive flathub "$APP" 2>>"$LOG_FILE"; then
            log "Installed flatpak: $APP"
        else
            warn "Failed to install flatpak: $APP — install manually with 'flatpak install --user flathub $APP'"
            flatpak_failed+=("$APP")
        fi
    done

    if [ "${#flatpak_failed[@]}" -eq 0 ]; then
        log "All ${#FLATPAK_APPS[@]} flatpak app(s) installed successfully"
    else
        warn "${#flatpak_failed[@]}/${#FLATPAK_APPS[@]} flatpak install(s) failed: ${flatpak_failed[*]}"
    fi

    section "Installing opencode CLI"

    if command -v opencode >/dev/null 2>&1; then
        warn "opencode already on PATH at $(command -v opencode) — skipping"
    elif [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping opencode install"
    else
        OC_ASSET="opencode-linux-${ARCH}.tar.gz"   # tar.gz on Linux (zip is macOS-only)
        OC_URL="https://github.com/anomalyco/opencode/releases/latest/download/${OC_ASSET}"
        OC_DST="$HOME/.local/bin/opencode"

        tmptar=$(mktemp --suffix=.tar.gz)
        tmpdir=$(mktemp -d)
        log "Downloading opencode ($OC_ASSET)..."
        if curl -fsSL "$OC_URL" -o "$tmptar"; then
            if tar -xzf "$tmptar" -C "$tmpdir"; then
                # binary may sit at the archive root or under a subdir — find it
                ocbin=$(find "$tmpdir" -type f -name opencode | head -n1)
                if [ -n "$ocbin" ]; then
                    chmod +x "$ocbin"
                    mkdir -p "$(dirname "$OC_DST")"
                    mv "$ocbin" "$OC_DST" \
                        && log "opencode installed to $OC_DST" \
                        || warn "Failed to move opencode binary to $OC_DST"
                else
                    warn "opencode binary not found inside $OC_ASSET"
                fi
            else
                warn "Failed to extract $OC_ASSET"
            fi
        else
            warn "Download failed: $OC_URL — asset name may have changed"
        fi
        rm -rf "$tmptar" "$tmpdir"
    fi

    section "Installing Claude Code CLI"

    if command -v claude >/dev/null 2>&1; then
        warn "claude already on PATH at $(command -v claude) — skipping"
    elif [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping Claude Code install"
    else
        CC_BASE="https://downloads.claude.ai/claude-code-releases"
        cc_platform="linux-${ARCH}"

        log "Resolving latest Claude Code version..."
        cc_version=$(curl -fsSL "$CC_BASE/latest" || true)
        if [[ ! "$cc_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            warn "No valid version from $CC_BASE/latest (got: '${cc_version:0:40}') — skipping"
        else
            log "Latest is $cc_version ($cc_platform)"
            manifest=$(curl -fsSL "$CC_BASE/$cc_version/manifest.json" || true)
            want=$(printf '%s' "$manifest" | jq -r ".platforms[\"$cc_platform\"].checksum // empty")

            if [[ ! "$want" =~ ^[a-f0-9]{64}$ ]]; then
                warn "Platform $cc_platform not found in manifest — skipping"
            else
                tmp=$(mktemp)
                log "Downloading Claude Code $cc_version ($cc_platform)..."
                if ! curl -fsSL "$CC_BASE/$cc_version/$cc_platform/claude" -o "$tmp"; then
                    warn "Download failed from $CC_BASE/$cc_version/$cc_platform/claude — skipping"
                    rm -f "$tmp"
                else
                    got=$(sha256sum "$tmp" | cut -d' ' -f1)
                    if [ "$got" != "$want" ]; then
                        warn "Checksum mismatch — expected $want, got $got — refusing install"
                        rm -f "$tmp"
                    else
                        chmod +x "$tmp"

                        CC_DST="$HOME/.local/bin/claude"
                        mkdir -p "$(dirname "$CC_DST")"
                        if mv "$tmp" "$CC_DST"; then
                            log "Claude Code installed to $CC_DST"
                        else
                            warn "Failed to move binary to $CC_DST"
                            rm -f "$tmp"
                        fi
                    fi
                fi
            fi
        fi
    fi
fi

# =============================================================================
# 5. Independent Tools (Runs everywhere, including macOS/NixOS if applicable)
# =============================================================================

# Chezmoi dotfiles bootstrap
section "Applying dotfiles via chezmoi"
if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    $HOME/.local/bin/chezmoi init --source "$HOME/dotfiles"
else
    log "chezmoi already initialised — skipping init"
fi
$HOME/.local/bin/chezmoi apply --source "$HOME/dotfiles"

# TPM bootstrap. install_plugins is a no-op unless the tmux config (applied
# above via chezmoi) lists plugins for TPM to manage.
section "Installing TPM (Tmux Plugin Manager)"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    log "TPM installed"
else
    warn "TPM already exists"
fi

section "Bootstrapping tmux plugins"
if [ -f "$HOME/.config/tmux/tmux.conf" ] || [ -f "$HOME/.tmux.conf" ]; then
    "$TPM_DIR/bin/install_plugins" 2>>"$LOG_FILE" \
        && log "Tmux plugins installed" \
        || warn "TPM auto-install failed — open tmux and press prefix+I"
else
    warn "No tmux.conf found — skipping plugin install. Re-run after chezmoi apply."
fi

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "======================================================================="
echo " System provisioning complete!"
echo " Log: $LOG_FILE"
echo "======================================================================="
