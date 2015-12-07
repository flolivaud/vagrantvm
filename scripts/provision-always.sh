#!/usr/bin/env bash

echo -e "\n=== Provision: Apache2 Vhosts ===\n"
DIR="/vagrant/scripts/vhosts"
FILES_LIST=$(find $DIR -type f -name "*.conf") 
PHP_VERSION=$1

if [[ $PHP_VERSION == "5.4" ]]; then
	folder_site="sites-enabled"
else
	folder_site="sites-available"
fi

for file in $FILES_LIST; do

	re="([a-zA-Z\_\-]+)*\.conf" 
	if [[ $file =~ $re  ]]; then 

		echo -e "\n >> Ajout du vhost ${BASH_REMATCH[1]}"
		cp $file /etc/apache2/$folder_site/${BASH_REMATCH[1]}.conf

		if [[ $PHP_VERSION != "5.4" ]]; then
			a2ensite ${BASH_REMATCH[1]} >/dev/null 2>&1
		fi
	fi
done

service apache2 restart >/dev/null 2>&1