#!/bin/bash
RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

#chown -R www-data: /var/www/*

if [ -f /run/secrets/db_password ] || [ -f /run/secrets/mariadb ] || [ -f /run/secrets/wordpress ]; then
	. /run/secrets/db_password
	. /run/secrets/mariadb
	. /run/secrets/wordpress
else
	echo -e "${RED}Database password secret not found! Exiting...${RESET}"
	exit 1
fi

while ! mariadb -h${DB_HOST} -u${MARIADB_USER} -p${MARIADB_USER_PASSWORD} ${MARIADB_DATABASE};
do
	echo -e "${YELLOW}Waiting for MariaDB to be available...${RESET}"
    sleep 3
done
echo "[WP config] MariaDB accessible."

if [ -f "${WP_PATH}/wp-config.php" ]; then
	echo -e "${YELLOW}WordPress is already installed.${RESET}"
else
	echo -e "${YELLOW}Setup WordPress...${RESET}"
	
	# Set PHP memory limit for wp-cli
	export PHP_MEMORY_LIMIT=512M
	
	wp-cli.phar cli update --yes --allow-root
	
	echo -e "${YELLOW}Downloading WordPress...${RESET}"
	mkdir -p "${WP_PATH}"
	
	# Download WordPress with retry logic
	echo -e "${YELLOW}Download attempt $i/3...${RESET}"
	wp-cli.phar core download --path="${WP_PATH}" --allow-root;
	echo -e "${GREEN}WordPress downloaded successfully!${RESET}"
	
	# Verify WordPress was downloaded
	if [ ! -f "${WP_PATH}/wp-config-sample.php" ]; then
		echo -e "${RED}WordPress download verification failed. Exiting...${RESET}"
		exit 1
	fi
	
	echo -e "${YELLOW}Configuring WordPress...${RESET}"
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
	
	echo -e "${YELLOW}Installing WordPress...${RESET}"
	if ! wp-cli.phar core install --url=${WP_URL} \
		--title="${WP_TITLE}" \
		--admin_user=${WP_ADMIN} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--path="${WP_PATH}" \
		--allow-root; then
		echo -e "${RED}Failed to install WordPress. Exiting...${RESET}"
		exit 1
	fi
	
	echo -e "${YELLOW}Creating User...${RESET}"
	if ! wp-cli.phar user create ${WP_USER} ${WP_USER_EMAIL} \
		--user_pass=${WP_USER_PASSWORD} \
		--role=subscriber \
		--path="${WP_PATH}" \
		--allow-root; then
		echo -e "${RED}Failed to create WordPress user. Continuing...${RESET}"
	fi

    # Set proper permissions
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
fi
echo -e "${YELLOW}Starting${RESET}"

exec /usr/sbin/php-fpm82 -F -R