#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

if [ -f /run/secrets/mariadb ]; then
  . /run/secrets/mariadb
else
  echo -e "${RED}Required secrets missing (mariadb). Exiting...${RESET}"
  exit 1
fi

echo -e "${BLUE}[MariaDB setup]${RESET}"

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo -e "${YELLOW}Initializing MariaDB data directory...${RESET}"
  mariadb-install-db --basedir=/usr --datadir=/var/lib/mysql --skip-test-db --rpm
fi
chown -R mysql:mysql /var/lib/mysql

if [ ! -f "/var/lib/mysql/.srcs_mariadb" ]; then
  echo -e "${YELLOW}First run detected, configuring users and database...${RESET}"

  echo "USE mysql;" > /init.sql
  echo "FLUSH PRIVILEGES;" >> /init.sql
  echo "CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}';" >> /init.sql
  echo "CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;" >> /init.sql
  echo "GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';" >> /init.sql
  echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';" >> /init.sql
  echo "FLUSH PRIVILEGES;" >> /init.sql

  chown mysql:mysql /init.sql

  mariadbd --bootstrap < /init.sql
  touch /var/lib/mysql/.srcs_mariadb
  
  echo -e "${GREEN}MariaDB users and privileges configured successfully.${RESET}"
else
  echo -e "${YELLOW}MariaDB already configured, skipping user setup...${RESET}"
fi

exec "$@"
