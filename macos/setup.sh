#!/bin/bash

# ============================================================================
# macOS provisioning — standalone, scripted-as-far-as-possible bootstrap.
# ----------------------------------------------------------------------------
# Prerequisites (must be true BEFORE running this script)
#   - A fresh/clean user account on macOS.
#   - Working internet connection.
#   - This repo cloned to ~/.dotfiles, e.g.:
#       git clone --recurse-submodules https://github.com/<user>/dotfiles ~/.dotfiles
#   - Run as the target user (NOT root); the script will sudo when needed.
#
# Parts of macOS provisioning cannot be fully scripted (GUI dialogs, TCC /
# Privacy & Security approvals, Login Items). See macos/README.md for the
# manual steps and known interactive challenges.
#
# NOTE: This is intentionally a trimmed, macOS-only rewrite of the multi-distro
# linux/setup.sh. It reuses that script's helpers, section style, and variable
# conventions (log/warn/err/section, LOG_FILE, DISTRO) so the body can later be
# folded back into the `OSTYPE == darwin*` branch of the unified script.
# ============================================================================

set -eE

echo "Starting macOS provisioning..."

LOG_FILE="$HOME/system-setup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[x]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }
section() { echo -e "\n${BLUE}--- $1 ---${NC}\n" | tee -a "$LOG_FILE"; }

# --- OS guard --------------------------------------------------------------
if [[ "$OSTYPE" != darwin* ]]; then
    err "This script targets macOS only (OSTYPE=$OSTYPE). For Linux use linux/setup.sh."
fi
DISTRO="macos"

# Resolve the dotfiles checkout from this script's location (macos/ -> repo
# root). Robust whether the repo lives at ~/.dotfiles or elsewhere.
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
log "Dotfiles checkout: $DOTFILES_DIR"

# =============================================================================
# 0. Acquire sudo up front and keep it alive for the whole run
# =============================================================================
# macOS prompts for the password on the first sudo and then again whenever the
# timestamp expires (default 5 min). Several steps below (Homebrew, the Nix
# installer, nix-darwin) sudo internally and can run for many minutes, so prime
# the timestamp now and refresh it in the background until this script exits.
section "Acquiring sudo (kept alive for the run)"
sudo -v || err "sudo is required — aborting"
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
# `xcode-select --install` opens a GUI dialog that must be clicked through; it
# cannot be fully scripted on a clean machine. Poll until the tools land.
section "Installing Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools already installed at $(xcode-select -p) — skipping"
else
    log "Triggering Xcode Command Line Tools install (a GUI dialog will appear)..."
    xcode-select --install || true
    log "Waiting for Command Line Tools to finish installing (click through the dialog)..."
    until xcode-select -p >/dev/null 2>&1; do
        sleep 10
    done
    log "Xcode Command Line Tools installed"
fi

# =============================================================================
# 2. Homebrew
# =============================================================================
section "Installing Homebrew"
if command -v brew >/dev/null 2>&1; then
    warn "Homebrew already on PATH at $(command -v brew) — skipping install"
else
    log "Installing Homebrew (non-interactive)..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to the login shell env (guard against duplicate appends so this
    # stays idempotent across re-runs).
    if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        {
            echo
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
        } >> "$HOME/.zprofile"
        log "Appended brew shellenv to ~/.zprofile"
    else
        warn "brew shellenv already present in ~/.zprofile — skipping append"
    fi
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# =============================================================================
# 3. Nix
# =============================================================================
# Use the official nixos.org installer (the Determinate installer is no longer
# used — see macos/README.md). `--daemon --yes` drives it non-interactively.
section "Installing Nix"
if command -v nix >/dev/null 2>&1 || [ -d /nix ]; then
    warn "Nix already present (nix on PATH or /nix exists) — skipping install"
else
    log "Installing Nix (multi-user daemon, non-interactive)..."
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
fi

# Make nix available in this shell for the nix-darwin step below.
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
    warn "nix-daemon.sh not found — nix may not be on PATH for the nix-darwin step"
fi

# =============================================================================
# 4. nix-darwin system settings
# =============================================================================
section "Applying nix-darwin system settings"
if [ -d "$DOTFILES_DIR/setup/system-settings" ]; then
    (
        cd "$DOTFILES_DIR/setup/system-settings"
        sudo nix --extra-experimental-features "nix-command flakes" \
            run nix-darwin -- switch --flake .
    ) && log "nix-darwin switch complete" \
       || warn "nix-darwin switch failed — inspect the log and re-run this step"
else
    warn "No $DOTFILES_DIR/setup/system-settings — skipping nix-darwin switch"
fi

# =============================================================================
# 5. Homebrew packages
# =============================================================================
section "Installing Homebrew packages (brew bundle)"
BREWFILE="$DOTFILES_DIR/setup/package-management/Brewfile"
if [ -f "$BREWFILE" ]; then
    brew trust nikitabobko/tap
    brew trust felixkratz/formulae
    brew bundle --file="$BREWFILE" \
        && log "brew bundle complete" \
        || warn "brew bundle reported failures — check the log for individual formulae/casks"
else
    warn "No Brewfile at $BREWFILE — skipping brew bundle"
fi

# =============================================================================
# 6. Apply dotfiles via chezmoi
# =============================================================================
# chezmoi is installed by brew bundle above, so it is on PATH here.
section "Applying dotfiles via chezmoi"
CHEZMOI_BIN="$(command -v chezmoi || true)"
if [ -z "$CHEZMOI_BIN" ]; then
    warn "chezmoi not found on PATH — skipping dotfiles apply (did brew bundle run?)"
else
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        "$CHEZMOI_BIN" init --source "$DOTFILES_DIR"
    else
        log "chezmoi already initialised — skipping init"
    fi
    "$CHEZMOI_BIN" apply --source "$DOTFILES_DIR"
fi

# =============================================================================
# 7. Post-installation tool initialisation
# =============================================================================
section "Initialising tools (bat / borders / tmux plugins)"

# bat: build the cache so the bundled (catppuccin) theme is available.
if command -v bat >/dev/null 2>&1; then
    bat cache --build && log "bat cache built" || warn "bat cache --build failed"
fi

# borders: start the window-border service (felixkratz/borders).
if command -v borders >/dev/null 2>&1; then
    brew services start borders \
        && log "borders service started" \
        || warn "Failed to start borders service"
fi

# TPM (Tmux Plugin Manager) ships via the `tpm` brew formula. install_plugins
# is a no-op unless the tmux config (applied above via chezmoi) lists plugins.
TPM_INSTALL="/opt/homebrew/opt/tpm/share/tpm/bin/install_plugins"
if [ -x "$TPM_INSTALL" ]; then
    if [ -f "$HOME/.config/tmux/tmux.conf" ] || [ -f "$HOME/.tmux.conf" ]; then
        "$TPM_INSTALL" \
            && log "Tmux plugins installed" \
            || warn "TPM auto-install failed — open tmux and press prefix+I"
    else
        warn "No tmux.conf found — skipping plugin install. Re-run after chezmoi apply."
    fi
else
    warn "tpm not found at $TPM_INSTALL — is the 'tpm' brew formula installed?"
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo "======================================================================="
echo " macOS provisioning complete!"
echo " Log: $LOG_FILE"
echo ""
echo " Manual steps remain (GUI / Privacy & Security) — see macos/README.md."
echo "======================================================================="
