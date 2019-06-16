#!/bin/sh

if $(wp core is-installed); then

    sudo -u www-data wp config set WP_CACHE true --raw --add --type=constant
    sudo -u www-data wp config set WP_REDIS_HOST $WP_REDIS_HOST --add --type=constant
    sudo -u www-data wp config set WP_REDIS_DATABASE $WP_REDIS_DATABASE --raw --add --type=constant
    sudo -u www-data wp config set WP_REDIS_PORT $WP_REDIS_PORT --raw --add --type=constant
    
    sudo -u www-data wp plugin install redis-cache --force --activate
    sudo -u www-data wp redis enable
    sudo -u www-data wp redis update-dropin

    chmod +777 /var/www/html/wp-content/advanced-cache.php

fi
