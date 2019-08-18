#!/bin/bash

exec /usr/local/bin/docker-entrypoint.sh

# Setup wp-cli
echo "Setting up wp-cli..."
mkdir -p $WP_CLI_CACHE_DIR
chown -R www-data:www-data $WP_CLI_CACHE_DIR
mkdir -p $WP_CLI_PACKAGES_DIR
chown -R www-data:www-data $WP_CLI_PACKAGES_DIR
rm -f /var/www/wp-cli.phar
curl -o /var/www/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /var/www/wp-cli.phar
echo "Done"

wp config set WP_SITEURL "https://$VIRTUAL_HOST" --add --type=constant
wp config set WP_HOME "https://$VIRTUAL_HOST" --add --type=constant

# Enabling WPVULN Daily Report
if [ -n "$VULN_API_TOKEN" ]; then
  sed -i -e "s/ADMIN_EMAIL/$ADMIN_EMAIL/g" /usr/bin/wpcli-vuln
  sed -i -e "s/VIRTUAL_HOST/$VIRTUAL_HOST/g" /usr/bin/wpcli-vuln
  wp package install git@github.com:10up/wp-vulnerability-scanner.git
  wp config set VULN_API_TOKEN $VULN_API_TOKEN --add --type=constant
  echo '4 25 * * * root wpcli-vuln-generate' >> /etc/cron.d/dockerpress
  echo '5 45 * * * root wpcli-vuln-send-report' >> /etc/cron.d/dockerpress
fi

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
    wp redis status
fi

echo '' > /etc/cron.d/dockerpress
chmod 644 /etc/cron.d/dockerpress
service cron start
service cron reload

exec "$@"
