#!/bin/bash

# ============================================================================
# Prerequisites (must be true BEFORE running this script)
# ----------------------------------------------------------------------------
# Arch:
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
#   git clone https://github.com/<user>/dotfiles.git
#   ~/dotfiles/linux/setup.sh
#
# Debian:
#   - A working install booted, with a non-root user that has sudo privileges
#   - Working internet connection
#   - These packages installed via apt:  sudo build-essential curl git
#     (sudo is not always present on a minimal Debian install; build-essential
#      pulls in gcc/make/etc. needed for later source-builds; curl + git are
#      needed to fetch this repo and the release-binary installers)
#   - This repo is cloned to ~/.dotfiles, e.g.:
#       git clone --recurse-submodules https://github.com/<user>/dotfiles ~/.dotfiles
#   - Run as the target user (NOT root); the script will sudo when needed
#
# Fedora:
#   - A working install booted, with a non-root user account; sudo is
#     pre-configured for the wheel group on Fedora installs, so the user
#     created during install already has it
#   - Working internet connection
#   - These packages installed via dnf:  @development-tools git
#     (@development-tools is dnf's group install shorthand for gcc/make/
#      autoconf/etc.; git is needed to clone this repo. curl ships with the
#      base install.)
#   - This repo is cloned to ~/.dotfiles, e.g.:
#       git clone --recurse-submodules https://github.com/<user>/dotfiles ~/.dotfiles
#   - Run as the target user (NOT root); the script will sudo when needed
#
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

# install_release_binary <name> <url> <dst> [archive_type] [expected_sha256]
#
# Generic "download release artefact, optional sha256-verify, extract if
# archive, move to dst" helper shared by the chezmoi / opencode / claude /
# starship install steps. Per-tool variation (version resolution, checksum
# lookup, arch-string mapping) stays in the caller; this function only owns
# the common download → verify → extract → install pipeline.
#
#   archive_type    "tar.gz" (default) — extract first, find binary inside
#                   "binary"           — single executable, no extraction
#   expected_sha256 optional 64-char hex digest; verified before extract.
#                   Empty means "no checksum available" — the helper warns
#                   loudly so the unverified install is visible in the log.
#
# Returns 0 on success or no-op (binary already on PATH), non-zero on any
# real failure so the caller can decide whether to bail or continue.
install_release_binary() {
    local name="$1"
    local url="$2"
    local dst="$3"
    local archive_type="${4:-tar.gz}"
    local expected_sha256="${5:-}"

    if command -v "$name" >/dev/null 2>&1; then
        warn "$name already on PATH at $(command -v "$name") — skipping"
        return 0
    fi

    local tmp tmpdir bin got
    tmp=$(mktemp)
    log "Downloading $name from $url..."
    if ! curl -fsSL "$url" -o "$tmp"; then
        warn "Download failed: $url — skipping $name"
        rm -f "$tmp"
        return 1
    fi

    if [ -z "$expected_sha256" ]; then
        warn "$name installing without checksum verification (upstream publishes none)"
    else
        if [[ ! "$expected_sha256" =~ ^[a-f0-9]{64}$ ]]; then
            warn "Invalid expected sha256 for $name (got: '${expected_sha256:0:40}') — refusing install"
            rm -f "$tmp"
            return 1
        fi
        got=$(sha256sum "$tmp" | cut -d' ' -f1)
        if [ "$got" != "$expected_sha256" ]; then
            warn "$name checksum mismatch — expected $expected_sha256, got $got — refusing install"
            rm -f "$tmp"
            return 1
        fi
    fi

    mkdir -p "$(dirname "$dst")"

    case "$archive_type" in
        binary)
            chmod +x "$tmp"
            if mv "$tmp" "$dst"; then
                log "$name installed to $dst"
                return 0
            else
                warn "Failed to move $name binary to $dst"
                rm -f "$tmp"
                return 1
            fi
            ;;
        tar.gz)
            tmpdir=$(mktemp -d)
            if ! tar -xzf "$tmp" -C "$tmpdir"; then
                warn "Failed to extract $name archive"
                rm -rf "$tmp" "$tmpdir"
                return 1
            fi
            # Binary usually sits at the archive root, but some projects nest
            # it under a versioned dir — find by name to be safe.
            bin=$(find "$tmpdir" -type f -name "$name" | head -n1)
            if [ -z "$bin" ]; then
                warn "$name binary not found inside archive"
                rm -rf "$tmp" "$tmpdir"
                return 1
            fi
            chmod +x "$bin"
            if mv "$bin" "$dst"; then
                log "$name installed to $dst"
                rm -rf "$tmp" "$tmpdir"
                return 0
            else
                warn "Failed to move $name binary to $dst"
                rm -rf "$tmp" "$tmpdir"
                return 1
            fi
            ;;
        *)
            warn "install_release_binary: unknown archive_type '$archive_type' for $name"
            rm -f "$tmp"
            return 1
            ;;
    esac
}

