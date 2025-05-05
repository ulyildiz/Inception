#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'


echo "${BLUE}1[MariaDB setup]${RESET}"

# write down to terminal maridb config file
echo "$(ls -la /etc/mysql/)"
echo "$(cat /etc/mysql/conf.d)"
echo "$(ls -la /etc/mysql/mariadb.conf.d/)"
echo "$(cat /etc/mysql/mariadb.conf.d/50-server.cnf)"
