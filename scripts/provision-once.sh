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

# ---------------------------------------
#          Gestion des depots
# ---------------------------------------

echo -e "\n--- Ajout des depots ---\n"

# --- PHP ---
if [[ $PHP_VERSION == "7" ]]; then
	add-apt-repository -y ppa:ondrej/php-7.0 >/dev/null 2>&1
elif [[ $PHP_VERSION == "5.4" ]]; then
	add-apt-repository -y ppa:ondrej/php5-oldstable >/dev/null 2>&1
elif [[ $PHP_VERSION == "5.5" ]]; then
	add-apt-repository -y ppa:ondrej/php5 >/dev/null 2>&1
elif [[ $PHP_VERSION == "5.6" ]]; then
	add-apt-repository -y ppa:ondrej/php5-5.6 >/dev/null 2>&1
fi

# --- Node.JS ---
add-apt-repository -y ppa:chris-lea/node.js >/dev/null 2>&1

# --- Ruby ---
apt-add-repository -y ppa:brightbox/ruby-ng >/dev/null 2>&1

echo -e "\n >> Mise a jour des depots\n"
apt-get update >/dev/null 2>&1

echo -e "\n--- TimeZone Europe/Paris ---\n"
echo "Europe/Paris" | sudo tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# ---------------------------------------
#          Apache Setup
# ---------------------------------------

echo -e "\n--- Installation et configuration d'apache ---\n"
apt-get install -y apache2 >/dev/null 2>&1
echo "ServerName localhost" > /etc/apache2/httpd.conf
a2enmod rewrite >/dev/null 2>&1

# ---------------------------------------
#          MySQL Setup
# ---------------------------------------

echo -e "\n--- Installation MySQL ---\n"
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password rootpass'
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password rootpass'
apt-get -y install mysql-server >/dev/null 2>&1

# ---------------------------------------
#          PHP Setup
# ---------------------------------------

echo -e "\n--- Installation PHP ${PHP_VERSION} ---\n"
if [[ $PHP_VERSION == "7" ]]; then
	apt-get install -y php7.0 php7.0-cli php7.0-common php7.0-curl php7.0-dev php7.0-gd php7.0-mysql php7.0-pgsql >/dev/null 2>&1
else
	apt-get install -y php5 php-pear php5-cli php5-common php5-curl php5-dev php5-gd php5-mcrypt php5-mysql php5-pgsql php5-xdebug >/dev/null 2>&1
fi

echo -e "\n >> Configuration de PHP\n"
if [[ $PHP_VERSION == "7" ]]; then
	echo "session.save_path = /var/lib/php/sessions" >> /etc/$php_dir/apache2/php.ini
	if [[ ! -e "/var/lib/php/sessions" ]]; then
    	mkdir /var/lib/php/sessions
	fi
	chmod 777 -R /var/lib/php/sessions
fi

DISPLAY_ERRORS="On"
MEMORY_LIMIT="1024M"
MAX_EXECUTION_TIME="600"
POST_MAX_SIZE="32M"
UPLOAD_MAX_FILESIZE="32M"
sed -i "s/display_errors = .*/display_errors = ${DISPLAY_ERRORS}/" /etc/$php_dir/apache2/php.ini
sed -i "s/memory_limit = .*/memory_limit = ${MEMORY_LIMIT}/" /etc/$php_dir/apache2/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = ${MAX_EXECUTION_TIME}/" /etc/$php_dir/apache2/php.ini
sed -i "s/post_max_size = .*/post_max_size = ${POST_MAX_SIZE}/" /etc/$php_dir/apache2/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = ${UPLOAD_MAX_FILESIZE}/" /etc/$php_dir/apache2/php.ini

# ---------------------------------------
#          Ruby Setup
# ---------------------------------------

echo -e "\n--- Installation Ruby 1.9.3\n"
apt-get install -y ruby1.9.3 >/dev/null 2>&1

# ---------------------------------------
#          Utilities Setup
# ---------------------------------------
echo -e "\n--- Installation Utilitaires ---\n"

# --- NodeJS ---
echo -e "\n >> NodeJS\n"
apt-get install -y nodejs git >/dev/null 2>&1

# --- Composer ---
echo -e "\n >> Composer\n"
curl -s https://getcomposer.org/installer | php >/dev/null 2>&1
mv composer.phar /usr/local/bin/composer

# --- XDebug ---
if [[ $PHP_VERSION == "7" ]]; then
    echo -e "\n >> XDebug\n"
    cd /tmp
	wget -q http://xdebug.org/files/xdebug-2.4.0rc2.tgz
	tar -xzf xdebug-2.4.0rc2.tgz
	cd xdebug-2.4.0RC2/
	phpize >/dev/null 2>&1
	./configure >/dev/null 2>&1
	make >/dev/null 2>&1
	cp modules/xdebug.so /usr/lib/php/20151012
	echo "zend_extension = /usr/lib/php/20151012/xdebug.so" >> /etc/php/7.0/apache2/php.ini
fi

# --- phpMyAdmin ---
if [[ ! -d "/var/www/phpmyadmin" ]]; then
	pma_version_link="http://www.phpmyadmin.net/home_page/version.php"
	pma_latest_version=$(wget -q -O /tmp/phpMyAdmin_Update.html $pma_version_link && sed -ne '1p' /tmp/phpMyAdmin_Update.html);
	echo -e "\n >> phpMyAdmin ($pma_latest_version)\n"
	cd /tmp
	mkdir /var/www/phpmyadmin
	wget -q https://files.phpmyadmin.net/phpMyAdmin/$pma_latest_version/phpMyAdmin-$pma_latest_version-all-languages.tar.gz --no-check-certificate
	tar -xzf phpMyAdmin-$pma_latest_version-all-languages.tar.gz >/dev/null 2>&1
	cp phpMyAdmin-$pma_latest_version-all-languages/* /var/www/phpmyadmin/ -R
	rm -R phpMyAdmin-$pma_latest_version-all-languages
	cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php
fi

# --- MailCatcher ---
echo -e "\n >> MailCatcher\n"
apt-get install -y libsqlite3-dev >/dev/null 2>&1
gem install mailcatcher >/dev/null 2>&1

echo -e "\n >> Configuration Mailcatcher\n"
echo "sendmail_path = /usr/bin/env $(which catchmail) -f test@local.dev" >> /etc/$php_dir/apache2/php.ini
echo "sendmail_path = /usr/bin/env $(which catchmail) -f test@local.dev" >> /etc/$php_dir/cli/php.ini
/usr/bin/env $(which mailcatcher) --ip=0.0.0.0 >/dev/null 2>&1

echo -e "\n--- Installation NPMs ---\n"
npm install -g bower gulp cordova phonegap ionic >/dev/null 2>&1

if [[ -e "/vagrant/scripts/custom.sh" ]]; then
    chmod +x /vagrant/scripts/custom.sh
    . /vagrant/scripts/custom.sh
fi