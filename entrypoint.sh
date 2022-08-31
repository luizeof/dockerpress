#!/bin/bash

# start memcache service
service memcached start

# remove default index.html if exists
rm -f /var/www/html/index.html

function finish() {
  /usr/local/lsws/bin/lswsctrl "stop"
  pkill "tail"
}

function update_wp_config() {
  echo "Updating wp-config.php ..."
  wp config set WP_SITEURL "https://$VIRTUAL_HOST" --add --type=constant
  wp config set WP_HOME "https://$VIRTUAL_HOST" --add --type=constant
  wp config set DB_NAME $WORDPRESS_DB_NAME --add --type=constant
  wp config set DB_USER $WORDPRESS_DB_USER --add --type=constant
  wp config set DB_PASSWORD $WORDPRESS_DB_PASSWORD --add --type=constant
  wp config set DB_HOST "$WORDPRESS_DB_HOST:$WORDPRESS_DB_PORT" --add --type=constant
  wp config set DB_PREFIX $WORDPRESS_DB_PREFIX --add --type=constant
  wp config set DB_PORT $WORDPRESS_DB_PORT --raw --add --type=constant
  wp config set WP_DEBUG $WP_DEBUG --raw --add --type=constant
  wp config set WP_MEMORY_LIMIT 512M --add --type=constant
  wp config set WP_MAX_MEMORY_LIMIT 512M --add --type=constant
  wp config set DISABLE_WP_CRON $DISABLE_WP_CRON --raw --add --type=constant
}

function generate_litespeed_password() {
  if [ -n "${ADMIN_PASSWORD}" ]; then
    ENCRYPT_PASSWORD="$(/usr/local/lsws/admin/fcgi-bin/admin_php -q '/usr/local/lsws/admin/misc/htpasswd.php' "${ADMIN_PASSWORD}")"
    echo "admin:${ENCRYPT_PASSWORD}" >'/usr/local/lsws/admin/conf/htpasswd'
    echo "WebAdmin user/password is admin/${ADMIN_PASSWORD}" >'/usr/local/lsws/adminpasswd'
  fi
}

function setup_mysql_client() {
  echo "Updating my.cnf ..."
  mv /root/.my.cnf.sample /root/.my.cnf
  sed -i -e "s/MYUSER/$WORDPRESS_DB_USER/g" /root/.my.cnf
  sed -i -e "s/MYPASSWORD/$WORDPRESS_DB_PASSWORD/g" /root/.my.cnf
  sed -i -e "s/MYHOST/$WORDPRESS_DB_HOST/g" /root/.my.cnf
  sed -i -e "s/MYDATABASE/$WORDPRESS_DB_NAME/g" /root/.my.cnf
  sed -i -e "s/MYPORT/$WORDPRESS_DB_PORT/g" /root/.my.cnf
}

function install_wp_cli() {
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
}

function setup_mysql_optimize() {
  echo "Setting up MySL Optimize..."
  sed -i -e "s/WORDPRESS_DB_HOST/$WORDPRESS_DB_HOST/g" /usr/local/bin/mysql-optimize
  sed -i -e "s/WORDPRESS_DB_USER/$WORDPRESS_DB_USER/g" /usr/local/bin/mysql-optimize
  sed -i -e "s/WORDPRESS_DB_PASSWORD/$WORDPRESS_DB_PASSWORD/g" /usr/local/bin/mysql-optimize
  sed -i -e "s/WORDPRESS_DB_NAME/$WORDPRESS_DB_NAME/g" /usr/local/bin/mysql-optimize
  sed -i -e "s/WORDPRESS_DB_PORT/$WORDPRESS_DB_PORT/g" /usr/local/bin/mysql-optimize
}

function create_wordpress_database() {
  if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
    echo "Try create Database if not exists using root ..."
    mysql --no-defaults -h $WORDPRESS_DB_HOST --port $WORDPRESS_DB_PORT -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;"
  else
    echo "Try create Database if not exists using $WORDPRESS_DB_USER user ..."
    mysql --no-defaults -h $WORDPRESS_DB_HOST --port $WORDPRESS_DB_PORT -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;"
  fi
}

function install_wordpress() {
  chown -R www-data:www-data /var/www/html

  if [ ! -e /var/www/html/wp-config.php ]; then

    echo "Wordpress not found, downloading latest version ..."
    wp core download --locale=$WP_LOCALE --path=/var/www/html

    echo "Creating wp-config.file ..."
    cp /var/www/wp-config-sample.php /var/www/html/wp-config.php
    chown www-data:www-data /var/www/html/wp-config.php
    update_wp_config

    echo "Shuffling wp-config.php salts ..."
    wp config shuffle-salts

    # if Wordpress is installed
    if ! $(wp core is-installed); then
      echo "Installing Wordpress for $VIRTUAL_HOST ..."
      wp core install --url=$VIRTUAL_HOST \
        --title=Wordpress \
        --admin_user=$ADMIN_USER \
        --admin_password=$ADMIN_PASS \
        --admin_email=$ADMIN_EMAIL \
        --skip-email \
        --path=/var/www/html

      # Updating Plugins ...
      echo "Updating plugins ..."
      wp plugin update --all --path=/var/www/html

      # Remove unused Dolly
      echo "Remove Dolly..."
      wp plugin delete hello --path=/var/www/html

      # Updating Themes ...
      echo "Updating themes ..."
      wp theme update --all --path=/var/www/html

      echo "Done Installing."

      cp /var/www/.htaccess /var/www/html
      chown -R www-data:www-data /var/www/html/.htaccess
      wp rewrite structure '/%postname%/'

    else
      echo 'Wordpress is already installed.'
    fi
  else
    echo 'wp-config.php file already exists.'
    update_wp_config
  fi
}

function install_dockerpress_plugins() {
  echo "Installing action-scheduler ..."
  wp plugin install action-scheduler --force --activate --path=/var/www/html

  echo "Installing litespeed-cache ..."
  wp plugin install litespeed-cache --force --activate --path=/var/www/html

  echo "Installing regenerate-thumbnails ..."
  wp plugin install regenerate-thumbnails --force --activate --path=/var/www/html
}

cd /var/www/html

# Generate litespeed Admin Password
generate_litespeed_password

trap cleanup SIGTERM

#### Setting Up MySQL Client Defaults
setup_mysql_client

#### Setup wp-cli
install_wp_cli

### setting up cron service
service cron reload
service cron start

#### Setting up Mysql Optimize
setup_mysql_optimize

#### Creating Wordpress Database
create_wordpress_database

# run wordpress installer
install_wordpress

# install and activate default plugins
install_dockerpress_plugins

# update file permissions
chown -R www-data:www-data /var/www/html

wp core verify-checksums

service memcached start

# Start the LiteSpeed
/usr/local/lsws/bin/litespeed

# welcome to dockerpress
sysvbanner dockerpress

# Read the credentials
cat '/usr/local/lsws/adminpasswd'

# Tail the logs to stdout
tail -f \
  '/var/log/litespeed/access.log'

exec "$@"
