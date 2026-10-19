# Carregado pelo Bash e pelo Zsh. Pode ser carregado mais de uma vez.
sus_prepend_path() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}
sus_prepend_path "$HOME/.local/bin"
sus_prepend_path "$HOME/.composer/vendor/bin"
sus_prepend_path "$HOME/.config/composer/vendor/bin"
if [ -d "$HOME/development/flutter/bin" ]; then
  sus_prepend_path "$HOME/development/flutter/bin"
fi
export NVM_DIR="$HOME/.nvm"
if ! command -v nvm >/dev/null 2>&1 && [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi
if [ -d /usr/lib/jvm/java-21-openjdk-amd64 ]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
elif [ -d /usr/lib/jvm/java-21-openjdk-arm64 ]; then
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64
fi
if [ -d "$HOME/Android/Sdk" ]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  sus_prepend_path "$ANDROID_HOME/platform-tools"
  sus_prepend_path "$ANDROID_HOME/cmdline-tools/latest/bin"
fi
export PATH
unset -f sus_prepend_path
