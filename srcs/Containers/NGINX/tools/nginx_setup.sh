#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

echo -e "${BLUE}Starting NGINX setup...${RESET}"

# Read domain name from secret
if [ -f /run/secrets/nginx_domain ]; then
    . /run/secrets/nginx_domain
else
    echo -e "${YELLOW}Secret not found, using environment variable: ${RESET}"
fi

# Read SSL configuration from secret
if [ -f /run/secrets/ssl_config ]; then
    SSL_CONFIG=$(cat /run/secrets/ssl_config)
    SSL_COUNTRY=$(echo "$SSL_CONFIG" | sed -n '1p')
    SSL_STATE=$(echo "$SSL_CONFIG" | sed -n '2p')
    SSL_CITY=$(echo "$SSL_CONFIG" | sed -n '3p')
    SSL_ORG=$(echo "$SSL_CONFIG" | sed -n '4p')
    echo -e "${GREEN}SSL configuration loaded from secret${RESET}"
fi

# Set default values if not provided
WEB_ROOT=${WEB_ROOT:-/var/www/html}
SSL_PROTOCOLS=${SSL_PROTOCOLS:-"TLSv1.2 TLSv1.3"}
SSL_CIPHERS=${SSL_CIPHERS:-"HIGH:!aNULL:!MD5"}
HSTS_MAX_AGE=${HSTS_MAX_AGE:-31536000}

# Use environment variables for SSL paths
SSL_CERT_PATH=${SSL_CERT_PATH:-"/etc/nginx/ssl/${DOMAIN_NAME}.crt"}
SSL_KEY_PATH=${SSL_KEY_PATH:-"/etc/nginx/ssl/${DOMAIN_NAME}.key"}
SSL_CSR_PATH="/etc/nginx/ssl/${DOMAIN_NAME}.csr"

echo -e "${BLUE}SSL Configuration:${RESET}"
echo -e "${BLUE}  Certificate: ${SSL_CERT_PATH}${RESET}"
echo -e "${BLUE}  Key: ${SSL_KEY_PATH}${RESET}"
echo -e "${BLUE}  Domain: ${DOMAIN_NAME}${RESET}"

# Create SSL directory
mkdir -p /etc/nginx/ssl



# Create web root directory
mkdir -p ${WEB_ROOT:-/var/www/html}

# Set proper permissions
chown -R www:www ${WEB_ROOT:-/var/www/html}
chmod -R 755 ${WEB_ROOT:-/var/www/html}


# Generate SSL certificate if it doesn't exist
if [ ! -f "${SSL_CERT_PATH}" ]; then
    echo -e "${YELLOW}Generating SSL certificate for ${DOMAIN_NAME}...${RESET}"
    
    # Generate private key
    openssl genrsa -out "${SSL_KEY_PATH}" 2048
    
    # Generate certificate signing request
    openssl req -new -key "${SSL_KEY_PATH}" -out "${SSL_CSR_PATH}" -subj "/C=${SSL_COUNTRY}/ST=${SSL_STATE}/L=${SSL_CITY}/O=${SSL_ORG}/CN=${DOMAIN_NAME}"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in "${SSL_CSR_PATH}" -signkey "${SSL_KEY_PATH}" -out "${SSL_CERT_PATH}"
    
    # Set proper permissions for SSL files
    chmod 777 "${SSL_KEY_PATH}"
    chmod 777 "${SSL_CERT_PATH}"
    
    # Clean up CSR file
    rm -f "${SSL_CSR_PATH}"
    
    echo -e "${GREEN}SSL certificate generated successfully!${RESET}"
else
    echo -e "${GREEN}SSL certificate already exists.${RESET}"
fi


# Substitute environment variables in nginx configuration
echo -e "${BLUE}Configuring NGINX with environment variables...${RESET}"
envsubst '\$DOMAIN_NAME \$SSL_CERT_PATH \$SSL_KEY_PATH \$WEB_ROOT \$SSL_PROTOCOLS \$HSTS_MAX_AGE' < /etc/nginx/http.d/default.conf.template > /etc/nginx/http.d/default.conf

# Verify the configuration was created correctly
echo -e "${BLUE}Generated configuration:${RESET}"
cat /etc/nginx/http.d/default.conf

# Test nginx configuration
echo -e "${BLUE}Testing NGINX configuration...${RESET}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}NGINX configuration is valid!${RESET}"
    echo -e "${GREEN}Starting NGINX...${RESET}"
    exec "$@"
else
    echo -e "${RED}NGINX configuration is invalid!${RESET}"
    exit 1
fi