#!/usr/bin/env bash
install_web() {
  section 'PHP, Laravel, MariaDB e phpMyAdmin'
  local fresh_apache=0
  if [[ -f /etc/apache2/sites-enabled/devagress.conf ]]; then
    die 'Apache usa o instalador anterior. Consulte docs/migracao.md antes de instalar web.'
  fi
  [[ -f /etc/apache2/ports.conf ]] || fresh_apache=1
  apt_install ca-certificates curl git unzip openssl php-cli php-curl php-mbstring \
    php-xml php-zip php-bcmath php-intl php-sqlite3 php-mysql php-pgsql composer
  php -r 'if (PHP_VERSION_ID < 80300) {fwrite(STDERR,"Laravel 13 exige PHP >= 8.3\n"); exit(1);}'
  printf 'phpmyadmin phpmyadmin/dbconfig-install boolean false\nphpmyadmin phpmyadmin/reconfigure-webserver multiselect\n' | sudo debconf-set-selections
  apt_install mariadb-server mariadb-client apache2 libapache2-mod-php phpmyadmin
  composer global require laravel/installer --no-interaction --prefer-dist
  local composer_bin
  composer_bin="$(composer global config bin-dir --absolute --quiet)"
  backup_file "$HOME/.local/bin/laravel"
  ln -sfn "$composer_bin/laravel" "$HOME/.local/bin/laravel"

  backup_file /etc/mysql/mariadb.conf.d/99-script-up-server.cnf
  sudo tee /etc/mysql/mariadb.conf.d/99-script-up-server.cnf >/dev/null <<'CONF'
[mysqld]
bind-address = 127.0.0.1
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
CONF
  restart_service mariadb
  configure_database
  configure_phpmyadmin "$fresh_apache"
  php --version
  composer --version
  "$HOME/.local/bin/laravel" --version
  php -r 'foreach (["bcmath","ctype","curl","dom","fileinfo","filter","hash","intl","mbstring","openssl","pcre","PDO","pdo_mysql","session","tokenizer","xml","zip"] as $ext) {if (!extension_loaded($ext)) {fwrite(STDERR,"Extensão ausente: $ext\n"); exit(1);}} echo "Extensões PHP: OK\n";'
  php -r '$p=parse_ini_file($argv[1]); new PDO("mysql:host=127.0.0.1;dbname=dev_laravel", $p["DB_USERNAME"], $p["DB_PASSWORD"]); echo "Login MariaDB: OK\n";' "$CONFIG_DIR/mariadb.env"
  curl -fsSL -o /dev/null http://127.0.0.1:8080/phpmyadmin/
  printf 'phpMyAdmin: http://localhost:8080/phpmyadmin\nCredenciais: %s/mariadb.env\n' "$CONFIG_DIR"
}

configure_database() {
  local credentials="$CONFIG_DIR/mariadb.env" db_password existing
  if [[ -f "$credentials" ]]; then
    db_password="$(sed -n 's/^DB_PASSWORD=//p' "$credentials")"
    [[ "$db_password" =~ ^[a-f0-9]{48}$ ]] || die 'Senha salva com formato inesperado. Verifique mariadb.env.'
  else
    existing="$(sudo mariadb --batch --skip-column-names -e "SELECT COUNT(*) FROM mysql.user WHERE User='developer' AND Host='localhost';")"
    [[ "$existing" == 0 ]] || die 'Usuário developer já existe sem credencial gerenciada. Não será alterado.'
    db_password="$(openssl rand -hex 24)"
    (umask 077; printf 'DB_CONNECTION=mysql\nDB_HOST=127.0.0.1\nDB_PORT=3306\nDB_DATABASE=dev_laravel\nDB_USERNAME=developer\nDB_PASSWORD=%s\n' "$db_password" > "$credentials")
  fi
  sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS dev_laravel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'developer'@'localhost' IDENTIFIED BY '${db_password}';
ALTER USER 'developer'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`dev\\_%\`.* TO 'developer'@'localhost';
SQL
  chmod 600 "$credentials"
}

configure_phpmyadmin() {
  local fresh_apache="$1" file
  # Instalação nova usa somente loopback. Apache preexistente mantém portas/sites.
  if (( fresh_apache )); then
    backup_file /etc/apache2/ports.conf
    sudo tee /etc/apache2/ports.conf >/dev/null <<'CONF'
# Portas adicionais são gerenciadas em conf-available/script-up-server-ports.conf.
CONF
    sudo a2dissite 000-default >/dev/null
  fi
  for file in /etc/apache2/conf-available/script-up-server-ports.conf /etc/apache2/sites-available/script-up-server.conf; do
    backup_file "$file"
  done
  if grep -Eq '^[[:space:]]*Listen[[:space:]]+([^#]*:)?8080([[:space:]]|$)' /etc/apache2/ports.conf; then
    die 'A porta 8080 já está declarada em ports.conf. Consulte docs/migracao.md.'
  fi
  sudo tee /etc/apache2/conf-available/script-up-server-ports.conf >/dev/null <<'CONF'
Listen 127.0.0.1:8080
CONF
  sudo tee /etc/apache2/sites-available/script-up-server.conf >/dev/null <<'CONF'
<VirtualHost 127.0.0.1:8080>
    ServerName localhost
    DocumentRoot /var/www/html
    Include /etc/phpmyadmin/apache.conf
    <Location /phpmyadmin>
        Require local
    </Location>
    ErrorLog ${APACHE_LOG_DIR}/script-up-server-error.log
    CustomLog ${APACHE_LOG_DIR}/script-up-server-access.log combined
</VirtualHost>
CONF
  sudo a2enconf script-up-server-ports >/dev/null
  sudo a2ensite script-up-server >/dev/null
  sudo apache2ctl configtest
  restart_service apache2
}
