#!/bin/bash

RESET='\033[0m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

echo -e "${BLUE}Starting NGINX setup...${RESET}"

set -a
SSL_CERT_PATH="/etc/nginx/ssl/${DOMAIN_NAME}.crt"
SSL_KEY_PATH="/etc/nginx/ssl/${DOMAIN_NAME}.key"
set +a

if [ ! -f "${SSL_CERT_PATH}" ]; then
    echo -e "${YELLOW}Generating SSL certificate for ${DOMAIN_NAME}...${RESET}"
    
    if [ ! -f "${SSL_KEY_PATH}" ]; then
        openssl genrsa -out "${SSL_KEY_PATH}" 2048
    fi

    openssl req -x509 -new -days 365 -subj "/C=TR/ST=Kocaeli/L=Gebze/O=42/CN=${DOMAIN_NAME}"\
        -key "${SSL_KEY_PATH}" -out "${SSL_CERT_PATH}"
    
    echo -e "${GREEN}SSL certificate generated successfully!${RESET}"
else
    echo -e "${GREEN}SSL certificate already exists.${RESET}"
fi

echo -e "${BLUE}Configuring NGINX with environment variables...${RESET}"
envsubst '${DOMAIN_NAME} ${SSL_CERT_PATH} ${SSL_KEY_PATH}' \
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
