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

#configure mariadb users privilages

if [ -f /run/secrets/db_password ]; then
  echo -e "${YELLOW}Using db_password from Docker secrets...${RESET}"
  MARIADB_USER_PASSWORD=$(cat /run/secrets/db_password)
else
	echo -e "${RED}Error: db_password secret not found!${RESET}"
	exit 1
fi

if [ -f /run/secrets/db_root_password ]; then
  echo -e "${YELLOW}Using db_root_password from Docker secrets...${RESET}"
  MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
else
	echo -e "${RED}Error: db_root_password secret not found!${RESET}"
	exit 1
fi

echo -e "${YELLOW}Configuring MariaDB users and privileges...${RESET}"

mariadbd-safe --skip-networking & sleep 5

echo -e "${YELLOW} ${MARIADB_DATABASE} ${RESET}"

echo -e "${YELLOW}Altering root user's password...${RESET}"
mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';"

echo -e "${YELLOW}Creating user ${MARIADB_USER} if not exists...${RESET}"
mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}';"

echo -e "${YELLOW}Removing all privileges to ${MARIADB_USER} user...${RESET}"
mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '${MARIADB_USER}'@'%';"

echo -e "${YELLOW}Creating ${MARIADB_DATABASE}...${RESET}"
mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;"

echo -e "${YELLOW}Granting privileges to ${MARIADB_USER} user on ${MARIADB_DATABASE}...${RESET}"
mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';"

echo -e "${YELLOW} Apply privileges...${RESET}"
mariadb -u root -p"${MARIADB_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

echo -e "${GREEN}MariaDB users and privileges configured successfully.${RESET}"

# Stop temporary MariaDB
mariadb-admin -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown

exec mariadbd
