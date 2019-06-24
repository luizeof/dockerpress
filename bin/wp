#!/bin/sh

if [ -z "$1" ];
then
  echo "usage: wp command --args"
else
  sudo -E -u www-data /var/www/wp-cli.phar "$@"
fi
