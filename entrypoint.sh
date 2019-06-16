#!/bin/bash

curl -o /var/www/wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/v1.5.1/utils/wp-completion.bash
echo 'source /var/www/wp-completion.bash' >> ~/.bash_profile
source ~/.bash_profile

service cron start 
service cron reload

exec /usr/local/bin/docker-entrypoint.sh "$@"
