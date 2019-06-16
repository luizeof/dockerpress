#!/bin/sh

 if [ "$#" -eq  "0" ]
   then
     sudo -E -u www-data /usr/local/bin/wp-cli.phar
 else
     sudo -E -u www-data /usr/local/bin/wp-cli.phar "$@"
 fi
