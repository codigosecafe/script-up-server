# Flutter e Expo no WSL2

```bash
bash setup.sh install node
bash setup.sh install mobile
```

SDK Android Linux: `~/Android/Sdk`. Flutter stable: `~/development/flutter`.
Java 21 é usado por padrão. O arquivo Android command-line tools tem SHA-256
conferido antes da extração. As licenças são apresentadas no terminal.

Gradle pode baixar NDK, plataforma e build tools exigidos pelo projeto na
primeira compilação. Android Studio e emuladores não são instalados. Dart já
acompanha Flutter.

## Expo no celular

```bash
cd ~/Projects
pnpm create expo-app@latest meu-app
cd meu-app
pnpm exec expo start --tunnel
```

Instale Expo Go e escaneie o QR code. O túnel evita encaminhar a porta do Metro
no WSL e exige internet. Para módulos fora do Expo Go, use um development build.
Expo CLI acompanha o projeto; EAS CLI está disponível como `eas` e exige conta
Expo para builds na nuvem.

Com Android conectado, compile localmente:

```bash
pnpm exec expo run:android
```

## Flutter no celular

```bash
cd ~/Projects
flutter create meu_flutter
cd meu_flutter
flutter doctor -v
flutter devices
```

No Android 11 ou superior, habilite opções do desenvolvedor e depuração sem fio.
Computador e celular precisam estar em uma rede que permita comunicação entre
eles. Use os endereços e portas mostrados no Android:

```bash
adb pair IP_DO_CELULAR:PORTA_DE_PAREAMENTO
adb connect IP_DO_CELULAR:PORTA_DE_DEPURACAO
adb devices
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

O código de pareamento aparece no celular. As duas portas são diferentes.
Para USB no WSL, é necessário encaminhar o dispositivo pelo Windows, por
exemplo com usbipd-win.

## Emulador e navegador no Windows

Instale Android Studio e crie o emulador no Windows. Ele não aparecerá
automaticamente no ADB Linux: configure a comunicação entre servidor ADB
Windows e cliente WSL conforme o modo de rede e firewall do computador.
O instalador não expõe o servidor ADB nem altera o firewall.

Para Flutter web, use o navegador Windows sem Chrome no WSL:

```bash
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8090
```

Abra http://localhost:8090. Esse comando publica o servidor nas interfaces do
WSL; encerre com Ctrl+C ao terminar.

`flutter doctor` pode apontar Chrome, Android Studio ou dispositivos ausentes;
avalie conforme o alvo desejado. Compilar iOS localmente exige macOS/Xcode;
no Expo, builds iOS podem ser feitos via EAS.
