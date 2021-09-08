#!/bin/bash

# cronjob:
# @reboot /home/user/scripts/on_reboot.sh

cd /home/user/proxy
docker-compose up -d
cd /home/user/stack/www/socket
docker-compose up -d
cd /home/user/stack/www/webcam
docker-compose up -d
