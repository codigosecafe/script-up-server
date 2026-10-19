# Migração

## Estrutura antiga

`server-web-lamp/`, `ambiente-flutter-ubuntu/` e `utils/` foram substituídas por
`setup.sh`, módulos e documentação. As versões antigas continuam no histórico
Git e a licença MIT original foi mantida.

`scripts-alias/` permanece byte a byte como estava, inclusive os caminhos fixos
e scripts de manutenção antigos. Revise cada script antes de executá-lo. Essa
pasta não é carregada nem executada pelo instalador.

## Scripts soltos anteriores

Os arquivos de `~/dev-setup/` e `~/terminal-setup/` foram incorporados ao projeto.
Use os novos comandos. Os arquivos soltos não são apagados automaticamente.

O módulo terminal substitui a linha
`source "$HOME/.config/zsh/rocketseat.zsh"` pela nova configuração e salva backup.
Personalizações no arquivo antigo precisam ser transferidas para seu `.zshrc`.

Se já executou o instalador anterior de desenvolvimento:

1. Preserve `~/.config/devagress/mariadb.env`: a conta nova `developer` é
   independente da conta anterior `devagress` e usa bancos `dev_*`.
2. Revise os `.env` antes de trocar conta ou banco.
3. Depois de instalar os módulos novos, remova manualmente a linha que carrega
   `~/.config/devagress/env.sh` do Bash/Zsh para evitar duplicar o PATH.

## Apache anterior

O módulo web interrompe a configuração se o site anterior `devagress.conf` está
habilitado. Para migrar, salve os arquivos e desabilite esse site:

```bash
mkdir -p ~/apache-migracao
sudo cp -a /etc/apache2/ports.conf /etc/apache2/sites-available/devagress.conf ~/apache-migracao/
sudo a2dissite devagress
sudoedit /etc/apache2/ports.conf
```

Remova somente o `Listen 127.0.0.1:8080` gerado pelo instalador anterior; preserve
outras portas. O novo módulo declara 8080 em sua própria configuração. Execute:

```bash
bash setup.sh install web
```

Conflitos com outros sites ou serviços na porta 8080 precisam ser resolvidos
antes. Não é necessário remover bancos ou desinstalar MariaDB.
