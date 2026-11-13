#!/usr/bin/env bash
# RiFA Technology dev environment setup (MSYS2 UCRT64).
# Safe to run repeatedly: it only installs or configures what is missing.
#
# Usage (inside the "MSYS2 UCRT64" shell):
#   ./setup.sh            # interactive: asks for git name/email if unset
#   ./setup.sh --yes      # non-interactive: skips every prompt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSUME_YES=0
[[ "${1:-}" == "--yes" ]] && ASSUME_YES=1

info() { printf '\n==> %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; }

interactive() { [[ $ASSUME_YES -eq 0 && -t 0 ]]; }

# --- 1. Environment check ---------------------------------------------------
if [[ "${MSYSTEM:-}" != "UCRT64" ]]; then
  echo "This script must run in the MSYS2 UCRT64 shell (MSYSTEM=UCRT64)." >&2
  echo "Current MSYSTEM: ${MSYSTEM:-<unset>}" >&2
  exit 1
fi

# --- 2. pacman packages -----------------------------------------------------
info "Installing pacman packages (only missing ones)"
mapfile -t packages < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$SCRIPT_DIR/packages-ucrt64.txt" | grep -v '^$')
pacman -S --needed --noconfirm "${packages[@]}"

# --- 3. git config ----------------------------------------------------------
info "Configuring git"
for key in user.name user.email; do
  if [[ -z "$(git config --global "$key" || true)" ]]; then
    if interactive; then
      read -r -p "  git $key: " value
      [[ -n "$value" ]] && git config --global "$key" "$value"
    else
      warn "git $key is not set; run: git config --global $key \"...\""
    fi
  else
    echo "  $key = $(git config --global "$key")"
  fi
done
git config --global init.defaultBranch main
git config --global core.autocrlf input

# --- 4. SSH key for GitHub --------------------------------------------------
info "Checking SSH key"
if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  echo "  ~/.ssh/id_ed25519 already exists"
elif interactive; then
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  comment="$(git config --global user.email || echo "$USER@$(hostname)")"
  ssh-keygen -t ed25519 -C "$comment" -f "$HOME/.ssh/id_ed25519"
  echo
  echo "  Add this public key at https://github.com/settings/keys :"
  cat "$HOME/.ssh/id_ed25519.pub"
else
  warn "no SSH key; run: ssh-keygen -t ed25519"
fi

# --- 5. Claude Code CLI -----------------------------------------------------
info "Checking Claude Code CLI"
if command -v claude >/dev/null 2>&1; then
  echo "  claude already installed"
else
  npm install -g @anthropic-ai/claude-code
fi

# --- 6. Verify --------------------------------------------------------------
info "Verifying tools"
"$SCRIPT_DIR/verify.sh"
