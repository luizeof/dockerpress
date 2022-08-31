FROM bitnami/minideb:buster

LABEL name="DockerPress"
LABEL version="3.0.0"
LABEL release="2022-03-07"

WORKDIR /var/www/html

# ENV Defaults
ENV WP_CLI_CACHE_DIR "/var/www/.wp-cli/cache/"
ENV WP_CLI_PACKAGES_DIR "/var/www/.wp-cli/packages/"
ENV ADMIN_EMAIL "webmaster@host.com"
ENV ADMIN_PASS "dockerpress"
ENV ADMIN_USER "dockerpress"
ENV WP_LOCALE "en_US"
ENV WP_DEBUG false
ENV WORDPRESS_DB_PREFIX "wp_"
ENV WORDPRESS_DB_PORT 3306
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="1"
ENV DEBIAN_FRONTEND="noninteractive"
ENV DISABLE_WP_CRON=true

# HTTP port
EXPOSE "80/tcp"

# Webadmin port (HTTPS)
EXPOSE "7080/tcp"

# Install System Libraries
RUN apt-get update \
	&& \
	apt-get install -y --no-install-recommends \
	sudo \
	curl \
	cron \
	less \
	sysvbanner \
	wget \
	nano \
	htop \
	ghostscript \
	memcached \
  	libmemcached-dev \
  	libmemcached-tools \
	zip \
	unzip \
	git \
	webp \
	libwebp6 \
	memcached \
	libmemcached-tools \
	graphicsmagick \
	imagemagick \
	zlib1g \
	inetutils-ping \
	libxml2 \
	default-mysql-client\
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -rf /var/lib/apt/lists/* \
	&& sudo apt-get clean

# Make sure we have required tools
RUN install_packages \
	"curl" \
	"gnupg"

RUN wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debian_repo.sh | bash

# Install the Litespeed keys
RUN curl --silent --show-error \
	"http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg" |\
	apt-key add -

RUN curl --silent --show-error \
	"http://rpms.litespeedtech.com/debian/lst_repo.gpg" |\
	apt-key add -

# Install the Litespeed repository
RUN # echo "deb http://rpms.litespeedtech.com/debian/ buster main" > "/etc/apt/sources.list.d/openlitespeed.list"

RUN apt-get update

# Install the Litespeed
RUN install_packages \
	"openlitespeed" && \
	echo "cloud-docker" > "/usr/local/lsws/PLAT"

# Install PageSpeed module
RUN install_packages \
	"ols-pagespeed"

# Install the PHP
RUN install_packages \
	"lsphp80"

# Install PHP modules
RUN install_packages \
	"lsphp80-apcu" \
	"lsphp80-common" \
	"lsphp80-curl" \
	"lsphp80-igbinary" \
	"lsphp80-imagick" \
	"lsphp80-imap" \
	"lsphp80-intl" \
	"lsphp80-ldap" \
	"lsphp80-memcached" \
	"lsphp80-msgpack" \
	"lsphp80-mysql" \
	"lsphp80-opcache" \
	"lsphp80-pear" \
	"lsphp80-pgsql" \
	"lsphp80-pspell" \
	"lsphp80-redis" \
	"lsphp80-sqlite3" \
	"lsphp80-tidy"

# Set the default PHP CLI
RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp80/bin/lsphp" \
	"/usr/local/lsws/fcgi-bin/lsphp5"

RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp80/bin/php8.0" \
	"/usr/bin/php"

# Install the certificates
RUN install_packages \
	"ca-certificates"

# Install requirements
RUN install_packages \
	"procps" \
	"tzdata"

# PHP Settings
RUN  sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /usr/local/lsws/lsphp80/etc/php/8.0/litespeed/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 256M/g' /usr/local/lsws/lsphp80/etc/php/8.0/litespeed/php.ini
RUN sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/lsws/lsphp80/etc/php/8.0/litespeed/php.ini

COPY php-8.0/config/opcache.ini /usr/local/lsws/lsphp80/etc/php/8.0/mods-available/opcache.ini

RUN touch /var/www/.opcache

COPY php-8.0/memcached.conf /etc/memcached.conf

# Create the directories
RUN mkdir --parents \
	"/tmp/lshttpd/gzcache" \
	"/tmp/lshttpd/pagespeed" \
	"/tmp/lshttpd/stats" \
	"/tmp/lshttpd/swap" \
	"/tmp/lshttpd/upload" \
	"/var/log/litespeed"

# Make sure logfiles exist
RUN touch \
	"/var/log/litespeed/server.log" \
	"/var/log/litespeed/access.log"

# Make sure we have access to files
RUN chown --recursive "lsadm:lsadm" \
	"/tmp/lshttpd" \
	"/var/log/litespeed"

# Configure the admin interface
COPY --chown="lsadm:lsadm" \
	"php-8.0/litespeed/admin_config.conf" \
	"/usr/local/lsws/admin/conf/admin_config.conf"

# Configure the server
COPY --chown="lsadm:lsadm" \
	"php-8.0/litespeed/httpd_config.conf" \
	"/usr/local/lsws/conf/httpd_config.conf"

# Create the virtual host folders
RUN mkdir --parents \
	"/usr/local/lsws/conf/vhosts/wordpress" \
	"/var/www" \
	"/var/www/html" \
	"/var/www/tmp"

# Configure the virtual host
COPY --chown="lsadm:lsadm" \
	"php-8.0/litespeed/vhconf.conf" \
	"/usr/local/lsws/conf/vhosts/wordpress/vhconf.conf"

# Set up the virtual host configuration permissions
RUN chown --recursive "lsadm:lsadm" \
	"/usr/local/lsws/conf/vhosts/wordpress"

# Set up the virtual host document root permissions
RUN chown --recursive "www-data:www-data" \
	"/var/www/html"

RUN chown "www-data:www-data" \
	"/var/www"

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	; \
	rm -rf /var/lib/apt/lists/*

# Default Volume for Web
VOLUME /var/www/html

COPY wordpress/.htaccess /var/www

COPY wordpress/wp-config-sample.php /var/www/wp-config-sample.php

# Copy commands
COPY bin/* /usr/local/bin/

# Add Permissions
RUN chmod +x /usr/local/bin/wp
RUN chmod +x /usr/local/bin/mysql-optimize
RUN chmod +x /usr/local/bin/wpcli-run-clear-scheduler-log
RUN chmod +x /usr/local/bin/wpcli-run-clear-spams
RUN chmod +x /usr/local/bin/wpcli-run-delete-transient
RUN chmod +x /usr/local/bin/wpcli-run-media-regenerate
RUN chmod +x /usr/local/bin/wpcli-run-schedule

# Copy Crontab
COPY cron.d/dockerpress.crontab /etc/cron.d/dockerpress
RUN chmod 644 /etc/cron.d/dockerpress

RUN { \
	echo '[client]'; \
	echo 'user=MYUSER'; \
	echo "password='MYPASSWORD'"; \
	echo 'host=MYHOST'; \
	echo 'port=MYPORT'; \
	echo ''; \
	echo '[mysql]'; \
	echo 'database=MYDATABASE'; \
	echo ''; \
	} > /root/.my.cnf.sample

# Running wordpress startup scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default Port for Apache
EXPOSE 80

# Set the workdir and command
ENV PATH="/usr/local/lsws/bin:${PATH}"

ENTRYPOINT ["entrypoint.sh"]
