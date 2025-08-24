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
  mariadb-install-db --basedir=/usr --datadir=/var/lib/mysql --skip-test-db 
fi
chown -R mysql:mysql /var/lib/mysql

#configure mariadb users privileges

echo -e "${YELLOW}Configuring MariaDB users and privileges...${RESET}"

# Start MariaDB temporarily for configuration
mariadbd --skip-networking &
sleep 10

# Only configure users and database on first run
if [ ! -f "/var/lib/mysql/.srcs_mariadb" ]; then
    echo -e "${YELLOW}First run detected, configuring users and database...${RESET}"
    
    echo -e "${YELLOW}Setting root user password...${RESET}"
    mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"

    echo -e "${YELLOW}Creating user ${MARIADB_USER} if not exists...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}'; FLUSH PRIVILEGES;"

    echo -e "${YELLOW}Creating ${MARIADB_DATABASE}...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`; FLUSH PRIVILEGES;"

    echo -e "${YELLOW}Granting privileges to ${MARIADB_USER} user on ${MARIADB_DATABASE}...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%'; FLUSH PRIVILEGES;"
  
    echo -e "${YELLOW}Apply privileges...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    
    # Create marker file to indicate initialization is complete
    touch /var/lib/mysql/.srcs_mariadb
    
    echo -e "${GREEN}MariaDB users and privileges configured successfully.${RESET}"
else
    echo -e "${YELLOW}MariaDB already configured, skipping user setup...${RESET}"
fi

# Stop temporary MariaDB
mariadb-admin -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown

exec /usr/bin/mariadbd-safe --datadir='/var/lib/mysql'
