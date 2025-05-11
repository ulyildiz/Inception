#!/bin/bash
RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

# wait mariadb
while ! mariadb -h"${DB_HOST}" -u"${MARIADB_USER}" -p"$(cat /run/secrets/db_password)" ${MARIADB_DATABASE} &> /dev/null; do
  echo -e "${YELLOW}Waiting 2 for MariaDB to be ready...${RESET}"
  sleep 1
done
echo -e "${GREEN}MariaDB is ready!${RESET}"



exec /usr/sbin/php-fpm82 -F -R