#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

echo -e "${BLUE}[MariaDB setup]${RESET}"

# initialize log directory
if [ ! -d "/var/log/mysql" ]; then
  echo -e "${YELLOW}Creating log directory...${RESET}"
  mkdir -p /var/log/mysql
fi
chown -R mysql:mysql /var/log/mysql

# initialize for socket
if [ ! -d "/run/mysqld" ]; then
  echo -e "${YELLOW}Creating mysqld run directory...${RESET}"
  mkdir -p /run/mysqld
fi
chown -R mysql:mysql /run/mysqld

# Initialize the database only if not already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo -e "${YELLOW}Initializing MariaDB data directory...${RESET}"
  mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi
chown -R mysql:mysql /var/lib/mysql

if [ -f /run/secrets/db_root_password ]; then
  echo -e "${YELLOW}Setting up root password...${RESET}"
  MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
else 
  echo -e "${RED}No root password provided. Please set it up using a secret.${RESET}"
  exit 1
fi

if [ -f /run/secrets/db_password ]; then
  echo -e "${YELLOW}Setting up user password...${RESET}"
  MARIADB_USER_PASSWORD=$(cat /run/secrets/db_password)
else 
  echo -e "${RED}No user password provided. Please set it up using a secret.${RESET}"
  exit 1
fi

exec mariadbd
