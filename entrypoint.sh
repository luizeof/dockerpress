#!/bin/bash

if $(wp core is-installed); then

    echo "Setting up Redis..."

    wp config set WP_CACHE true --raw --add --type=constant
    wp config set WP_REDIS_HOST $WP_REDIS_HOST --add --type=constant
    wp config set WP_REDIS_DATABASE $WP_REDIS_DATABASE --raw --add --type=constant
    wp config set WP_REDIS_PORT $WP_REDIS_PORT --raw --add --type=constant

    wp plugin install redis-cache --force --activate
    wp redis enable
    wp redis update-dropin

    chmod +777 /var/www/html/wp-content/advanced-cache.php

    echo "Done."

fi

service cron start

service cron reload

exec /usr/local/bin/docker-entrypoint.sh "$@"
