#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_ROOT/lib/common.sh"

usage() {
  cat <<'HELP'
script-up-server — ferramentas nativas para Ubuntu e WSL2

Uso:
  bash setup.sh install terminal|node|web|mobile|all [--dry-run]
  bash setup.sh doctor
  bash setup.sh git 'Nome' 'email@exemplo.com'
  bash setup.sh ssh 'Nome <email@exemplo.com>' [--no-passphrase]
  bash setup.sh --help

terminal  Zsh, Oh My Zsh, Spaceship, plugins, Fira Code e paleta Dracula
node      NVM, Node LTS, pnpm e ferramentas Expo/EAS
web       PHP do Ubuntu (>= 8.3), Composer, Laravel, MariaDB e phpMyAdmin
mobile    Flutter stable, Dart, Java 21 e Android SDK (Linux x86_64)
all       terminal + node + web + mobile

Execute como usuário normal. Install pede sudo; Git e SSH não usam sudo.
O modo --dry-run mostra o plano sem baixar, instalar ou alterar arquivos.
HELP
}

case "${1:---help}" in
  --help|-h|help) usage ;;
  install)
    profile="${2:-}"
    [[ "$profile" =~ ^(terminal|node|web|mobile|all)$ ]] || die 'Informe um perfil válido. Consulte --help.'
    [[ $# -le 3 ]] || die 'Argumentos extras. Consulte --help.'
    if [[ $# == 3 ]]; then
      [[ "$3" == --dry-run ]] || die "Opção desconhecida: $3"
      print_plan "$profile"
      exit 0
    fi
    require_user
    require_ubuntu
    if [[ "$profile" == mobile || "$profile" == all ]]; then
      [[ "$(uname -m)" == x86_64 ]] || die 'O módulo mobile requer Linux x86_64.'
      [[ -t 0 ]] || die 'Use um terminal interativo para ler e aceitar as licenças Android.'
    fi
    command -v sudo >/dev/null || die 'sudo não está instalado.'
    sudo -v
    init_state
    trap 'printf "\nFalha na linha %s (%s). Corrija o erro acima e execute novamente.\n" "$LINENO" "${BASH_SOURCE[0]}" >&2' ERR
    profiles=("$profile")
    [[ "$profile" != all ]] || profiles=(terminal node web mobile)
    for module in "${profiles[@]}"; do
      source "$PROJECT_ROOT/modules/$module.sh"
      "install_$module"
    done
    install_environment
    printf '\nConcluído. Abra um novo terminal. Backups: %s\n' "$BACKUP_DIR"
    echo 'Diagnóstico: bash setup.sh doctor'
    ;;
  doctor)
    [[ $# == 1 ]] || die 'doctor não recebe argumentos.'
    source "$PROJECT_ROOT/modules/doctor.sh"
    run_doctor
    ;;
  git|ssh)
    action="$1"
    shift
    require_user
    source "$PROJECT_ROOT/modules/identity.sh"
    "configure_$action" "$@"
    ;;
  *) usage >&2; exit 2 ;;
esac
