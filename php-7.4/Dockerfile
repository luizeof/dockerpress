FROM bitnami/minideb:buster

LABEL name="DockerPress"
LABEL version="3.0.0"
LABEL release="2022-03-07"

WORKDIR /var/www/html

# ENV Defaults
ENV WP_CLI_CACHE_DIR "/var/www/.wp-cli/cache/"
ENV WP_CLI_PACKAGES_DIR "/var/www/.wp-cli/packages/"
ENV ADMIN_EMAIL "webmaster@host.com"
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

# Install the Litespeed
RUN install_packages \
	"openlitespeed" && \
	echo "cloud-docker" > "/usr/local/lsws/PLAT"

# Install PageSpeed module
RUN install_packages \
	"ols-pagespeed"

# Install the PHP
RUN install_packages \
	"lsphp74"

# Install PHP modules
RUN install_packages \
	"lsphp74-dev" \
	"lsphp74-apcu" \
	"lsphp74-common" \
	"lsphp74-curl" \
	"lsphp74-igbinary" \
	"lsphp74-imagick" \
	"lsphp74-imap" \
	"lsphp74-intl" \
	"lsphp74-ldap" \
	"lsphp74-memcached" \
	"lsphp74-msgpack" \
	"lsphp74-mysql" \
	"lsphp74-opcache" \
	"lsphp74-pear" \
	"lsphp74-pgsql" \
	"lsphp74-pspell" \
	"lsphp74-redis" \
	"lsphp74-sqlite3" \
	"lsphp74-json" \
	"lsphp74-tidy" \
	"lsphp74-*"

# Set the default PHP CLI
RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp74/bin/lsphp" \
	"/usr/local/lsws/fcgi-bin/lsphp5"

RUN ln --symbolic --force \
	"/usr/local/lsws/lsphp74/bin/php7.4" \
	"/usr/bin/php"

# Install the certificates
RUN install_packages \
	"ca-certificates"

# Install requirements
RUN install_packages \
	"procps" \
	"tzdata"

# PHP Settings
RUN  sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 128M/g' /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini
RUN sed -i 's/post_max_size = 8M/post_max_size = 256M/g' /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini

COPY php-7.4/config/opcache.ini /usr/local/lsws/lsphp74/etc/php/7.4/mods-available/opcache.ini

RUN touch /var/www/.opcache

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
	"php-7.4/litespeed/admin_config.conf" \
	"/usr/local/lsws/admin/conf/admin_config.conf"

# Configure the server
COPY --chown="lsadm:lsadm" \
	"php-7.4/litespeed/httpd_config.conf" \
	"/usr/local/lsws/conf/httpd_config.conf"

# Create the virtual host folders
RUN mkdir --parents \
	"/usr/local/lsws/conf/vhosts/wordpress" \
	"/var/www" \
	"/var/www/html" \
	"/var/www/tmp"

# Configure the virtual host
COPY --chown="lsadm:lsadm" \
	"php-7.4/litespeed/vhconf.conf" \
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
RUN chmod +x /usr/local/bin/wpcli-run-actionscheduler
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
