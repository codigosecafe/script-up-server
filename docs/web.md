# Web e banco

```bash
bash setup.sh install node
bash setup.sh install web
```

## MariaDB

`developer` tem acesso a bancos `dev_*`, sem privilégios administrativos globais
ou permissão para conceder privilégios. Root mantém a autenticação por socket:

```bash
sudo mariadb
```

Crie bancos separados pelo phpMyAdmin ou pelo cliente:

```bash
mariadb -h 127.0.0.1 -u developer -p -e 'CREATE DATABASE dev_meu_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;'
```

Consulte a senha em `~/.config/script-up-server/mariadb.env`. Não publique esse
arquivo. Reexecuções mantêm a senha. O instalador não remove MySQL/MariaDB
existentes nem desativa SQL mode. Se já existir `developer@localhost` sem
credencial gerenciada, a criação é interrompida para preservar a conta.

## Laravel com pnpm

```bash
cd ~/Projects
laravel new meu-app
cd meu-app
```

Configure no `.env` os campos do arquivo privado, ajustando o banco. Depois:

```bash
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

Se houver frontend, em outro terminal na pasta do projeto:

```bash
pnpm install
pnpm run dev
```

Abra http://localhost:8000 no Windows. Vite normalmente usa a porta 5173.

## Serviços no WSL

Com systemd, os serviços são habilitados quando a distribuição inicia:

```bash
systemctl status mariadb apache2 --no-pager
```

Sem systemd, inicie manualmente a cada sessão:

```bash
sudo service mariadb start
sudo service apache2 start
```

## VPS

Execute como usuário normal com sudo. Domínio, HTTPS, PHP-FPM, filas e publicação
da aplicação são configurações específicas de cada implantação.

O phpMyAdmin usa loopback. Crie um túnel a partir do seu computador:

```bash
ssh -N -L 8080:127.0.0.1:8080 usuario@IP_DA_VPS
```

Abra http://localhost:8080/phpmyadmin. Se a porta local estiver ocupada, use
`-L 8082:127.0.0.1:8080` e abra localhost:8082.

Apache preexistente mantém portas e sites. A restrição local vale para o novo
virtual host do phpMyAdmin. Se phpMyAdmin já estiver habilitado globalmente por
outra configuração, revise essa configuração separadamente.
