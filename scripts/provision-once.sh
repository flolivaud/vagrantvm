#!/usr/bin/env bash

VAGRANT_PROVISION_DIR="/var/vagrant_provision"
PHP_VERSION=$1

if [ -e $VAGRANT_PROVISION_DIR ]; then
    exit 0
fi

if [[ $PHP_VERSION == "7" ]]; then
	php_dir="php/7.0"
else
	php_dir="php5"
fi

mkdir $VAGRANT_PROVISION_DIR

echo -e "\n--- Ajout des depots ---\n"

# PHP
if [[ $PHP_VERSION == "7" ]]; then
	add-apt-repository -y ppa:ondrej/php-7.0 >/dev/null 2>&1
elif [[ $PHP_VERSION == "5.4" ]]; then
	add-apt-repository -y ppa:ondrej/php5-oldstable >/dev/null 2>&1
elif [[ $PHP_VERSION == "5.5" ]]; then
	add-apt-repository -y ppa:ondrej/php5 >/dev/null 2>&1
elif [[ $PHP_VERSION == "5.6" ]]; then
	add-apt-repository -y ppa:ondrej/php5-5.6 >/dev/null 2>&1
fi

# Node.JS
add-apt-repository -y ppa:chris-lea/node.js >/dev/null 2>&1

# Mailhog
echo "deb http://repo.deogracia.xyz/debian precise contrib" >> /etc/apt/sources.list.d/mailhog-debian-package.list
wget -q -O - http://l.deogracia.xyz/2 | sudo apt-key add - >/dev/null 2>&1

echo -e "\n--- Mise a jour des depots ---\n"
apt-get update >/dev/null 2>&1

echo -e "\n--- Installation et configuration d'apache ---\n"
apt-get install -y apache2 >/dev/null 2>&1
echo "ServerName localhost" > /etc/apache2/httpd.conf
a2enmod rewrite >/dev/null 2>&1

echo -e "\n--- Installation PHP ${PHP_VERSION} ---\n"
if [[ $PHP_VERSION == "7" ]]; then
	apt-get install -y php7.0 php7.0-cli php7.0-common php7.0-curl php7.0-dev php7.0-gd php7.0-mysql php7.0-pgsql >/dev/null 2>&1
else
	apt-get install -y php5 php-pear php5-cli php5-common php5-curl php5-dev php5-gd php5-mcrypt php5-mysql php5-pgsql php5-xdebug >/dev/null 2>&1
fi


echo -e "\n--- Installation Node.JS ---\n"
apt-get install -y nodejs >/dev/null 2>&1

echo -e "\n--- Installation GIT ---\n"
apt-get install -y git >/dev/null 2>&1

echo -e "\n--- Installation Composer ---\n"
curl -s https://getcomposer.org/installer | php >/dev/null 2>&1
mv composer.phar /usr/local/bin/composer

echo -e "\n--- Installation de Mailhog ---\n"
apt-get install -y mailhog >/dev/null 2>&1
service mailhog stop
cd /usr/sbin/
wget -q https://github.com/mailhog/MailHog/releases/download/v0.1.8/MailHog_linux_amd64 >/dev/null 2>&1
mv MailHog_linux_amd64 mailhog
chmod +x mailhog
service mailhog start
echo "sendmail_path = /usr/sbin/mailhog sendmail test@local.dev" >> /etc/$php_dir/apache2/php.ini