# ============================================================================
# Shared per-distro helpers
# ============================================================================

# configure_greetd <vt> <greetd_user> [session_cmd]
# Writes /etc/greetd/config.toml, enables the service, then sanity-checks that
# the Hyprland session file and uwsm are actually present. The session command
# is uniform across distros, so it defaults — pass a third arg only to override.
configure_greetd() {
    local vt="$1" greetd_user="$2"
    local session_cmd="${3:-uwsm start hyprland.desktop}"

    section "Configuring greetd + tuigreet"
    sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = $vt

[default_session]
command = "tuigreet --time --asterisks --cmd '$session_cmd'"
user = "$greetd_user"
EOF
    sudo systemctl enable greetd.service
    log "/etc/greetd/config.toml written (vt=$vt, user=$greetd_user); greetd.service enabled"

    if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
        warn "No /usr/share/wayland-sessions/hyprland.desktop — uwsm needs this session file (shipped by the hyprland package)"
    fi
    if ! command -v uwsm &>/dev/null; then
        warn "uwsm not found on PATH — package install likely failed; re-run the ${PKG_MANAGER:-package} install step"
    fi
}

# apply_vm_console_fixes
# VM-only (caller gates on $IS_VM): put a serial console on the kernel cmdline
# so the boot is reachable over UTM's serial, and free tty1 from kmscon so
# greetd can own it. Idempotent — skips entries that already carry console=tty0.
apply_vm_console_fixes() {
    local serial_con entries_dir d entry cmdline_changed

    case "$(uname -m)" in
        aarch64) serial_con="ttyAMA0" ;;
        *)       serial_con="ttyS0" ;;
    esac

    entries_dir=""
    for d in /boot/loader/entries /efi/loader/entries /boot/efi/loader/entries; do
        if [ -d "$d" ]; then entries_dir="$d"; break; fi
    done

    if [ -n "$entries_dir" ]; then
        shopt -s nullglob
        cmdline_changed=false
        for entry in "$entries_dir"/*.conf; do
            if ! grep -q '^options ' "$entry"; then continue; fi
            if grep -q 'console=tty0' "$entry"; then
                warn "$(basename "$entry"): console=tty0 already set — skipping"
                continue
            fi
            sudo sed -i "/^options /s|\$| console=${serial_con} console=tty0|" "$entry"
            log "$(basename "$entry"): appended 'console=${serial_con} console=tty0'"
            cmdline_changed=true
        done
        shopt -u nullglob
        if [ "$cmdline_changed" != true ]; then
            warn "No type-1 systemd-boot entries with an 'options' line found (UKI/EFISTUB?)."
            warn "Add 'console=${serial_con} console=tty0' to your kernel cmdline manually."
        fi
    else
        warn "No systemd-boot entries dir found (stock Fedora/GRUB systems land here — expected)."
        warn "GRUB:  add 'console=${serial_con} console=tty0' to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub,"
        warn "       then regenerate: update-grub (Debian) / grub2-mkconfig -o /boot/grub2/grub.cfg (Fedora)."
        warn "UKI:   add it to /etc/kernel/cmdline then rebuild (mkinitcpio/ukify)."
    fi

    # Free tty1 from kmscon (not shipped on stock Fedora/Debian — checked anyway).
    if systemctl list-unit-files | grep -q 'kmsconvt@'; then
        sudo systemctl disable kmsconvt@tty1.service 2>/dev/null || true
        sudo systemctl mask kmsconvt@tty1.service
        log "Disabled and masked kmsconvt@tty1.service so greetd owns tty1"
    else
        warn "kmsconvt@tty1 not present — nothing to mask"
    fi
}

# add_user_to_graphics_groups — video/input for DRM/libinput, seat if seatd is in use.
add_user_to_graphics_groups() {
    section "Adding $USER to video,input groups"
    sudo usermod -aG video,input "$USER"
    if getent group seat &>/dev/null; then
        sudo usermod -aG seat "$USER"
    fi
}

# set_login_shell_zsh — switch the login shell to zsh unless it already is.
set_login_shell_zsh() {
    section "Setting zsh as login shell"
    if getent passwd "$USER" | grep -q '/zsh$'; then
        warn "Login shell is already zsh"
    else
        sudo chsh -s /usr/bin/zsh "$USER" && log "Login shell set to /usr/bin/zsh"
    fi
}

# enable_networkmanager — idempotent; harmless if already enabled by a preset.
enable_networkmanager() {
    section "Enabling NetworkManager"
    sudo systemctl enable NetworkManager.service
}

# Define common packages for Linux
# starship intentionally excluded — only Arch packages it; Debian/Fedora get it
# via a release-binary install in a later step.
PACKAGES=(
    "bat" "btop" "curl" "dunst" "eza" "fastfetch" "flatpak" "foot" "fzf" "git" "grim" "jq" "kitty" "make" "neovim"
    "podman" "podman-compose" "ripgrep" "slurp" "tmux" "unzip" "waybar" "wget" "wl-clipboard" "wofi" "zoxide" "zsh"
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

        debian)
            section "Configuring for Debian"
            PKG_MANAGER="apt-get"
            INSTALL_ARGS="-y install"

            # openssh-server is in the package list (not the prereqs) so that
            # remote access is available after the first reboot — useful when
            # the tui-greet screen on a fresh boot misbehaves and SSH is the
            # only way in to view logs.
            PACKAGES+=("fd-find" "greetd" "npm" "openssh-server" "python3" "python3-pip" "starship" "tuigreet")

            if [ "$IS_VM" = true ]; then
                PACKAGES+=("mesa-utils" "libgl1-mesa-dri" "spice-vdagent")
            fi

            IS_DEBIAN=true
            ;;

        fedora)
            section "Configuring for Fedora"
            PKG_MANAGER="dnf"
            INSTALL_ARGS="-y install"

            PACKAGES+=("chezmoi" "fd-find" "greetd" "nodejs24-npm" "python" "python-pip" "tuigreet")

            if [ "$IS_VM" = true ]; then
                PACKAGES+=("egl-utils" "mesa-dri-drivers" "mesa-demos" "spice-vdagent")
            fi

            # Hyprland is not in Fedora base repos. lionheartp/Hyprland COPR
            # provides it, but only builds for Fedora 43+ (and rawhide).
            if [ "$DISTRO" = "fedora" ] && [ "${VERSION_ID%%.*}" -ge 43 ] 2>/dev/null; then
                log "Enabling lionheartp/Hyprland COPR..."
                sudo dnf -y install dnf-plugins-core
                sudo dnf -y copr enable lionheartp/Hyprland

                PACKAGES+=(
                    "hyprland" "hyprpaper" "hyprlock" "hypridle" "hyprland-guiutils"
                    "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk" "polkit"
                    "qt5-qtwayland" "qt6-qtwayland" "gtk3" "gtk4"
                    "pipewire" "pipewire-pulseaudio" "wireplumber" "NetworkManager"
                    "google-noto-sans-fonts" "google-noto-emoji-fonts" "jetbrains-mono-fonts"
                    "papirus-icon-theme" "brightnessctl" "xdg-utils" "uwsm"
                )
            elif [ "$DISTRO" = "fedora" ]; then
                warn "Fedora ${VERSION_ID:-?} is older than 43 — lionheartp/Hyprland COPR has no build for this release; Hyprland packages will not be installed"
            fi

            IS_FEDORA=true
            ;;

        arch|archarm)
            section "Configuring for Arch Linux"
            PKG_MANAGER="pacman"
            INSTALL_ARGS="-S --needed --noconfirm"

            # Core tooling
            PACKAGES+=(
                "chezmoi" "fd" "greetd-tuigreet" "k9s" "lazydocker" "lazygit"
                "python" "python-pip" "gnupg" "openssh" "npm" "starship"
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
    log "Installing ${#PACKAGES[@]} package(s): ${PACKAGES[*]}"
    # Fast path: try the whole list in one transaction. If anything fails
    # (typo, dropped package on a new distro release, transient mirror issue)
    # fall back to installing one-at-a-time so we can isolate the bad entries
    # without aborting the entire provisioning run.
    if sudo $PKG_MANAGER $INSTALL_ARGS "${PACKAGES[@]}"; then
        log "All ${#PACKAGES[@]} package(s) installed successfully"
    else
        warn "Bulk install failed — retrying one-by-one to isolate failures..."
        install_failed=()
        for pkg in "${PACKAGES[@]}"; do
            if sudo $PKG_MANAGER $INSTALL_ARGS "$pkg"; then
                :
            else
                install_failed+=("$pkg")
            fi
        done
        if [ "${#install_failed[@]}" -eq 0 ]; then
            log "All ${#PACKAGES[@]} package(s) installed on retry"
        else
            warn "${#install_failed[@]}/${#PACKAGES[@]} package(s) failed permanently: ${install_failed[*]}"
            warn "Continuing with provisioning — fix package names and re-run if needed"
        fi
    fi

fi


# =============================================================================
# 3. Debian-Specific Installation Block
# =============================================================================

if [ "$IS_DEBIAN" = true ]; then

    section "Enabling trixie-backports + installing Hyprland stack"
    # Hyprland is not in Debian 13 (trixie) stable — it lives in
    # trixie-backports (0.54.x at time of writing), as do hyprpaper and uwsm.
    # Add the backports suite (deb822 format) and pull ONLY the Hyprland stack
    # from it via `-t trixie-backports`; everything else stays on stable.
    if [ "$ID" = "debian" ] && [ "${VERSION_CODENAME:-}" = "trixie" ]; then
        BACKPORTS_SOURCES="/etc/apt/sources.list.d/debian-backports.sources"
        if [ -f "$BACKPORTS_SOURCES" ] && grep -q 'trixie-backports' "$BACKPORTS_SOURCES"; then
            warn "trixie-backports already configured at $BACKPORTS_SOURCES — skipping add"
        else
            sudo tee "$BACKPORTS_SOURCES" >/dev/null <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
            log "Wrote $BACKPORTS_SOURCES"
        fi

        sudo apt-get update

        HYPR_BACKPORTS=("hyprland" "hyprland-guiutils" "hyprpaper" "uwsm")
        log "Installing from trixie-backports: ${HYPR_BACKPORTS[*]}"
        if sudo apt-get -y -t trixie-backports install "${HYPR_BACKPORTS[@]}"; then
            log "Hyprland stack installed from trixie-backports"
        else
            warn "trixie-backports install failed for one or more of: ${HYPR_BACKPORTS[*]} — check 'apt-cache policy <pkg>'"
        fi
    else
        warn "Not Debian trixie (id=$ID codename=${VERSION_CODENAME:-?}) — skipping trixie-backports Hyprland install"
    fi

    configure_greetd 7 "_greetd"

    if [ "$IS_VM" = true ]; then apply_vm_console_fixes; fi

    add_user_to_graphics_groups

    section "Installing chezmoi"

    if [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping chezmoi install"
    else
        case "$ARCH" in
            x64)   CZ_ARCH=amd64 ;;
            arm64) CZ_ARCH=arm64 ;;
        esac

        log "Resolving latest chezmoi version..."
        # Capture the full API response first, then parse — piping curl straight
        # into `grep -m1` makes grep close the pipe early, which is the curl (23)
        # "failure writing output" noise.
        cz_api=$(curl -fsSL "https://api.github.com/repos/twpayne/chezmoi/releases/latest" || true)
        cz_version=$(printf '%s' "$cz_api" | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
        if [[ ! "$cz_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            warn "No valid chezmoi version from GitHub API (got: '${cz_version:0:40}') — skipping"
        else
            cz_asset="chezmoi_${cz_version}_linux_${CZ_ARCH}.tar.gz"
            cz_base="https://github.com/twpayne/chezmoi/releases/download/v$cz_version"
            log "Latest chezmoi is $cz_version (linux-$CZ_ARCH)"

            # Pull the digest for our specific asset out of the signed
            # checksums manifest. Empty result → helper refuses to install.
            cz_sha=$(curl -fsSL "$cz_base/chezmoi_${cz_version}_checksums.txt" \
                | awk -v f="$cz_asset" '$2==f {print $1}')

            install_release_binary "chezmoi" \
                "$cz_base/$cz_asset" \
                "$HOME/.local/bin/chezmoi" \
                "tar.gz" \
                "$cz_sha"
        fi
    fi

    set_login_shell_zsh

    section "Setting up bat symlink"
    if command -v batcat >/dev/null 2>&1; then
        if [ ! -e "$HOME/.local/bin/bat" ]; then
            ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
            log "Created bat -> batcat symlink"
        else
            warn "bat symlink already present"
        fi
    fi

    section "Masking packaged waybar.service user unit"
    # Debian's waybar package ships an enabled waybar.service user unit, so on a
    # uwsm/systemd login it starts a second bar on top of the one the Hyprland
    # Lua config launches (exec -> /bin/sh -c waybar). Mask the user unit so the
    # config is the single source of truth. Done as a /dev/null symlink rather
    # than `systemctl --user mask` so it works even when this script runs without
    # an active user bus (e.g. over SSH during provisioning). Arch/Fedora don't
    # ship this unit.
    if [ -e /usr/lib/systemd/user/waybar.service ]; then
        mkdir -p "$HOME/.config/systemd/user"
        ln -sf /dev/null "$HOME/.config/systemd/user/waybar.service"
        log "Masked user waybar.service (Hyprland config owns the bar) — effective next login"
        # If a user bus happens to be reachable, also stop any running instance
        # and reload so the mask takes effect now rather than on next login.
        if systemctl --user show-environment &>/dev/null; then
            systemctl --user stop waybar.service 2>/dev/null || true
            systemctl --user daemon-reload 2>/dev/null || true
        fi
    else
        warn "No packaged waybar.service user unit at /usr/lib/systemd/user — nothing to mask"
    fi
fi

# =============================================================================
# 3. Arch-Specific Installation Block
# =============================================================================

if [ "$IS_ARCH" = true ]; then

    enable_networkmanager

    configure_greetd 1 "greeter"

    if [ "$IS_VM" = true ]; then apply_vm_console_fixes; fi

    add_user_to_graphics_groups

    set_login_shell_zsh
fi

# =============================================================================
# 3.c Fedora-Specific Installation Block
# =============================================================================

if [ "$IS_FEDORA" = true ]; then

    enable_networkmanager

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

    # Fedora's greetd package creates a `greetd` system user (not `greeter`);
    # vt 1. Wrong user => greetd starts, fails to drop privileges, then exits
    # (shows as "active (running)" briefly, then "inactive (dead)").
    configure_greetd 1 "greetd"

    # Minimal Fedora boots to multi-user.target — assert graphical so greetd runs.
    current_target="$(systemctl get-default)"
    if [ "$current_target" = "graphical.target" ]; then
        log "Default target already graphical.target"
    else
        sudo systemctl set-default graphical.target
        log "Default target set to graphical.target (was $current_target)"
    fi

    if [ "$IS_VM" = true ]; then apply_vm_console_fixes; fi

    add_user_to_graphics_groups

    set_login_shell_zsh
fi

# =============================================================================
# 4. Open source system configuration (Runs on standard non-NixOS Linux distros)
# =============================================================================

# Arch installs all required Nerd Fonts via pacman as part of the main package
# list above. Debian/Fedora have no equivalent repo packages, so download the
# Nerd Font release zips manually.
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

    if [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping opencode install"
    else
        # opencode publishes /latest/download/ URLs but no signed checksums
        # file alongside the release artefacts. The helper will warn loudly
        # about the unverified install rather than silently shipping the bytes.
        install_release_binary "opencode" \
            "https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-${ARCH}.tar.gz" \
            "$HOME/.local/bin/opencode" \
            "tar.gz"
    fi

    section "Installing Claude Code CLI"

    if [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping Claude Code install"
    else
        cc_base="https://downloads.claude.ai/claude-code-releases"
        cc_platform="linux-${ARCH}"

        log "Resolving latest Claude Code version..."
        cc_version=$(curl -fsSL "$cc_base/latest" || true)
        if [[ ! "$cc_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            warn "No valid version from $cc_base/latest (got: '${cc_version:0:40}') — skipping"
        else
            log "Latest Claude Code is $cc_version ($cc_platform)"
            cc_manifest=$(curl -fsSL "$cc_base/$cc_version/manifest.json" || true)
            cc_sha=$(printf '%s' "$cc_manifest" | jq -r ".platforms[\"$cc_platform\"].checksum // empty")

            # Claude ships as a single executable, not a tarball — pass the
            # "binary" archive_type so the helper skips extraction.
            install_release_binary "claude" \
                "$cc_base/$cc_version/$cc_platform/claude" \
                "$HOME/.local/bin/claude" \
                "binary" \
                "$cc_sha"
        fi
    fi

    section "Installing starship prompt"

    # No-op on Arch (pacman) and Debian (apt) where starship is in repos —
    # the helper's command -v check short-circuits. Fedora repos lack it, so
    # this is where Fedora actually fetches the release tarball.
    if [ -z "$ARCH" ]; then
        warn "No supported architecture detected — skipping starship install"
    else
        case "$ARCH" in
            x64)   ss_target="x86_64-unknown-linux-gnu" ;;
            arm64) ss_target="aarch64-unknown-linux-musl" ;;
        esac

        log "Resolving latest starship version..."
        ss_api=$(curl -fsSL "https://api.github.com/repos/starship/starship/releases/latest" || true)
        ss_version=$(printf '%s' "$ss_api" | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
        if [[ ! "$ss_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            warn "No valid starship version from GitHub API (got: '${ss_version:0:40}') — skipping"
        else
            ss_asset="starship-${ss_target}.tar.gz"
            ss_base="https://github.com/starship/starship/releases/download/v$ss_version"
            log "Latest starship is $ss_version ($ss_target)"

            ss_sha=$(curl -fsSL "$ss_base/$ss_asset.sha256" 2>/dev/null | awk '{print $1}')

            install_release_binary "starship" \
                "$ss_base/$ss_asset" \
                "$HOME/.local/bin/starship" \
                "tar.gz" \
                "$ss_sha"
        fi
    fi
fi

# =============================================================================
# 5. Independent Tools (Runs everywhere, including macOS/NixOS if applicable)
# =============================================================================

# Chezmoi dotfiles bootstrap
# Arch/Fedora install chezmoi via pacman/dnf to /usr/bin/chezmoi (always on
# PATH). Debian installs it via the release-binary step above to
# ~/.local/bin/chezmoi — and that directory is NOT on PATH yet, because the
# .zshenv that adds it is itself one of the dotfiles `chezmoi apply` is about
# to lay down. Resolve the binary explicitly to dodge the chicken-and-egg.
section "Applying dotfiles via chezmoi"

# GitHub username hosting the dotfiles repo. `chezmoi init --apply <user>`
# clones it into chezmoi's source dir and applies in one step, so the local
# ~/dotfiles checkout isn't required on a fresh VM.
GITHUB_USER="jeff-tooke"

if [ "$IS_DEBIAN" = true ]; then
    CHEZMOI_BIN="$HOME/.local/bin/chezmoi"
else
    CHEZMOI_BIN="$(command -v chezmoi || true)"
fi

# if [ -z "$CHEZMOI_BIN" ] || [ ! -x "$CHEZMOI_BIN" ]; then
#     warn "chezmoi not found (looked for: ${CHEZMOI_BIN:-<nothing on PATH>}) — skipping dotfiles apply"
# else
#     if [ ! -d "$HOME/.local/share/chezmoi" ]; then
#         "$CHEZMOI_BIN" init --apply "$GITHUB_USER"
#     else
#         log "chezmoi already initialised — running apply"
#         "$CHEZMOI_BIN" apply
#     fi
# fi

# Previous local-source flow — kept for reference if you want to point chezmoi
# at a working copy under ~/dotfiles instead of the GitHub remote:
#
if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    "$CHEZMOI_BIN" init --source "$HOME/dotfiles"
else
    log "chezmoi already initialised — skipping init"
fi
"$CHEZMOI_BIN" apply --source "$HOME/dotfiles"

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
