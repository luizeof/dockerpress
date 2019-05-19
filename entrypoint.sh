#!/bin/bash

service cron start 
service cron reload

exec /usr/local/bin/docker-entrypoint.sh "$@"
