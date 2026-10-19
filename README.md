# script-up-server

Preparação de Ubuntu e WSL2 para desenvolvimento web e mobile com ferramentas
nativas. Instalação por módulos, terminal, Git/SSH e diagnóstico. Sem Docker.

O projeto nasceu da configuração de VPS Ubuntu. Agora também cobre Laravel,
Node, Flutter e React Native com Expo. Os scripts antigos foram substituídos;
`scripts-alias/` foi preservada sem alterações.

## Começar

Requer **Ubuntu 24.04 LTS ou 26.04 LTS**, Bash, usuário normal com sudo e
internet. Mobile requer x86_64 e vários GB livres. No WSL, use WSL2 e mantenha
os projetos no sistema de arquivos Linux.

```bash
git clone git@github.com:codigosecafe/script-up-server.git
cd script-up-server
bash setup.sh install all --dry-run
bash setup.sh install all
```

Execute sem `sudo` antes de `setup.sh`. O instalador solicita sudo onde
necessário e apresenta as licenças Android para leitura e aceitação. Abra um
novo terminal ao concluir.

| Módulo | Ferramentas |
| --- | --- |
| `terminal` | Zsh, Oh My Zsh, Spaceship, Zinit, completions, sugestões, syntax highlighting, Fira Code |
| `node` | NVM, Node LTS, pnpm, EAS CLI e suporte a túnel Expo |
| `web` | PHP do Ubuntu >= 8.3, Composer, Laravel installer, MariaDB, Apache e phpMyAdmin |
| `mobile` | Flutter stable, Dart, Java 21, Android SDK, API 36 e build tools |
| `all` | Todos os módulos acima |

Instale módulos separadamente e em qualquer ordem:

```bash
bash setup.sh install terminal
bash setup.sh install node
bash setup.sh install web
bash setup.sh install mobile
bash setup.sh doctor
```

`--dry-run` descreve o plano sem rede, sudo ou alterações. `doctor` verifica
todas as ferramentas e retorna 1 se faltarem componentes, o que é esperado
quando apenas alguns módulos foram instalados.

## Git e SSH

Comandos opcionais, não executados por `install all`:

```bash
bash setup.sh git 'Seu Nome' 'voce@example.com'
bash setup.sh ssh 'Seu Nome <voce@example.com>' --no-passphrase
```

Sem `--no-passphrase`, o SSH solicita uma senha. Usa Ed25519 e recusa
sobrescrever chaves. Somente a chave pública é exibida. Se você já criou sua
chave, mantenha a existente. Nenhuma chave ou senha é incluída no projeto.

## Laravel, banco e phpMyAdmin

A documentação atual consultada é do Laravel 13. Composer resolve o installer
disponível ao instalar. O PHP vem do Ubuntu: 8.3 no 24.04 e 8.5 no 26.04,
sem PPA adicional. Node e pnpm vêm do módulo `node`.

- phpMyAdmin: **http://localhost:8080/phpmyadmin**.
- MariaDB: `127.0.0.1:3306`.
- Usuário: `developer`, com acesso aos bancos cujo nome começa com `dev_`.
- Banco inicial: `dev_laravel`.
- Credenciais: `~/.config/script-up-server/mariadb.env`, permissão 600.

```bash
cat ~/.config/script-up-server/mariadb.env
cd ~/Projects
laravel new minha-api
```

Escolha MySQL/MariaDB e copie os campos `DB_*` para o `.env` do projeto. Use
`dev_laravel` ou crie um banco `dev_nome_do_projeto`. Consulte [web e banco](docs/web.md).

## Mobile

```bash
cd ~/Projects
pnpm create expo-app@latest meu-app
cd meu-app
pnpm exec expo start --tunnel
```

```bash
cd ~/Projects
flutter create meu_flutter
cd meu_flutter
flutter doctor -v
```

O SDK Android fica no WSL. Celular e emulador precisam ser conectados
separadamente. O emulador pode rodar no Windows; compilar iOS localmente exige
macOS/Xcode. Veja [mobile no WSL](docs/mobile.md).

## Organização e manutenção

| Local | Conteúdo |
| --- | --- |
| `setup.sh` | Comandos e perfis |
| `modules/` | Instaladores e diagnóstico |
| `lib/` | Pacotes, backups e utilitários compartilhados |
| `config/` | PATH, Zsh e paleta Dracula para Windows Terminal |
| `docs/` | Uso, migração e limitações |
| `tests/` | Testes isolados sem instalar serviços |
| `scripts-alias/` | Legado preservado; execução manual |

Backups: `~/.local/state/script-up-server/`. Reexecuções mantêm as credenciais
geradas e evitam duplicar linhas gerenciadas no shell. A recuperação de backups
é manual; não há rollback de pacotes. Node segue LTS e Flutter segue stable.
Repositórios existentes de temas e plugins não são atualizados automaticamente.

Em instalação nova, Apache e MariaDB usam loopback. Apache preexistente mantém
sites e portas; conflitos são sinalizados. O módulo web prepara ferramentas,
sem publicar aplicações em produção. Não altera firewall, acesso SSH ou dados
dos bancos existentes.

Veja [migração](docs/migracao.md) para os scripts anteriores e
[terminal](docs/terminal.md) para cores e fonte no WSL.

## Verificação

```bash
python3 -m unittest discover -s tests -v
```

A CI verifica sintaxe Bash/Zsh, testes e ShellCheck nos scripts novos.
`scripts-alias` mantém os originais e fica fora dessa análise. Instalação real
de pacotes e serviços precisa ser validada em uma máquina Ubuntu disponível.

## Referências

- [Laravel](https://laravel.com/docs/13.x/installation)
- [NVM](https://github.com/nvm-sh/nvm) e [pnpm](https://pnpm.io/installation)
- [Flutter Android](https://docs.flutter.dev/platform-integration/android/setup)
- [Expo](https://docs.expo.dev/get-started/create-a-project/)
- [Android tools](https://developer.android.com/studio#command-tools)
- [phpMyAdmin](https://docs.phpmyadmin.net/en/latest/setup.html)

Licença [MIT](LICENSE).
