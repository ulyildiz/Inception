#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

if [ -f /run/secrets/mariadb ]; then
	. /run/secrets/mariadb
else
	echo -e "${RED}MariaDB secret file not found! Exiting...${RESET}"
	exit 1
fi

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

#configure mariadb users privilages

if [ -f /run/secrets/db_password ]; then
  echo -e "${YELLOW}Using db_password from Docker secrets...${RESET}"
  . /run/secrets/db_password
else
	echo -e "${RED}Error: db_password secret not found!${RESET}"
	exit 1
fi

if [ -f /run/secrets/db_root_password ]; then
  echo -e "${YELLOW}Using db_root_password from Docker secrets...${RESET}"
  . /run/secrets/db_root_password
else
	echo -e "${RED}Error: db_root_password secret not found!${RESET}"
	exit 1
fi

echo -e "${YELLOW}Configuring MariaDB users and privileges...${RESET}"

# Start MariaDB temporarily for configuration
mariadbd-safe & 
sleep 10

# Wait for MariaDB to be ready
until mariadb -u root -e "SELECT 1;" 2>/dev/null; do
    echo -e "${YELLOW}Waiting for MariaDB to start...${RESET}"
    sleep 2
done

# Only configure users and database on first run
if [ -d "/var/lib/mysql/mysql" ]; then
    echo -e "${YELLOW}First run detected, configuring users and database...${RESET}"
    
    echo -e "${YELLOW}Altering root user's password...${RESET}"
    mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';"
    
    echo -e "${YELLOW}Creating user ${MARIADB_USER} if not exists...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}';"
    
    echo -e "${YELLOW}Creating ${MARIADB_DATABASE}...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;"
    
    echo -e "${YELLOW}Granting privileges to ${MARIADB_USER} user on ${MARIADB_DATABASE}...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';"
    
    echo -e "${YELLOW}Apply privileges...${RESET}"
    mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
    
    echo -e "${GREEN}MariaDB users and privileges configured successfully.${RESET}"
else
    echo -e "${YELLOW}MariaDB already configured, skipping user setup...${RESET}"
fi

# Stop temporary MariaDB
mariadb-admin -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown

exec mariadbd
