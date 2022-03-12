#!/bin/bash

# Force this for PHP 7.4 compatibility
docker-php-ext-enable imagick

#### Setting Up Env

touch /var/www/.wp_address
touch /var/www/.s3_access_key
touch /var/www/.s3_region
touch /var/www/.s3_secret_key
touch /var/www/.s3_bucket_name
touch /var/www/.wp_db_host
touch /var/www/.wp_db_user
touch /var/www/.wp_db_password
touch /var/www/.wp_db_name
touch /var/www/.wp_db_preffix
touch /var/www/.wp_db_port

echo $VIRTUAL_HOST >/var/www/.wp_address
echo $WORDPRESS_DB_HOST >/var/www/.wp_db_host
echo $WORDPRESS_DB_USER >/var/www/.wp_db_user
echo $WORDPRESS_DB_PASSWORD >/var/www/.wp_db_password
echo $WORDPRESS_DB_NAME >/var/www/.wp_db_name
echo $WORDPRESS_DB_PORT >/var/www/.wp_db_port

#### S3 Backup Settigns

echo $S3_ACCESS_KEY_ID >/var/www/.s3_access_key
echo $AWS_DEFAULT_REGION >/var/www/.s3_region
echo $S3_SECRET_ACCESS_KEY >/var/www/.s3_secret_key
echo $S3_BUCKET_NAME >/var/www/.s3_bucket_name

#### Setting Up MySQL Client Defaults

echo "Updating my.cnf ..."
mv /root/.my.cnf.sample /root/.my.cnf
sed -i -e "s/MYUSER/$WORDPRESS_DB_USER/g" /root/.my.cnf
sed -i -e "s/MYPASSWORD/$WORDPRESS_DB_PASSWORD/g" /root/.my.cnf
sed -i -e "s/MYHOST/$WORDPRESS_DB_HOST/g" /root/.my.cnf
sed -i -e "s/MYDATABASE/$WORDPRESS_DB_NAME/g" /root/.my.cnf
sed -i -e "s/MYPORT/$WORDPRESS_DB_PORT/g" /root/.my.cnf

#### Setup wp-cli

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
rm -rf /var/www/wp-completion.bash
curl -o /var/www/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
source /var/www/wp-completion.bash
echo "Done"

### Setting up cron file

echo "Setting up wp-cron..."
touch /etc/cron.d/dockerpress
echo "SHELL=/bin/bash" >/etc/cron.d/dockerpress
echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >>/etc/cron.d/dockerpress
echo "" >>/etc/cron.d/dockerpress

#### Setting up Mysql Optimize

echo "Setting up MySL Optimize..."
sed -i -e "s/WORDPRESS_DB_HOST/$WORDPRESS_DB_HOST/g" /usr/local/bin/mysql-optimize
sed -i -e "s/WORDPRESS_DB_USER/$WORDPRESS_DB_USER/g" /usr/local/bin/mysql-optimize
sed -i -e "s/WORDPRESS_DB_PASSWORD/$WORDPRESS_DB_PASSWORD/g" /usr/local/bin/mysql-optimize
sed -i -e "s/WORDPRESS_DB_NAME/$WORDPRESS_DB_NAME/g" /usr/local/bin/mysql-optimize
sed -i -e "s/WORDPRESS_DB_PORT/$WORDPRESS_DB_PORT/g" /usr/local/bin/mysql-optimize

#### Creating Wordpress Database using root or another user / password

if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
  echo "Try create Database if not exists using root ..."
  mysql --no-defaults -h $WORDPRESS_DB_HOST --port $WORDPRESS_DB_PORT -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;"
else
  echo "Try create Database if not exists using $WORDPRESS_DB_USER user ..."
  mysql --no-defaults -h $WORDPRESS_DB_HOST --port $WORDPRESS_DB_PORT -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;"
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
  wp config set WP_SITEURL "https://$VIRTUAL_HOST" --add --type=constant
  wp config set WP_HOME "https://$VIRTUAL_HOST" --add --type=constant
  wp config set DB_NAME $WORDPRESS_DB_NAME --add --type=constant
  wp config set DB_USER $WORDPRESS_DB_USER --add --type=constant
  wp config set DB_PASSWORD $WORDPRESS_DB_PASSWORD --add --type=constant
  wp config set DB_HOST "$WORDPRESS_DB_HOST:$WORDPRESS_DB_PORT" --add --type=constant
  wp config set DB_PORT $WORDPRESS_DB_PORT --raw --add --type=constant
  wp config set WP_DEBUG $WP_DEBUG --raw --add --type=constant

  # if Wordpress is installed
  if ! $(wp core is-installed); then
    echo "Installing Wordpress for $VIRTUAL_HOST ..."
    wp core install --url=$VIRTUAL_HOST \
      --title=Wordpress \
      --admin_user=dockerpress \
      --admin_password=dockerpress \
      --admin_email=$ADMIN_EMAIL \
      --skip-email \
      --path=/var/www/html
    echo "Done Installing."
  else
    echo 'Wordpress is already installed.'
  fi

  wp rewrite structure '/%postname%/'

  # Updating Plugins ...
  echo "Updating plugins ..."
  wp plugin update --all

  # Remove unused Dolly
  echo "Remove Dolly..."
  wp plugin delete hello

  # Updating Themes ...
  echo "Updating themes ..."
  wp theme update --all

else

  echo 'wp-config.php file already exists.'

fi

echo "Updating wp-config.php ..."
wp config set WP_SITEURL "https://$VIRTUAL_HOST" --add --type=constant
wp config set WP_HOME "https://$VIRTUAL_HOST" --add --type=constant
wp config set DB_NAME $WORDPRESS_DB_NAME --add --type=constant
wp config set DB_USER $WORDPRESS_DB_USER --add --type=constant
wp config set DB_PASSWORD $WORDPRESS_DB_PASSWORD --add --type=constant
wp config set DB_HOST "$WORDPRESS_DB_HOST:$WORDPRESS_DB_PORT" --add --type=constant
wp config set DB_PORT $WORDPRESS_DB_PORT --raw --add --type=constant
wp config set WP_DEBUG $WP_DEBUG --raw --add --type=constant

# Redis Cache
if [ -n "$WP_REDIS_HOST" ]; then
  wp config set WP_CACHE true --raw --add --type=constant
  wp config set WP_REDIS_HOST $WP_REDIS_HOST --add --type=constant
  wp config set WP_REDIS_DATABASE $WP_REDIS_DATABASE --raw --add --type=constant
  wp config set WP_CACHE_KEY_SALT $VIRTUAL_HOST --add --type=constant

  if [ -n "$WP_REDIS_PORT" ]; then
    echo "Setting up redis port..."
    wp config set WP_REDIS_PORT $WP_REDIS_PORT --raw --add --type=constant
  fi

  if [ -n "$WP_REDIS_PASSWORD" ]; then
    echo "Setting up redis password..."
    wp config set WP_REDIS_PASSWORD $WP_REDIS_PASSWORD --add --type=constant
  else
    echo "Redis password not set. Try to create a more secure redis setup."
  fi
fi

echo "wp-config.php updated."

echo "Installing action-scheduler ..."
wp plugin install action-scheduler --force --activate

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
  wp redis update-dropin
  wp redis enable
  chmod +777 /var/www/html/wp-content/object-cache.php
fi

service apache2 reload

service cron reload

chown -R www-data:www-data /var/www/html/

wp core verify-checksums

sysvbanner dockerpress

exec "$@"
