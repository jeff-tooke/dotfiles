# ---- Dotfiles (chezmoi) helpers ----

# Commit all changes in the chezmoi source repo and push.
# Usage: dfp ["commit message"]   (defaults to a generic message)
df_push() {
    local msg="${*:-chore: update dotfiles}"
    chezmoi git -- add -A &&
    chezmoi git -- commit -m "$msg" &&
    chezmoi git -- push
}
