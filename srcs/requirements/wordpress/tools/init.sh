#!/bin/bash
set -e

WP_PATH=/var/www/html

DB_PASSWORD=$(cat /run/secrets/db_password)
. /run/secrets/credentials

if [ ! -f "$WP_PATH/wp-load.php" ]; then
    wp core download --path="$WP_PATH" --allow-root
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    wp config create \
        --path="$WP_PATH" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb:3306 \
        --allow-root
fi

if ! wp core is-installed --path="$WP_PATH" --allow-root; then
    wp core install \
        --path="$WP_PATH" \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --path="$WP_PATH" \
        --allow-root
fi

chown -R www-data:www-data "$WP_PATH"

exec php-fpm8.2 -F