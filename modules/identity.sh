#!/usr/bin/env bash
configure_git() {
  [[ $# == 2 && -n "$1" && -n "$2" ]] || die "Uso: bash setup.sh git 'Nome' 'email@exemplo.com'"
  command -v git >/dev/null || die 'Instale Git primeiro.'
  git config --global user.name "$1"
  git config --global user.email "$2"
  git config --global --get user.name
  git config --global --get user.email
}

configure_ssh() {
  [[ $# -ge 1 && $# -le 2 && -n "$1" ]] || die "Uso: bash setup.sh ssh 'Nome <email>' [--no-passphrase]"
  local comment="$1" key="$HOME/.ssh/id_ed25519"
  if [[ $# == 2 ]]; then
    [[ "$2" == --no-passphrase ]] || die "Opção desconhecida: $2"
  fi
  command -v ssh-keygen >/dev/null || die 'Instale openssh-client primeiro.'
  [[ ! -e "$key" && ! -L "$key" && ! -e "$key.pub" && ! -L "$key.pub" ]] || die "Chave já existe: $key. Nenhum arquivo foi sobrescrito."
  install -d -m 700 "$HOME/.ssh"
  if [[ "${2:-}" == --no-passphrase ]]; then
    ssh-keygen -t ed25519 -C "$comment" -N '' -f "$key"
  else
    [[ -t 0 ]] || die 'Use um terminal interativo para definir a senha da chave, ou --no-passphrase.'
    ssh-keygen -t ed25519 -C "$comment" -f "$key"
  fi
  chmod 600 "$key"
  chmod 644 "$key.pub"
  ssh-keygen -lf "$key.pub"
  cat "$key.pub"
}
