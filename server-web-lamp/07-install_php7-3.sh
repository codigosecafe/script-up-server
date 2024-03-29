#!/bin/bash
echo "\n\n"
echo "#=============================================================================="
echo "# title       : INSTALL PHP7.3"
echo "# description : Script para instalacao do PHP7.3"
echo "# author      : Claudio Alexssandro Lino"
echo "# github      : https://github.com/codigosecafe"
echo "# version     : 1.0.0"
echo "#=============================================================================="
echo "\n"

cd ~/
apt-get update
aptitude install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
aptitude update -y
apt-cache pkgnames | grep php7.3
apt install php7.3 php7.3-common libphp7.3-embed -y
apt install php7.3-bz2 php7.3-cgi php7.3-cli php7.3-dba php7.3-dev php7.3-xdebug -y
apt install php7.3-bcmath php7.3-fpm php7.3-gmp php7.3-mysql php7.3-mysqli php7.3-tidy -y
apt install php7.3-sqlite3 php7.3-json php7.3-opcache php7.3-sybase php7.3-curl -y
apt install php7.3-ldap php7.3-phpdbg php7.3-imap php7.3-xml php7.3-xsl php7.3-intl -y
apt install php7.3-zip php7.3-odbc php7.3-mbstring php7.3-readline php7.3-gd php7.3-interbase -y
apt install php7.3-snmp php7.3-xmlrpc php7.3-soap php7.3-pspell php7.3-pgsql php7.3-enchant php7.3-recode php7.3-redis -y
apt-cache pkgnames | grep php7.3
a2enmod php7.3 
update-alternatives --set php /usr/bin/php7.3  
php -i | grep /etc/php/7.3/apache2/php.ini
php --ini

pecl uninstall xdebug
pecl install xdebug

/etc/init.d/apache2 restart
echo "\n"
echo "|----------------------------------------------------|"
echo "##### => Instalar o Composer"
echo "|----------------------------------------------------|"
cd ~/
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo "\n"
apt-get update 
apt-get -y upgrade 
apt-get -y clean
apt-get -y autoclean
echo "\n"

echo '<?php phpinfo(); ?>' > /var/www/html/showinfo.php
echo "DDD: $(find /usr/lib/php -name 'xdebug.so' -type f -printf "%p\n" | sort -nr | tail -1)"
echo "\n"
echo "#=========================== FIM DO SCRIPT ===================================="
echo "\n\n"
exit 