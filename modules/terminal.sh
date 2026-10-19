#!/usr/bin/env bash
install_terminal() {
  section 'Zsh, Spaceship e plugins'
  apt_install zsh git curl ca-certificates fonts-firacode fontconfig python3
  clone_if_missing ohmyzsh/ohmyzsh "$HOME/.oh-my-zsh"
  clone_if_missing spaceship-prompt/spaceship-prompt "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"
  clone_if_missing zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
  local theme="$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
  backup_file "$theme"
  ln -sfn "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$theme"
  backup_file "$CONFIG_DIR/terminal.zsh"
  install -m 644 "$PROJECT_ROOT/config/terminal.zsh" "$CONFIG_DIR/terminal.zsh"
  backup_file "$HOME/.zshrc"
  # Migra apenas a linha gerada pelo instalador anterior desta sessão.
  python3 - "$HOME/.zshrc" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
if p.exists():
    old = 'source "$HOME/.config/zsh/rocketseat.zsh"'
    p.write_text(''.join(line for line in p.read_text().splitlines(keepends=True) if line.strip() != old))
PY
  append_once "$HOME/.zshrc" 'source "$HOME/.config/script-up-server/terminal.zsh"'
  zsh -n "$CONFIG_DIR/terminal.zsh"
  zsh -ic '[[ -n $SPACESHIP_VERSION && -n $FAST_HIGHLIGHT_VERSION ]] && (( $+functions[_zsh_autosuggest_start] )) || exit 1'
  fc-cache -f
  configure_dracula
  local zsh_path current_shell
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  if [[ "$current_shell" != "$zsh_path" ]]; then
    echo 'Definindo Zsh como shell padrão; pode solicitar sua senha.'
    chsh -s "$zsh_path"
  fi
  zsh --version
}

configure_dracula() {
  if command -v gsettings >/dev/null && command -v dconf >/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && gsettings list-schemas | grep -qx 'org.gnome.Terminal.ProfilesList'; then
    dconf dump /org/gnome/terminal/legacy/profiles:/ > "$BACKUP_DIR/gnome-terminal.dconf"
    local profile schema
    profile="$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")"
    [[ -n "$profile" ]] || return 0
    schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
    gsettings set "$schema" use-theme-colors false
    gsettings set "$schema" background-color '#282a36'
    gsettings set "$schema" foreground-color '#f8f8f2'
    gsettings set "$schema" palette "['#21222c', '#ff5555', '#50fa7b', '#f1fa8c', '#bd93f9', '#ff79c6', '#8be9fd', '#f8f8f2', '#6272a4', '#ff6e6e', '#69ff94', '#ffffa5', '#d6acff', '#ff92df', '#a4ffff', '#ffffff']"
    gsettings set "$schema" use-system-font false
    gsettings set "$schema" font 'Fira Code 12'
  else
    echo 'No Windows Terminal, importe config/windows-terminal-dracula.json e selecione a fonte no Windows. Consulte docs/terminal.md.'
  fi
}
