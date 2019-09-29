FROM php:7.3-apache

# Install System Libraries
RUN apt-get update \
    ; \
    apt-get install -y sudo \
    software-properties-common \
    build-essential \
    apache2 \
    libapache2-mod-security2 \
    modsecurity-crs \
    curl \
    tcl \
    cron \
    bzip2 \
    tidy \
    sysvbanner \
    wget \
    nano \
    htop \
    zip \
    git \
    csstidy \
    unzip \
    g++ \
    zlib1g-dev \
    libjpeg-dev \
		libmagickwand-dev \
		libpng-dev \
    libz-dev \
    libpq-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libaprutil1-dev \
    libssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libldap2-dev \
    libmemcached-dev \
    libxml2-dev \
    libz-dev \
		libzip-dev \
    mariadb-client \
    libmagickwand-dev \
    imagemagick \
    ghostscript

# Configure PHP and System Libraries
RUN	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    ; \
	  docker-php-ext-install -j "$(nproc)" \
		  bcmath \
		  exif \
		  gd \
      pdo \
      intl \
      xml \
      pdo_mysql \
      soap \
      opcache \
      mysqli \
      opcache \
      zip \
	 ; \
   printf "\n" | printf "\n" | pecl install redis \
   ; \
   pecl install imagick-3.4.4 \
      apcu-5.1.11 \
      memcached \
   ; \
	 docker-php-ext-enable imagick \
      bcmath \
      redis \
      opcache \
      apcu \
      memcached \
	 ; \
	 apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
   ; \
	 rm -rf /var/lib/apt/lists/*

# set recommended opcache settings
RUN { \
		echo 'opcache.memory_consumption=256'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=9999'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set recommended PHP.ini settings
RUN { \
  	echo 'file_uploads = On'; \
  	echo 'upload_max_filesize = 256M'; \
  	echo 'post_max_size = 256M'; \
  	echo 'max_execution_time = 999'; \
  	echo 'memory_limit = 512M'; \
  } > /usr/local/etc/php/conf.d/php73-recommended.ini

# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

# Enable apache modules
RUN a2enmod setenvif \
      headers \
      security2 \
      deflate \
      filter \
      expires \
      rewrite \
      include \
      ext_filter

# Default Volume for Apache
VOLUME /var/www/html

# Enable Apache Configs
COPY dockerpress.conf /etc/apache2/conf-available/dockerpress.conf
RUN a2enconf dockerpress

# Installing Apache mod-pagespeed
RUN curl -o /home/mod-pagespeed-beta_current_amd64.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb
RUN dpkg -i /home/mod-pagespeed-*.deb
RUN apt-get -f install

LABEL name="DockerPress"
LABEL version="1.1.0"
LABEL release="2019-08-19"

# Redis Defaults
ENV WP_CLI_CACHE_DIR "/var/www/.wp-cli/cache/"
ENV WP_CLI_PACKAGES_DIR "/var/www/.wp-cli/packages/"
ENV ADMIN_EMAIL "webmaster@localhost"
ENV WP_POST_REVISIONS true
ENV WP_LOCALE "pt_BR"
ENV CRON_ACTIONSCHEDULER 1
ENV CRON_MEDIA_REGENERATE 1
ENV CRON_CLEAR_TRANSIENT 1
ENV WP_DEBUG false
ENV WORDPRESS_DB_PORT 3306

COPY .htaccess /var/www/.htaccess-template
COPY wp-config-sample.php /var/www/wp-config-sample.php

# Copy commands
COPY bin/* /usr/local/bin/
RUN chmod -R +777 /usr/local/bin/

COPY dockerpress.ini.sample /usr/local/etc/php/conf.d/dockerpress.ini
RUN chmod +x /usr/local/etc/php/conf.d/dockerpress.ini

COPY my.cnf /root/.my.cnf.sample

# Running container startup scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default Port for Apache
EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
