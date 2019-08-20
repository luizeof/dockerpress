FROM luizeof/php7.3-build:latest

LABEL name="DockerPress"
LABEL version="1.1.0"
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
ENV CRON_ACTIONSCHEDULER 1
ENV CRON_MEDIA_REGENERATE 1
ENV CRON_CLEAR_TRANSIENT 1
ENV WP_DEBUG false

COPY .htaccess /var/www/.htaccess-template
COPY wp-config-sample.php /var/www/wp-config-sample.php

# Setting up crontab
COPY dockerpress.cron /etc/cron.d/dockerpress
RUN chmod +x /etc/cron.d/dockerpress

# Copy commands
COPY bin/* /usr/local/bin/
RUN chmod -R +777 /usr/local/bin/

COPY my.cnf /root/.my.cnf

# Running container startup scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
