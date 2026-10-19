#!/usr/bin/env bash
install_node() {
  section 'Node LTS via NVM e pnpm'
  apt_install git curl ca-certificates build-essential python3 unzip
  export NVM_DIR="$HOME/.nvm"
  local installer
  installer="$(mktemp "$BACKUP_DIR/nvm-install.XXXXXX")"
  curl -fsSL --retry 3 https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh -o "$installer"
  PROFILE=/dev/null bash "$installer"
  # NVM não suporta nounset em todos os caminhos internos.
  set +u
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use default
  npm install --global pnpm@latest eas-cli@latest @expo/ngrok
  set -u
  node --version
  pnpm --version
  eas --version
}
