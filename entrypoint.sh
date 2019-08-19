#!/bin/bash

# Setup wp-cli
echo "Setting up wp-cli..."
rm -rf /var/www/.wp-cli/
mkdir -p $WP_CLI_CACHE_DIR
chown -R www-data:www-data $WP_CLI_CACHE_DIR
rm -rf $WP_CLI_PACKAGES_DIR
mkdir -p $WP_CLI_PACKAGES_DIR
chown -R www-data:www-data $WP_CLI_PACKAGES_DIR
rm -f /var/www/wp-cli.phar
curl -o /var/www/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /var/www/wp-cli.phar
echo "Done"

chown -R www-data:www-data /var/www/html/

if [ ! -e wp-config.php ]; then

  echo "Wordpress not found, downloading latest version ..."
  wp core download --locale=$WP_LOCALE --path=/var/www/html

  echo "Creating wp-config.file ..."
  wp config create --dbname=$WORDPRESS_DB_NAME \
                   --dbuser=$WORDPRESS_DB_USER \
                   --dbpass=$WORDPRESS_DB_PASSWORD \
                   --dbhost=$WORDPRESS_DB_HOST \
                   --locale=$WP_LOCALE \
                   --skip-check \
                   --path=/var/www/html
                   --extra-php "
                     if ($_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')
                         $_SERVER['HTTPS'] = '1';

                     if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
                         $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
                     }
                   "

  echo "Shuffling wp-config.php salts ..."
  wp config shuffle-salts
  if ! $(wp core is-installed); then
    echo "Creating $WORDPRESS_DB_NAME database on if not exists ..."
    wp db create
    echo "Installing Wordpress at $VIRTUAL_HOST ..."
    wp core install --url=$VIRTUAL_HOST \
                  --title=DockerPress \
                  --admin_user=dockerpress \
                  --admin_password=dockerpress \
                  --admin_email=dockerpress@dockerpress.com.br \
                  --skip-email \
                  --path=/var/www/html
    echo "Done Installing."
  fi

fi

if [ ! -e /var/www/html/.htaccess ]; then
  echo ".htaccess not found, copying now ..."
  cp -f /var/www/.htaccess-template /var/www/html/.htaccess
  chown www-data:www-data /var/www/html/.htaccess
fi

wp config set WP_SITEURL "https://$VIRTUAL_HOST" --add --type=constant
wp config set WP_HOME "https://$VIRTUAL_HOST" --add --type=constant

# Enabling WPVULN Daily Report
if [ -n "$VULN_API_TOKEN" ]; then
  sed -i -e "s/ADMIN_EMAIL/$ADMIN_EMAIL/g" /usr/local/bin/wpcli-vuln-send-report
  sed -i -e "s/VIRTUAL_HOST/$VIRTUAL_HOST/g" /usr/local/bin/wpcli-vuln-send-report
  wp package install git@github.com:10up/wp-vulnerability-scanner.git
  wp config set VULN_API_TOKEN $VULN_API_TOKEN --add --type=constant
  echo '4 25 * * * root wpcli-vuln-generate' >> /etc/cron.d/dockerpress
  echo '5 45 * * * root wpcli-vuln-send-report' >> /etc/cron.d/dockerpress
fi

if [ "$CRON_ACTIONSCHEDULER" -eq 1 ]; then
  echo '*/2 * * * * root /usr/local/bin/wpcli-run-schedule' >> /etc/cron.d/dockerpress
  echo '*/3 * * * * root /usr/local/bin/wpcli-run-actionscheduler' >> /etc/cron.d/dockerpress
  echo '* 5 * * * root /usr/local/bin/wpcli-clear-scheduler-log' >> /etc/cron.d/dockerpress
fi

if [ "$CRON_MEDIA_REGENERATE" -eq 1 ]; then
  echo '1 20 * * * root /usr/local/bin/wpcli-media-regenerate' >> /etc/cron.d/dockerpress
fi

if [ "$CRON_CLEAR_TRANSIENT" -eq 1 ]; then
  echo '2 30 * * * root /usr/local/bin/wp transient delete --expired --path=/var/www/html' >> /etc/cron.d/dockerpress
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

echo '' >> /etc/cron.d/dockerpress
chmod 644 /etc/cron.d/dockerpress
service cron start
service cron reload

chown -R www-data:www-data /var/www/html/

exec "$@"
