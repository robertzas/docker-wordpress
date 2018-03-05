#!/bin/bash

# terminate on errors
set -e

MARIADB_DATA_DIR=/home/data/mysql
DATABASE_USERNAME=${DATABASE_USERNAME:-"wordpress"}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-"abc123"}
DATABASE_NAME=${DATABASE_NAME:-"azurelocaldb"}
DATABASE_HOST=${DATABASE_HOST:-"localhost"}
DATABASE_ROOT_PASSWORD=${DATABASE_ROOT_PASSWORD:-"rootpwd"}

# init mariadb

if [ -d "/run/mysqld" ]; then
	echo "[i] mysqld already present, skipping creation"
	chown -R mysql:mysql /run/mysqld
else
	echo "[i] mysqld not found, creating...."
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
fi

if [ -d /var/lib/mysql/mysql ]; then
	echo "[i] MySQL directory already present, skipping creation"
	chown -R mysql:mysql /var/lib/mysql
else
	echo "[i] MySQL data directory not found, creating initial DBs"

	chown -R mysql:mysql /var/lib/mysql

	mysql_install_db --user=mysql > /dev/null

	tfile=`mktemp`
	if [ ! -f "$tfile" ]; then
	    return 1
	fi

	cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' identified by '$DATABASE_ROOT_PASSWORD' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
EOF

	if [ "$DATABASE_NAME" != "" ]; then
	    echo "[i] Creating database: $DATABASE_NAME"
	    echo "CREATE DATABASE IF NOT EXISTS \`$DATABASE_NAME\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

	    if [ "$DATABASE_USERNAME" != "" ]; then
		echo "[i] Creating user: $DATABASE_USERNAME with password $DATABASE_PASSWORD"
		echo "GRANT ALL ON \`$DATABASE_NAME\`.* to '$DATABASE_USERNAME'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';" >> $tfile
	    fi
	fi

    # cat $tfile

	/usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < $tfile
	rm -f $tfile

fi

# Check if volume is empty
if [ ! "$(ls -A "/var/www/wp-content" 2>/dev/null)" ]; then
    echo 'Setting up wp-content volume'
    # Copy wp-content from Wordpress src to volume
    cp -r /usr/src/wordpress/wp-content /var/www/
    chown -R www-data:www-data /var/www

    # Generate secrets
    curl -f https://api.wordpress.org/secret-key/1.1/salt/ >> /usr/src/wordpress/wp-secrets.php

    sed -i "s/getenv('DATABASE_NAME')/${DATABASE_NAME}/g" /usr/src/wordpress/wp-config.php
    sed -i "s/getenv('DATABASE_USERNAME')/${DATABASE_USERNAME}/g" /usr/src/wordpress/wp-config.php
    sed -i "s/getenv('DATABASE_PASSWORD')/${DATABASE_PASSWORD}/g" /usr/src/wordpress/wp-config.php
    sed -i "s/getenv('DATABASE_HOST')/${DATABASE_HOST}/g" /usr/src/wordpress/wp-config.php
fi

exec "$@"
