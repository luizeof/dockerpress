FROM php:7.4-apache

LABEL name="DockerPress"
LABEL version="2.1.0"
LABEL release="2021-04-01"

# ENV Defaults
ENV WP_CLI_CACHE_DIR "/var/www/.wp-cli/cache/"
ENV WP_CLI_PACKAGES_DIR "/var/www/.wp-cli/packages/"
ENV ADMIN_EMAIL "webmaster@host.com"
ENV WP_POST_REVISIONS true
ENV WP_LOCALE "pt_BR"
ENV CRON_ACTIONSCHEDULER 1
ENV CRON_MEDIA_REGENERATE 1
ENV CRON_CLEAR_TRANSIENT 1
ENV WP_DEBUG false
ENV WORDPRESS_DB_PORT 3306

# Install System Libraries
RUN apt-get update \
  && \
  apt-get install -y --no-install-recommends \
  sudo \
  software-properties-common \
  build-essential \
  apache2 \
  libapache2-mod-security2 \
  modsecurity-crs \
  curl \
  tcl \
  dos2unix \
  cron \
  bzip2 \
  tidy \
  sysvbanner \
  wget \
  less \
  nano \
  htop \
  zip \
  unzip \
  git \
  libwebp-dev \
  webp \
  libwebp6 \
  graphicsmagick \
  csstidy \
  g++ \
  zlib1g-dev \
  libjpeg-dev \
  libmagickwand-dev \
  libpng-dev \
  libgif-dev \
  libtiff-dev \
  libz-dev \
  inetutils-ping \
  libpq-dev \
  libcurl4-openssl-dev \
  libaprutil1-dev \
  libssl-dev \
  libicu-dev \
  libldap2-dev \
  libmemcached-dev \
  libxml2-dev \
  libzip-dev \
  mariadb-client \
  libwebp-dev \
  libjpeg62-turbo-dev \
  libxpm-dev \
  libfreetype6-dev \
  imagemagick \
  ghostscript \
  jpegoptim \
  optipng \
  pngquant \
  libc-client-dev \
  libjpeg-dev \
  gifsicle \
  groff \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/* \
  && sudo apt-get clean

# Configure PHP and System Libraries
RUN	docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install -j "$(nproc)" \
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
  zip

RUN printf "\n" | printf "\n" | pecl install redis \
  ; \
  pecl install imagick \
  apcu \
  memcached

RUN docker-php-ext-enable imagick \
  bcmath \
  redis \
  opcache \
  apcu \
  memcached

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  ; \
  rm -rf /var/lib/apt/lists/*

# set recommended opcache settings
RUN { \
  echo 'opcache.memory_consumption=768'; \
  echo 'opcache.interned_strings_buffer=16'; \
  echo 'opcache.max_accelerated_files=99999'; \
  echo 'opcache.revalidate_freq=2'; \
  echo 'opcache.fast_shutdown=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# set recommended PHP.ini settings
RUN { \
  echo 'file_uploads=On'; \
  echo 'upload_max_filesize=256M'; \
  echo 'post_max_size=256M'; \
  echo 'max_execution_time=300'; \
  echo 'memory_limit=512M'; \
  echo 'expose_php=Off'; \
  } > /usr/local/etc/php/conf.d/php73-recommended.ini

# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
  echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
  echo 'display_errors=Off'; \
  echo 'display_startup_errors=Off'; \
  echo 'log_errors=On'; \
  echo 'error_log=/dev/stderr'; \
  echo 'log_errors_max_len=1024'; \
  echo 'ignore_repeated_errors=On'; \
  echo 'ignore_repeated_source=Off'; \
  echo 'html_errors=Off'; \
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

# Copy Apache Configs
COPY apache/conf/dockerpress.conf /etc/apache2/conf-available/dockerpress.conf
COPY apache/conf/mozilla-observatory.conf /etc/apache2/conf-available/mozilla-observatory.conf

# Enable Apache Configs
RUN a2enconf dockerpress

# Installing Apache mod-pagespeed
RUN curl -o /home/mod-pagespeed-beta_current_amd64.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb
RUN dpkg -i /home/mod-pagespeed-*.deb
RUN apt-get -f install

COPY .htaccess /var/www/.htaccess-template
COPY wp-config-sample.php /var/www/wp-config-sample.php

# Copy commands
COPY bin/* /usr/local/bin/
# Fix Permissions
RUN chmod -R +777 /usr/local/bin/

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

# Running container startup scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default Port for Apache
EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]

CMD ["apache2-foreground"]
