FROM wordpress:php7.3-apache

LABEL name="DockerPress"
LABEL version="1.0.0"
LABEL release="2019-06-16"

# Redis Defaults
ENV WP_REDIS_DATABASE 2
ENV WP_REDIS_PORT 6379
ENV WP_REDIS_HOST localhost

# Update apt-cache and core libraries
RUN apt-get update && \
    apt-get install -y \
      sudo \
      software-properties-common \
      build-essential \
      curl \
      tcl8.5 \
      zlib1g-dev \
      cron \
      g++ \
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
      python \
      python-setuptools \
      python-pip \
  		libxml2-dev \
      libzip-dev \
  		libz-dev \
      tidy \
      libapache2-modsecurity \
      wget \
      nano \
      htop \
      zip \
      mysql-client \
      git \
      unzip \
      libmagickwand-dev \
      imagemagick \
      && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
      && rm -rf /var/lib/apt/lists/*

# Instll PHP modules
RUN docker-php-ext-install pdo intl xml zip mysqli pdo_mysql soap opcache bcmath


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
RUN a2enmod setenvif headers deflate filter expires rewrite include ext_filter

# Enable custom parameters
COPY luizeof.ini /usr/local/etc/php/conf.d/luizeof.ini

# Enable Apache Configs
COPY luizeof-cache.conf /etc/apache2/conf-available/luizeof-cache.conf
RUN a2enconf luizeof-cache

# Setting up crontab
COPY luizeof.cron /etc/cron.d/luizeof
RUN chmod +x /etc/cron.d/luizeof

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
