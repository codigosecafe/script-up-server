#!/bin/bash
echo "\n\n"
echo "#=============================================================================="
echo "# title       : ENABLE PHP7.4"
echo "# description : Script para instalacao do PHP7.4"
echo "# author      : Claudio Alexssandro Lino"
echo "# github      : https://github.com/codigosecafe"
echo "# version     : 1.0.0"
echo "#=============================================================================="
echo "\n"

cd ~/
a2enmod php7.4 
update-alternatives --set php /usr/bin/php7.4  
php -i | grep /etc/php/7.4/apache2/php.ini
php --ini
/etc/init.d/apache2 restart
echo "\n"
echo "#=========================== FIM DO SCRIPT ===================================="
echo "\n\n"
exit 