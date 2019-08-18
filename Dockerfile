FROM php:7.3-apache

LABEL name="DockerPress"
LABEL version="1.0.0"
LABEL release="2019-08-19"

# Redis Defaults
ENV WP_REDIS_DATABASE 2
ENV WP_REDIS_PORT 6379
ENV WP_REDIS_HOST localhost
ENV WP_CLI_CACHE_DIR "/var/www/.wp-cli/cache/"
ENV WP_CLI_PACKAGES_DIR "/var/www/.wp-cli/packages/"
ENV ADMIN_EMAIL "webmaster@localhost"
ENV WP_POST_REVISIONS true
ENV WP_LOCALE "pt_BR"

VOLUME /var/www/html

# Update apt-cache and core libraries
RUN apt-get update && \
    apt-get install -y \
      sudo \
      software-properties-common \
      build-essential \
      curl \
      tcl \
      zlib1g-dev \
      cron \
      g++ \
      libz-dev \
      libpq-dev \
      libjpeg-dev \
      libpng-dev \
      libfreetype6-dev \
      libcurl4-openssl-dev \
      libaprutil1-dev \
      libssl-dev \
      bzip2 \
      csstidy \
      libfreetype6-dev \
  		libicu-dev \
  		libldap2-dev \
  		libmemcached-dev \
      python \
      python-setuptools \
      python-pip \
  		libxml2-dev \
      libzip-dev \
  		libz-dev \
      tidy \
      libapache2-mod-security2 \
      modsecurity-crs \
      wget \
      nano \
      htop \
      zip \
      mariadb-client \
      git \
      unzip \
      libmagickwand-dev \
      imagemagick \
      ghostscript \
      && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
      && rm -rf /var/lib/apt/lists/*

# Instll PHP modules
RUN docker-php-ext-install pdo intl xml zip mysqli pdo_mysql soap opcache bcmath


# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini


# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
# https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
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


# Install the PHP gd library
RUN docker-php-ext-configure gd \
      --enable-gd-native-ttf \
      --with-jpeg-dir=/usr/lib \
      --with-freetype-dir=/usr/include/freetype2 && \
    docker-php-ext-install gd

# Install Extra modules
RUN pecl install \
		apcu-5.1.11 \
		memcached

RUN pecl install imagick-3.4.4


# Enable Extra modules
RUN docker-php-ext-enable \
    bcmath \
    opcache \
		apcu \
		memcached

# Install and enable redis
RUN printf "\n" | printf "\n" | pecl install redis
RUN docker-php-ext-enable redis

# Install and enable imagick
# RUN pecl install imagick
RUN docker-php-ext-enable imagick
RUN docker-php-ext-install exif

# Enable apache modules
RUN a2enmod setenvif headers security2 deflate filter expires rewrite include ext_filter

# Enable custom parameters
COPY dockerpress.ini /usr/local/etc/php/conf.d/dockerpress.ini

# Enable Apache Configs
COPY dockerpress.conf /etc/apache2/conf-available/dockerpress.conf
RUN a2enconf dockerpress

# Setting up crontab
COPY dockerpress.cron /etc/cron.d/dockerpress
RUN chmod +x /etc/cron.d/dockerpress

# Installing Apache mod-pagespeed
RUN curl -o /home/mod-pagespeed-beta_current_amd64.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb
RUN dpkg -i /home/mod-pagespeed-*.deb
RUN apt-get -f install

# Copy commands
COPY bin/* /usr/local/bin/
RUN chmod -R +777 /usr/local/bin/

EXPOSE 80

# Running container startup scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
