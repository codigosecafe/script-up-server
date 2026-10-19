#!/usr/bin/env bash
run_doctor() {
  local failed=0 tool
  if [[ -r "$HOME/.config/script-up-server/env.sh" ]]; then
    set +u
    source "$HOME/.config/script-up-server/env.sh"
    set -u
  fi
  section 'Ferramentas disponíveis'
  for tool in git ssh zsh php composer laravel node pnpm flutter dart java adb sdkmanager eas; do
    if command -v "$tool" >/dev/null; then
      printf '[OK] %-12s %s\n' "$tool" "$(command -v "$tool")"
    else
      printf '[AUSENTE] %s\n' "$tool"
      failed=1
    fi
  done
  if command -v nvm >/dev/null; then
    printf '[OK] nvm %s\n' "$(nvm --version)"
  else
    echo '[AUSENTE] nvm'
    failed=1
  fi
  section 'Git global'
  git config --global --get user.name || true
  git config --global --get user.email || true
  section 'Serviços locais'
  for tool in mariadb apache2; do
    if [[ "$(ps -p 1 -o comm=)" == systemd ]] && command -v systemctl >/dev/null; then
      if systemctl is-active --quiet "$tool"; then
        printf '[OK] %s ativo\n' "$tool"
      else
        printf '[PENDENTE] %s inativo ou não instalado\n' "$tool"
        failed=1
      fi
    else
      printf '[INFO] Use sudo service %s status (WSL sem systemd).\n' "$tool"
    fi
  done
  if command -v curl >/dev/null && curl -fsSL --connect-timeout 2 --max-time 5 -o /dev/null http://127.0.0.1:8080/phpmyadmin/; then
    echo '[OK] phpMyAdmin responde em localhost:8080'
  else
    echo '[PENDENTE] phpMyAdmin indisponível em localhost:8080'
    failed=1
  fi
  if command -v flutter >/dev/null; then
    echo 'Para diagnóstico mobile completo: flutter doctor -v'
  fi
  return "$failed"
}
