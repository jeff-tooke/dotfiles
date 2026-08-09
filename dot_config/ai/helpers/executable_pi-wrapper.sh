#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# launch Pi with AI provider environment configured
#
# Secrets are retrieved from the aibot rbw profile via get_secret.sh.
# The environment variables only exist for the lifetime of the Pi process.
#
# Usage:
#   pi-wrapper.sh
#   pi-wrapper.sh <pi arguments>
# ---------------------------------------------------------------------------

# ---- Configuration ---------------------------------------------------------

SECRET_HELPER="${HOME}/.local/bin/get-secret.sh"

# Non-secret provider configuration.
OLLAMA_BASE_URL="http://localhost:11434"
OMNIROUTE_BASE_URL="https://omniroute.<domain-name>.com"

# Bitwarden item names as understood by get_secret.sh.
OMNIROUTE_API_KEY_ITEM="omniroute-api-key"

# ---- Helpers ---------------------------------------------------------------
error() {
    echo "[ai-coding] ERROR: $*" >&2
    exit 1
}

# ---- Validate dependencies -------------------------------------------------
command -v pi >/dev/null 2>&1 \
    || error "pi not found in PATH"

command -v rbw >/dev/null 2>&1 \
    || error "rbw not found in PATH"

[[ -x "$SECRET_HELPER" ]] \
    || error "secret helper not found or not executable: $SECRET_HELPER"

export RBW_PROFILE="aibot"

# ---- Retrieve secrets ------------------------------------------------------
if ! OMNIROUTE_API_KEY="$("$SECRET_HELPER" "$OMNIROUTE_API_KEY_ITEM")"; then
    error "failed to retrieve OMNIROUTE_API_KEY"
fi

[[ -n "$OMNIROUTE_API_KEY" ]] \
    || error "OMNIROUTE_API_KEY was retrieved but is empty"

# ---- Export Pi environment -------------------------------------------------
export OLLAMA_BASE_URL
export OMNIROUTE_BASE_URL
export OMNIROUTE_API_KEY

# ---- Launch Pi -------------------------------------------------------------
exec pi "$@"
