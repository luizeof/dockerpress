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

echo "Updating my.cnf ..."
sed -i -e "s/MYUSER/$WORDPRESS_DB_USER/g" /root/.my.cnf
sed -i -e "s/MYPASSWORD/$WORDPRESS_DB_PASSWORD/g" /root/.my.cnf
sed -i -e "s/MYHOST/$WORDPRESS_DB_HOST/g" /root/.my.cnf
sed -i -e "s/MYDATABASE/$WORDPRESS_DB_NAME/g" /root/.my.cnf

echo "Sleeping 30s waiting mysql service ready..."
sleep 30

# Creating Wordpress Database
if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
  echo "Try create Database if not exists using root ..."
  mysql -h $WORDPRESS_DB_HOST -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;";
else
  echo "Try create Database if not exists using $WORDPRESS_DB_USER user ..."
  mysql -h $WORDPRESS_DB_HOST -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;";
fi

# Creating Wordpress User
if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
  echo "Try to create user $WORDPRESS_DB_USER with all privileges on $WORDPRESS_DB_NAME ..."
  mysql -h $WORDPRESS_DB_HOST -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@'%' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';";
  mysql -h $WORDPRESS_DB_HOST -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;";
fi

chown -R www-data:www-data /var/www/html/

if [ ! -e wp-config.php ]; then

  echo "Wordpress not found, downloading latest version ..."
  wp core download --locale=$WP_LOCALE --path=/var/www/html

  echo "Creating wp-config.file ..."
  cp /var/www/wp-config-sample.php /var/www/html/wp-config.php
  chown www-data:www-data /var/www/html/wp-config.php

  echo "Shuffling wp-config.php salts ..."
  wp config shuffle-salts

  echo "Updating Database Info on wp-config.file "
  wp config set DB_NAME $WORDPRESS_DB_NAME --add --type=constant
  wp config set DB_USER $WORDPRESS_DB_USER --add --type=constant
  wp config set DB_PASSWORD $WORDPRESS_DB_PASSWORD --add --type=constant
  wp config set DB_HOST $WORDPRESS_DB_HOST --add --type=constant

  # if Wordpress is installed
  if ! $(wp core is-installed); then
    echo "Creating $WORDPRESS_DB_NAME database on if not exists ..."
    echo "Installing Wordpress at $VIRTUAL_HOST ..."
    wp core install --url=$VIRTUAL_HOST \
                  --title=Wordpress \
                  --admin_user=dockerpress \
                  --admin_password=dockerpress \
                  --admin_email=dockerpress@dockerpress.com.br \
                  --skip-email \
                  --path=/var/www/html
    echo "Done Installing."
  fi

  wp rewrite structure '/%postname%/'

fi

echo "Updating wp-config.php ..."
wp config set WP_SITEURL "https://$VIRTUAL_HOST" --add --type=constant
wp config set WP_HOME "https://$VIRTUAL_HOST" --add --type=constant
wp config set DB_NAME $WORDPRESS_DB_NAME --add --type=constant
wp config set DB_USER $WORDPRESS_DB_USER --add --type=constant
wp config set DB_PASSWORD $WORDPRESS_DB_PASSWORD --add --type=constant
wp config set DB_HOST $WORDPRESS_DB_HOST --add --type=constant
wp config set WP_DEBUG $WP_DEBUG --raw --add --type=constant

# Redis Cache
if [ -n "$WP_REDIS_HOST" ]; then
  wp config set WP_CACHE true --raw --add --type=constant
  wp config set WP_REDIS_HOST $WP_REDIS_HOST --add --type=constant
  wp config set WP_REDIS_DATABASE $WP_REDIS_DATABASE --raw --add --type=constant
  wp config set WP_REDIS_PORT $WP_REDIS_PORT --raw --add --type=constant
  wp config set WP_CACHE_KEY_SALT $VIRTUAL_HOST --add --type=constant

  if [ -n "$WP_REDIS_PASSWORD" ]; then
    wp config set WP_REDIS_PASSWORD $WP_REDIS_PASSWORD --add --type=constant
  else
    echo "Redis password not set. Try to create a more secure redis setup."
  fi
fi


echo "wp-config.php updated."

if [ ! -e /var/www/html/.htaccess ]; then
  echo ".htaccess not found, copying now ..."
  cp -f /var/www/.htaccess-template /var/www/html/.htaccess
  chown www-data:www-data /var/www/html/.htaccess
fi

# Redis Cache
if [ -n "$WP_REDIS_HOST" ]; then
  echo "Enabling Redis Cache ..."
  rm -f /var/www/html/wp-content/object-cache.php
  wp plugin install redis-cache --force --activate
  wp redis enable
  wp redis update-dropin
  chmod +777 /var/www/html/wp-content/object-cache.php
fi

# Enabling WPVULN Daily Report
if [ -n "$VULN_API_TOKEN" ]; then
  echo "Enabling VULN Daily report ..."
  sed -i -e "s/ADMIN_EMAIL/$ADMIN_EMAIL/g" /usr/local/bin/wpcli-run-vuln-send-report
  sed -i -e "s/VIRTUAL_HOST/$VIRTUAL_HOST/g" /usr/local/bin/wpcli-run-vuln-send-report
  wp package install git@github.com:10up/wp-vulnerability-scanner.git
  wp config set VULN_API_TOKEN $VULN_API_TOKEN --add --type=constant
  echo '4 25 * * * root wpcli-run-vuln-generate' >> /etc/cron.d/dockerpress
  echo '5 45 * * * root wpcli-run-vuln-send-report' >> /etc/cron.d/dockerpress
fi

if [ "$CRON_ACTIONSCHEDULER" -eq 1 ]; then
  echo "CRON: Enabling Action Scheduler ..."
  echo '*/2 * * * * root /usr/local/bin/wpcli-run-schedule' >> /etc/cron.d/dockerpress
  echo '*/3 * * * * root /usr/local/bin/wpcli-run-actionscheduler' >> /etc/cron.d/dockerpress
  echo '* 5 * * * root /usr/local/bin/wpcli-run-clear-scheduler-log' >> /etc/cron.d/dockerpress
fi

if [ "$CRON_MEDIA_REGENERATE" -eq 1 ]; then
  echo "CRON: Enabling Media Regenerate ..."
  echo '1 20 * * * root /usr/local/bin/wpcli-run-media-regenerate' >> /etc/cron.d/dockerpress
fi

if [ "$CRON_CLEAR_TRANSIENT" -eq 1 ]; then
  echo "CRON: Enabling Clear Transients ..."
  echo '2 30 * * * root /usr/local/bin/wpcli-run-delete-transient' >> /etc/cron.d/dockerpress
fi

echo '' >> /etc/cron.d/dockerpress
chmod 644 /etc/cron.d/dockerpress

service cron start
service cron reload

chown -R www-data:www-data /var/www/html/

unset MYSQL_ROOT_PASSWORD

sysvbanner dockerpress

exec "$@"
