#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

echo "${BLUE}1[MariaDB setup]${RESET}"

# initialize log directory
if [ ! -d "/var/log/mysql" ]; then
  echo "${YELLOW}Creating log directory...${RESET}"
  mkdir -p /var/log/mysql
fi
chown -R mysql:mysql /var/log/mysql

# initialize for socket
if [ ! -d "/run/mysqld" ]; then
  echo "${YELLOW}Creating mysqld run directory...${RESET}"
  mkdir -p /run/mysqld
fi
chown -R mysql:mysql /run/mysqld

# Initialize the database only if not already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "${YELLOW}Initializing MariaDB data directory...${RESET}"
  mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi
chown -R mysql:mysql /var/lib/mysql

exec mariadbd