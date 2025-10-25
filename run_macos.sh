#!/usr/bin/env bash
set -euo pipefail

log() { printf "\033[1;34m➜\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m⚠\033[0m %s\n" "$*"; }

BREW_BIN="/opt/homebrew/bin/brew"
SHELL_RC="$HOME/.zprofile"   # default shell on macOS is zsh

ensure_brew_in_path() {
  if [[ -x "$BREW_BIN" ]]; then
    # shellcheck disable=SC1090
    eval "$("$BREW_BIN" shellenv)"
    export PATH
    ok "Homebrew available at $BREW_BIN"
    return 0
  fi
  return 1
}

install_brew() {
  log "Homebrew not found. Installing Homebrew for Apple silicon…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Load into current session
  if ensure_brew_in_path; then
    # Persist for future shells
    if ! grep -q 'brew shellenv' "$SHELL_RC" 2>/dev/null; then
      log "Adding Homebrew to PATH in $SHELL_RC"
      {
        echo ""
        echo "# Homebrew (Apple silicon)"
        echo "eval \"\$($BREW_BIN shellenv)\""
      } >> "$SHELL_RC"
    fi
    ok "Homebrew installation complete."
  else
    warn "brew not found on PATH after install; open a new terminal and try again."
  fi
}

has_python3() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import sys; raise SystemExit(0 if sys.version_info.major >= 3 else 1)
PY
    return
  fi
  if command -v python >/dev/null 2>&1; then
    python - <<'PY'
import sys; raise SystemExit(0 if sys.version_info.major >= 3 else 1)
PY
    return
  fi
  return 1
}

install_python3_with_brew() {
  log "Installing Python 3 via Homebrew…"
  brew update
  brew install python
  ok "Python 3 installed."
}

main() {
  log "Checking for Homebrew…"
  if ! ensure_brew_in_path; then
    install_brew
    ensure_brew_in_path || warn "brew still not found; PATH may need a new shell."
  fi

  ok "brew version: $(brew --version | head -n1)"

  log "Checking for Python 3+…"
  if has_python3; then
    ok "Python found on filesystem"
  else
    install_python3_with_brew
    ok "Python now: $(python3 --version)"
  fi

  ok "Done."
}

main "$@"

# Ensure pipx is available
if ! command -v pipx >/dev/null 2>&1; then
  ok "Installing pipx"
  brew install pipx
  pipx ensurepath
  source $SHELL_RC
fi

# SEGGER J-Link (required by pylink)
if ! command -v JLinkExe >/dev/null 2>&1; then
  brew install --cask segger-jlink
fi

usage() {
  cat <<'USAGE'
Usage: ./run_hubble_demo.sh <BOARD> <TOKEN> <ORG>

Examples:
  ./run_macos.sh nrf52dk sk_abc123 my-org
  ./run_macos.sh nrf52840dk sk_live_123 my-team
USAGE
}

BOARD="$1"
ORG="$2"
TOKEN="$3"

# Basic validation
if [[ -z "$BOARD" || -z "$TOKEN" || -z "$ORG" ]]; then
  echo "Error: BOARD, TOKEN, and ORG are all required." >&2
  usage
  exit 1
fi

exec pipx run --no-cache \
  --spec "git+https://github.com/HubbleNetwork/hubble-tldm.git@master#subdirectory=python" \
  hubbledemo flash "$BOARD" -t "$TOKEN" -o "$ORG"
