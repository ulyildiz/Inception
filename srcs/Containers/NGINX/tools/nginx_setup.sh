#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

echo -e "${BLUE}Starting NGINX setup...${RESET}"

# Use environment variables
set -a
SSL_CERT_PATH="/etc/nginx/ssl/${DOMAIN_NAME}.crt"
SSL_KEY_PATH="/etc/nginx/ssl/${DOMAIN_NAME}.key"
SSL_PROTOCOLS="TLSv1.2 TLSv1.3"
WEB_ROOT="/var/www/html"
SSL_CSR_PATH="/etc/nginx/ssl/${DOMAIN_NAME}.csr"
set +a

mkdir -p /etc/nginx/ssl
mkdir -p ${WEB_ROOT}

chown -R www:www ${WEB_ROOT}
chmod -R 755 ${WEB_ROOT}

if [ ! -f "${SSL_CERT_PATH}" ]; then
    echo -e "${YELLOW}Generating SSL certificate for ${DOMAIN_NAME}...${RESET}"
    
    # Generate private key
    openssl genrsa -out "${SSL_KEY_PATH}" 2048
    
    # Generate certificate signing request
    openssl req -new -key "${SSL_KEY_PATH}" -out "${SSL_CSR_PATH}" -subj "/C=TR/ST=KOCAELI/L=GEBZE/O=42KOCAELI/CN=${DOMAIN_NAME}"
    
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

echo -e "${BLUE}Configuring NGINX with environment variables...${RESET}"
envsubst '${DOMAIN_NAME} ${SSL_CERT_PATH} ${SSL_KEY_PATH} ${WEB_ROOT} ${SSL_PROTOCOLS}' \
  < /etc/nginx/http.d/default.conf.template \
  > /etc/nginx/http.d/default.conf

echo -e "${BLUE}Generated configuration:${RESET}"
cat /etc/nginx/http.d/default.conf

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
