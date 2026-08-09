#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# vibing - launch a Pi coding environment inside herdr
#
# Creates a herdr workspace in the current directory, injects the AI
# environment, waits for the shell prompt, starts Pi as a native herdr agent,
# then attaches to herdr.
#
# Usage:
#   vibing
# ---------------------------------------------------------------------------

error() {
    echo "[vibing] ERROR: $*" >&2
    exit 1
}

SECRET_HELPER="${HOME}/.local/bin/get-secret.sh"
AGENT_NAME="pi"

# ---- Validate dependencies -------------------------------------------------

command -v herdr >/dev/null 2>&1 \
    || error "herdr not found in PATH"

command -v jq >/dev/null 2>&1 \
    || error "jq not found in PATH"

[[ -x "$SECRET_HELPER" ]] \
    || error "secret helper not found or not executable: $SECRET_HELPER"

# ---- Check for an existing Pi agent ----------------------------------------

if herdr agent get "$AGENT_NAME" >/dev/null 2>&1; then
    # Existing Pi is still alive. Just return to the Herdr session.
    herdr agent focus "$AGENT_NAME" >/dev/null 2>&1 || true
    exec herdr
fi

# ---- Provider configuration ------------------------------------------------

OLLAMA_BASE_URL="http://localhost:11434"
OMNIROUTE_BASE_URL="https://omniroute.<domain-name>.com"

# ---- Retrieve secrets ------------------------------------------------------

if ! OMNIROUTE_API_KEY="$("$SECRET_HELPER" "omniroute-api-key")"; then
    error "failed to retrieve OMNIROUTE_API_KEY"
fi

[[ -n "$OMNIROUTE_API_KEY" ]] \
    || error "OMNIROUTE_API_KEY was retrieved but is empty"

# ---- Ensure herdr server is running ----------------------------------------

if ! herdr status server >/dev/null 2>&1; then
    herdr server >/dev/null 2>&1 &

    for _ in {1..50}; do
        if herdr status server >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done

    herdr status server >/dev/null 2>&1 \
        || error "herdr server failed to start"
fi

# ---- Create workspace ------------------------------------------------------

workspace_json="$(
    herdr workspace create \
        --cwd "$PWD" \
        --label "$(basename "$PWD")" \
        --env "OLLAMA_BASE_URL=$OLLAMA_BASE_URL" \
        --env "OMNIROUTE_BASE_URL=$OMNIROUTE_BASE_URL" \
        --env "OMNIROUTE_API_KEY=$OMNIROUTE_API_KEY" \
        --focus
)"

pane_id="$(
    printf '%s\n' "$workspace_json" |
        jq -r '.result.root_pane.pane_id // empty'
)"

[[ -n "$pane_id" ]] \
    || error "could not determine herdr root pane"

# ---- Wait for the shell to reach its prompt --------------------------------
#
# Herdr's agent start requires the pane to be at an interactive shell prompt.
# The current Starship prompt ends in "❯".

if ! herdr pane wait-output "$pane_id" \
        --regex '❯[[:space:]]*$' \
        --source visible \
        --timeout 10000 >/dev/null; then
    error "root pane did not reach its shell prompt"
fi

# ---- Start native Pi agent -------------------------------------------------

herdr agent start $AGENT_NAME \
    --kind pi \
    --pane "$pane_id"

# ---- Attach to herdr -------------------------------------------------------

exec herdr
