#!/bin/sh

 if [ -z "$1" ];
 then
     sudo -E -u www-data /usr/local/bin/wp-cli.phar --info
 else
     sudo -E -u www-data /usr/local/bin/wp-cli.phar "$@"
 fi
