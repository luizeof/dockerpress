FROM wordpress:php7.2-apache

ENV WP_REDIS_DATABASE 1

ENV WP_REDIS_PORT 6379

ENV WP_REDIS_HOST=localhost

ENV PHP_MAX_MEMORY=300

RUN apt-get update

RUN apt-get install software-properties-common -y

RUN apt-get install sudo build-essential tcl8.5 zlib1g-dev libicu-dev g++ -y

RUN apt-get install -y \
      curl \
      libmemcached-dev \
      libz-dev \
      libpq-dev \
      libjpeg-dev \
      libpng-dev \
      libfreetype6-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      bzip2 \
      csstidy \
      libfreetype6-dev \
  		libicu-dev \
  		libldap2-dev \
  		libmemcached-dev \
  		libxml2-dev \
  		libz-dev \
      tidy \
      libapache2-modsecurity \
      wget \
      nano \
      htop \
      zip \
      unzip \
      libmagickwand-dev \
      imagemagick

RUN docker-php-ext-install pdo intl xml zip mysqli pdo_mysql soap

# Install the PHP gd library
RUN docker-php-ext-configure gd \
      --enable-gd-native-ttf \
      --with-jpeg-dir=/usr/lib \
      --with-freetype-dir=/usr/include/freetype2 && \
    docker-php-ext-install gd

# Install Extra modules
RUN pecl install \
		apcu-5.1.11 \
		memcached-3.0.4

# Enable Extra modules
RUN docker-php-ext-enable \
		apcu \
		memcached

RUN printf "\n" | printf "\n" | pecl install redis

RUN docker-php-ext-enable redis

RUN pecl install imagick -y

RUN docker-php-ext-enable imagick

RUN docker-php-ext-install exif

RUN a2enmod setenvif headers deflate filter expires rewrite include ext_filter

COPY luizeof.ini /usr/local/etc/php/conf.d/luizeof.ini

COPY luizeof.conf /etc/apache2/conf-available/luizeof.conf

COPY wordpress.cron /etc/cron.d/wordpress

RUN chmod +777 /etc/cron.d/wordpress

RUN curl -o /home/mod-pagespeed-beta_current_amd64.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb

RUN dpkg -i /home/mod-pagespeed-*.deb

RUN apt-get -f install

RUN curl -o /var/www/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

RUN mkdir -p /var/www/.wp-cli/cache/

RUN chown -R www-data:www-data /var/www/.wp-cli/cache/

RUN chmod -R +777 /var/www/.wp-cli/cache

RUN mv /var/www/wp-cli.phar /usr/local/bin/wp

RUN chmod +x /usr/local/bin/wp

RUN a2enconf luizeof

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

CMD ["apache2-foreground"]
