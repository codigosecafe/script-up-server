#!/usr/bin/env bash
install_mobile() {
  section 'Flutter stable, Dart, Java e Android SDK'
  apt_install git curl ca-certificates unzip zip xz-utils openjdk-21-jdk-headless \
    clang cmake ninja-build pkg-config libgtk-3-dev libglu1-mesa
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
  export ANDROID_HOME="$HOME/Android/Sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  local flutter_dir="$HOME/development/flutter"
  if [[ ! -e "$flutter_dir" ]]; then
    mkdir -p "$(dirname "$flutter_dir")"
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$flutter_dir"
  elif [[ ! -d "$flutter_dir/.git" ]]; then
    die "Pasta Flutter existente sem repositório Git: $flutter_dir"
  elif [[ -n "$(git -C "$flutter_dir" status --porcelain)" ]]; then
    die 'Flutter tem alterações locais. Preserve-as antes de atualizar.'
  fi
  export PATH="$flutter_dir/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$JAVA_HOME/bin:$PATH"
  flutter channel stable
  flutter upgrade
  flutter config --jdk-dir "$JAVA_HOME"
  flutter config --android-sdk "$ANDROID_HOME"
  install_android_tools
  echo 'Leia as licenças Android e responda às perguntas a seguir.'
  sdkmanager --sdk_root="$ANDROID_HOME" --licenses
  sdkmanager --sdk_root="$ANDROID_HOME" 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' 'cmake;3.22.1'
  flutter precache --android --web
  flutter --version
  dart --version
  java -version
  adb version
  if ! flutter doctor -v; then
    echo 'Revise as pendências do flutter doctor. Dispositivo/emulador e navegador são configurados separadamente.' >&2
  fi
}

install_android_tools() {
  [[ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]] || return 0
  [[ ! -e "$ANDROID_HOME/cmdline-tools/latest" ]] || die 'cmdline-tools/latest já existe e está incompleto.'
  local archive="$WORK_DIR/android-tools.zip"
  curl -fL --retry 3 https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip -o "$archive"
  printf '4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583  %s\n' "$archive" | sha256sum -c -
  unzip -q "$archive" -d "$WORK_DIR/android-tools"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  mv "$WORK_DIR/android-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
}
