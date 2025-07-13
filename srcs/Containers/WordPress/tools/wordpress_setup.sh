#!/bin/bash
RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

#chown -R www-data: /var/www/*

while ! mariadb -h${DB_HOST} -u${MARIADB_USER} -p$(cat /run/secrets/db_password) ${MARIADB_DATABASE} &> /dev/null; do
	echo -e "${YELLOW}Waiting for MariaDB to be ready...${RESET}"
	sleep 1
done
echo -e "${BLUE}MariaDB is ready!${RESET}"
# wait mariadb

WP_PATH="/var/www/html"

if [ -f "${WP_PATH}/wp-config.php" ]; then
	echo -e "${YELLOW}WordPress is already installed.${RESET}"
else
	echo -e "${YELLOW}Setup WordPress...${RESET}"
	wp-cli.phar cli update --yes --allow-root
	echo -e "${YELLOW}Downloading WordPress...${RESET}"
	mkdir -p "${WP_PATH}"
	php -d memory_limit=512M /usr/local/bin/wp-cli.phar core download --path="${WP_PATH}" --allow-root
	echo -e "${YELLOW}Creating wp-config.php...${RESET}"
	php -d memory_limit=512M /usr/local/bin/wp-cli.phar config create \
    --dbname="${MARIADB_DATABASE}" \
    --dbuser="${MARIADB_USER}" \
    --dbpass=$(cat /run/secrets/db_password) \
    --dbhost="${DB_HOST}" \
    --path="${WP_PATH}" \
    --allow-root
    
    # Set proper permissions
    chown -R www:www "${WP_PATH}"
    chmod -R 755 "${WP_PATH}"
    
    echo -e "${GREEN}WordPress setup completed!${RESET}"
fi
echo -e "${YELLOW}Starting${RESET}"

exec /usr/sbin/php-fpm82 -F -R