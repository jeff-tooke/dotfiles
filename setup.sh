#!/bin/bash
# ============================================================================
# Cross-platform provisioning entry point.
# ----------------------------------------------------------------------------
# Detects the OS, sets up logging + a persistent sudo session, then dispatches
# to the matching module under setup/os/:
#
#   macOS  -> setup/os/macos.sh
#   NixOS  -> setup/os/nixos.sh   (placeholder; managed via configuration.nix)
#   Linux  -> setup/os/linux.sh   (Arch / Debian / Fedora)
#
# Shared helpers live in setup/lib/common.sh; per-distro package lists in
# setup/packages/*.txt (macOS uses setup/package-management/Brewfile).
#
# Run as the target user (NOT root); the script sudos when needed.
# Per-platform PREREQUISITES (Xcode bootstrap on macOS, sudo/build tools on
# Linux) are documented in macos/README.md and linux/README.md — read them
# before running on a fresh machine.
# ============================================================================

set -eE

echo "Starting system provisioning..."

# Asset root: where this script + setup/ live. Resolving from the script's own
# location works whether the repo is at ~/.dotfiles (macOS) or ~/dotfiles
# (Linux). Doubles as the local chezmoi source today (see CHEZMOI_* below); the
# two diverge once provisioning moves to a standalone system-builder repo.
SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"

LOG_FILE="$HOME/system-setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- chezmoi dotfiles source -----------------------------------------------
# local  : apply from a local checkout ($CHEZMOI_LOCAL_SOURCE, = repo root)
# remote : clone + apply straight from GitHub (chezmoi init --apply $GITHUB_USER)
# Stays on `local` until the dotfiles repo is split out of this one. Override by
# exporting CHEZMOI_SOURCE_MODE=remote before running.
CHEZMOI_SOURCE_MODE="${CHEZMOI_SOURCE_MODE:-local}"
CHEZMOI_LOCAL_SOURCE="${CHEZMOI_LOCAL_SOURCE:-$SETUP_DIR}"
GITHUB_USER="${GITHUB_USER:-jeff-tooke}"

# shellcheck source=setup/lib/common.sh
. "$SETUP_DIR/setup/lib/common.sh"

log "Setup asset dir: $SETUP_DIR"

# --- Acquire sudo up front and keep it alive for the whole run -------------
section "Acquiring sudo (kept alive for the run)"
start_sudo_keepalive

# --- Detect OS and dispatch ------------------------------------------------
if [[ "$OSTYPE" == darwin* ]]; then
    DISTRO="macos"
    log "Detected macOS — dispatching to setup/os/macos.sh"
    # shellcheck source=setup/os/macos.sh
    . "$SETUP_DIR/setup/os/macos.sh"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID,,}"
    if [ "$DISTRO" = "nixos" ]; then
        log "Detected NixOS — dispatching to setup/os/nixos.sh"
        # shellcheck source=setup/os/nixos.sh
        . "$SETUP_DIR/setup/os/nixos.sh"
    else
        log "Detected Linux ($DISTRO) — dispatching to setup/os/linux.sh"
        # shellcheck source=setup/os/linux.sh
        . "$SETUP_DIR/setup/os/linux.sh"
    fi
else
    err "Cannot detect OS type. /etc/os-release missing and not running on macOS."
fi
