#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# get-secret.sh - retrieve a secret from Bitwarden (via rbw)
#
# Usage: get-secret.sh <item-name>
#   Set VERBOSE=1 to emit debug info to stderr.
# ---------------------------------------------------------------------------

VERBOSE="${VERBOSE:-0}"
log() {
  if [[ "$VERBOSE" == "1" ]]; then
    echo "[get-secret] $*" >&2
  fi
}

ITEM_NAME="${1:-}"
if [[ -z "$ITEM_NAME" ]]; then
  echo "[get-secret] ERROR: no item name provided" >&2
  exit 1
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export RBW_PROFILE="aibot"

# ---- detect non-TTY environment (e.g. coding agent) ------------------------
NEEDS_FAKE_PINENTRY=0
if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
  NEEDS_FAKE_PINENTRY=1
  log "non-TTY detected; will use fake pinentry for rbw unlock"
fi

# ---- helper: create & install a temporary fake pinentry --------------------
FAKE_PINENTRY=""
ORIG_CONFIG="${HOME}/Library/Application Support/rbw-${RBW_PROFILE}/config.json"
TMP_CONFIG=""

setup_fake_pinentry() {
  log "setting up fake pinentry workaround..."

  # Fetch master password from macOS Keychain
  BW_MASTER_PASS=$(security find-generic-password -a "$USER" -s "aibot-master-password" -w 2>/dev/null || true)
  if [[ -z "$BW_MASTER_PASS" ]]; then
    echo "[get-secret] ERROR: could not retrieve master password from macOS Keychain (item 'aibot-master-password')" >&2
    return 1
  fi

  # Create fake pinentry script that speaks the pinentry-assuan protocol
  FAKE_PINENTRY=$(mktemp /tmp/rbw-fake-pinentry.XXXXXX)
  cat <<EOF > "$FAKE_PINENTRY"
#!/bin/bash
PW="$(printf '%s' "$BW_MASTER_PASS" | sed 's/"/\\"/g')"
while read -r line; do
  case "\$line" in
    GETPIN) echo "D \$PW"; echo "OK" ;;
    BYE)    echo "OK"; exit 0 ;;
    *)      echo "OK" ;;
  esac
done
EOF
  chmod +x "$FAKE_PINENTRY"

  # Backup original rbw config
  if [[ -f "$ORIG_CONFIG" ]]; then
    TMP_CONFIG=$(mktemp /tmp/rbw-config-backup.XXXXXX)
    cp "$ORIG_CONFIG" "$TMP_CONFIG"
    log "backed up rbw config -> $TMP_CONFIG"
  fi

  # Point rbw at the fake pinentry
  python3 -c "
import json, sys
with open('$ORIG_CONFIG', 'r') as f:
    d = json.load(f)
d['pinentry'] = '$FAKE_PINENTRY'
with open('$ORIG_CONFIG', 'w') as f:
    json.dump(d, f)
" || {
    echo "[get-secret] ERROR: failed to patch rbw config ($ORIG_CONFIG)" >&2
    return 1
  }
  log "patched rbw config pinentry -> $FAKE_PINENTRY"
}

cleanup_fake_pinentry() {
  if [[ -n "$TMP_CONFIG" && -f "$TMP_CONFIG" ]]; then
    cp "$TMP_CONFIG" "$ORIG_CONFIG"
    log "restored original rbw config"
  fi
  if [[ -n "$FAKE_PINENTRY" && -f "$FAKE_PINENTRY" ]]; then
    rm -f "$FAKE_PINENTRY"
    log "removed fake pinentry"
  fi
  if [[ -n "$TMP_CONFIG" && -f "$TMP_CONFIG" ]]; then
    rm -f "$TMP_CONFIG"
    log "removed config backup"
  fi
}

# Register cleanup on exit, error, or interrupt
trap cleanup_fake_pinentry EXIT INT TERM

# ---- step 1: check if rbw agent is unlocked --------------------------------
if ! rbw unlocked >/dev/null 2>&1; then
  log "rbw agent is locked; need to unlock"

  if [[ "$NEEDS_FAKE_PINENTRY" == "1" ]]; then
    setup_fake_pinentry || exit 1
  else
    # TTY path: normal pinentry should work
    BW_MASTER_PASS=$(security find-generic-password -a "$USER" -s "aibot-master-password" -w 2>/dev/null || true)
    if [[ -z "$BW_MASTER_PASS" ]]; then
      echo "[get-secret] ERROR: could not retrieve master password from macOS Keychain" >&2
      exit 1
    fi
  fi

  # Unlock (fake pinentry feeds password automatically; TTY path feeds via stdin if rbw supports it)
  if ! echo "$BW_MASTER_PASS" | rbw unlock >/dev/null 2>&1; then
    # If stdin unlock failed (common with graphical pinentry), try without stdin for TTY
    if [[ "$NEEDS_FAKE_PINENTRY" == "0" ]]; then
      if ! rbw unlock >/dev/null 2>&1; then
        echo "[get-secret] ERROR: rbw unlock failed" >&2
        exit 1
      fi
    else
      echo "[get-secret] ERROR: rbw unlock failed (fake pinentry may have malfunctioned)" >&2
      exit 1
    fi
  fi
  log "rbw agent unlocked successfully"
else
  log "rbw agent already unlocked"
fi

# ---- step 2: retrieve secret -----------------------------------------------
SECRET=$(rbw get "$ITEM_NAME" 2>/dev/null || true)

if [[ -z "$SECRET" ]]; then
  echo "[get-secret] ERROR: secret '$ITEM_NAME' not found or empty" >&2
  exit 1
fi

log "secret '$ITEM_NAME' retrieved successfully"
echo "$SECRET"
