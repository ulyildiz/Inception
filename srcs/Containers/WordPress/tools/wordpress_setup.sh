#!/bin/bash
RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

if [ -f /run/secrets/mariadb ] && [ -f /run/secrets/wordpress ]; then
	. /run/secrets/mariadb
	. /run/secrets/wordpress
else
	echo -e "${RED}Required secrets missing (mariadb, wordpress). Exiting...${RESET}"
	exit 1
fi

DB_HOST=mariadb

db_ready=0
for i in $(seq 1 100); do
	if mariadb -h"${DB_HOST}" -u"${MARIADB_USER}" -p"${MARIADB_USER_PASSWORD}" "${MARIADB_DATABASE}" -e "SELECT 1" >/dev/null 2>&1; then
		echo "[WP config] MariaDB accessible."
		db_ready=1
		break
	fi
	echo -e "${YELLOW}Waiting for MariaDB to be available...${RESET}"
	sleep 3
done
if [ "$db_ready" -eq 0 ]; then
	echo -e "${RED}MariaDB not reachable after timeout. Exiting...${RESET}"
	exit 1
fi

WP_PATH="/var/www/html"

if [ ! -f "${WP_PATH}/wp-includes/version.php" ]; then
	echo -e "${YELLOW}Downloading WordPress...${RESET}"
	if wp-cli.phar core download --path="${WP_PATH}" --allow-root; then
		echo -e "${GREEN}WordPress downloaded successfully!${RESET}"
	else
		echo -e "${RED}Failed to download WordPress.${RESET}"
		exit 1
	fi
fi

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
	echo -e "${YELLOW}Creating wp-config.php...${RESET}"
	if ! wp-cli.phar config create --dbname=${MARIADB_DATABASE} \
		--dbuser=${MARIADB_USER} \
		--dbpass=${MARIADB_USER_PASSWORD} \
		--dbhost=${DB_HOST} \
		--path="${WP_PATH}" \
		--allow-root; then
		echo -e "${RED}Failed to create wp-config.php. Exiting...${RESET}"
		exit 1
	fi
fi

if [ ! wp-cli.phar core is-installed --path="${WP_PATH}" --allow-root ]; then
	echo -e "${YELLOW}Installing WordPress...${RESET}"
	if ! wp-cli.phar core install --url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--path="${WP_PATH}" \
		--allow-root; then
		echo -e "${RED}Failed to install WordPress. Exiting...${RESET}"
		exit 1
	fi
fi

echo -e "${YELLOW}Creating User...${RESET}"
if ! wp-cli.phar user create ${WP_USER} ${WP_USER_EMAIL} \
	--user_pass=${WP_USER_PASSWORD} \
	--role=subscriber \
	--path="${WP_PATH}" \
	--allow-root; then
	echo -e "${RED}Failed to create WordPress user. Continuing...${RESET}"
	exit 1
fi

chown -R www:www "${WP_PATH}"
chmod -R 755 "${WP_PATH}"

# Ensure index.php exists and is readable
if [ -f "${WP_PATH}/index.php" ]; then
	chmod 644 "${WP_PATH}/index.php"
	echo -e "${GREEN}WordPress index.php is ready${RESET}"
else
	echo -e "${RED}Warning: WordPress index.php not found!${RESET}"
fi

echo -e "${GREEN}WordPress setup completed!${RESET}"
echo -e "${YELLOW}Starting${RESET}"

exec /usr/sbin/php-fpm82 -F -R