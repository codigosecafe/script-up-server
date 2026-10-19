#!/usr/bin/env bash

die() { printf 'Erro: %s\n' "$*" >&2; exit 1; }
section() { printf '\n== %s ==\n' "$*"; }
require_user() { (( EUID != 0 )) || die 'Execute como usuário normal, sem sudo antes do script.'; }
require_ubuntu() {
  [[ -r /etc/os-release ]] || die 'Sistema sem /etc/os-release.'
  source /etc/os-release
  [[ "$ID" == ubuntu ]] || die 'Distribuição suportada: Ubuntu.'
  case "$VERSION_ID" in
    24.04|26.04) ;;
    *) die 'Use Ubuntu 24.04 LTS ou 26.04 LTS.' ;;
  esac
}

init_state() {
  CONFIG_DIR="$HOME/.config/script-up-server"
  BACKUP_DIR="$HOME/.local/state/script-up-server/$(date +%Y%m%d-%H%M%S)-$$"
  install -d -m 700 "$CONFIG_DIR" "$BACKUP_DIR"
  mkdir -p "$HOME/.local/bin" "$HOME/Projects"
  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf -- "$WORK_DIR"' EXIT
  APT_UPDATED=0
}

apt_install() {
  if (( APT_UPDATED == 0 )); then
    sudo apt-get update
    APT_UPDATED=1
  fi
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

backup_file() {
  local file="$1" destination="$BACKUP_DIR/files/${1#/}"
  if [[ -e "$file" || -L "$file" ]]; then
    mkdir -p "$(dirname "$destination")"
    sudo cp -a -- "$file" "$destination"
  fi
}

append_once() {
  local file="$1" line="$2"
  touch "$file"
  if ! grep -qxF -- "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

clone_if_missing() {
  local repository="$1" destination="$2"
  if [[ ! -e "$destination" ]]; then
    mkdir -p "$(dirname "$destination")"
    git clone --depth 1 "https://github.com/$repository.git" "$destination"
  elif [[ ! -d "$destination/.git" ]]; then
    die "Pasta existente sem repositório Git: $destination"
  fi
}

restart_service() {
  if [[ "$(ps -p 1 -o comm=)" == systemd ]]; then
    sudo systemctl enable "$1"
    sudo systemctl restart "$1"
  else
    sudo service "$1" restart
  fi
}

install_environment() {
  backup_file "$CONFIG_DIR/env.sh"
  install -m 644 "$PROJECT_ROOT/config/env.sh" "$CONFIG_DIR/env.sh"
  local rc
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    backup_file "$rc"
    append_once "$rc" '[ -r "$HOME/.config/script-up-server/env.sh" ] && . "$HOME/.config/script-up-server/env.sh"'
  done
}

print_plan() {
  local profile="$1" module
  local profiles=("$profile")
  [[ "$profile" != all ]] || profiles=(terminal node web mobile)
  printf 'Plano: %s (nenhuma alteração será executada)\n' "$profile"
  for module in "${profiles[@]}"; do
    case "$module" in
      terminal) echo 'terminal: Zsh + Oh My Zsh + Spaceship + Zinit + plugins; Fira Code; paleta Dracula; chsh.' ;;
      node) echo 'node: NVM 0.40.8; nvm install --lts; pnpm, EAS CLI e @expo/ngrok pelo npm do NVM.' ;;
      web) echo 'web: PHP >= 8.3 + Composer + Laravel installer; MariaDB local; usuário developer com acesso a dev_*; phpMyAdmin local em 8080.' ;;
      mobile) echo 'mobile: Java 21; Flutter stable e Dart; Android command-line tools com checksum; licenças interativas; API 36.' ;;
    esac
  done
  echo 'Instala pacotes necessários, salva backups e integra PATH ao Bash/Zsh.'
}
