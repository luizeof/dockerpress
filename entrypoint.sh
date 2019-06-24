#!/bin/bash

mkdir -p $WP_CLI_CACHE_DIR
chown -R www-data:www-data $WP_CLI_CACHE_DIR
mkdir -p $WP_CLI_PACKAGES_DIR
chown -R www-data:www-data $WP_CLI_PACKAGES_DIR
rm -f /var/www/wp-cli.phar
curl -o /var/www/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /var/www/wp-cli.phar

if $(wp core is-installed); then

    wp config set WP_CACHE true --raw --add --type=constant
    wp config set WP_REDIS_HOST $WP_REDIS_HOST --add --type=constant
    wp config set WP_REDIS_DATABASE $WP_REDIS_DATABASE --raw --add --type=constant
    wp config set WP_REDIS_PORT $WP_REDIS_PORT --raw --add --type=constant

    rm -f /var/www/html/wp-content/object-cache.php
    wp plugin install redis-cache --force --activate
    wp redis enable
    wp redis update-dropin
    chmod +777 /var/www/html/wp-content/object-cache.php

fi

service cron start
service cron reload

exec /usr/local/bin/docker-entrypoint.sh "$@"
