# NGINX Container & Setup Script

This guide explains how the NGINX container is built and initialized, what every command does, and how environment variables and secrets affect runtime behavior. It’s designed to be instructive and practical.

## Overview

- Base image: `alpine:3.22.1`
- Purpose: Terminate TLS (443), serve static assets, and proxy PHP requests to the WordPress PHP-FPM service at `wordpress:9000`.
- Security: Uses Docker secrets for domain and SSL subject data; generates a self-signed cert if none exists.

## File Layout

```
srcs/Containers/NGINX/
├── .env                        # Non-secret defaults and runtime config
├── Dockerfile                  # Builds the NGINX image
├── conf/
│   └── default.conf.template   # vhost template; env-injected at runtime
└── tools/
    └── nginx_setup.sh          # Entry-point: secrets, SSL, config, boot
```

## Dockerfile: Line-by-line

```
FROM alpine:3.22.1
```
- Minimal base for smaller, secure images.

```
apk update && apk upgrade
apk add --no-cache nginx openssl gettext
```
- Updates package index, upgrades base packages.
- Installs:
  - `nginx`: web server
  - `openssl`: generate keys/certs
  - `gettext`: provides `envsubst` to inject environment vars into config templates.

```
adduser -D -g 'www' www
mkdir -p /www /var/www/html /etc/nginx/ssl
chown -R www:www /var/lib/nginx /www /var/www/html
```
- Creates unprivileged `www` user and required dirs with proper ownership.

```
COPY ./tools/nginx_setup.sh /
COPY ./conf/default.conf.template /etc/nginx/http.d/default.conf.template
chmod +x /nginx_setup.sh
EXPOSE 443
ENTRYPOINT ["sh", "/nginx_setup.sh"]
CMD ["nginx", "-g", "daemon off;"]
```
- Ships the setup script and vhost template.
- `EXPOSE 443` documents the TLS port.
- Entrypoint runs the setup script, which finally `exec`s the CMD.

## Setup Script: `tools/nginx_setup.sh`

Key steps and commands:

1) Read secrets
- Sources `/run/secrets/nginx_domain` to set `DOMAIN_NAME`.
- Reads `/run/secrets/ssl_config` 4-line file: Country, State, City, Organization.

2) Prepare paths and permissions
- Ensures `/etc/nginx/ssl` and `${WEB_ROOT}` exist; sets `www:www` ownership and `755` perms.

3) Generate SSL if missing
- Private key: `openssl genrsa -out "$SSL_KEY_PATH" 2048`
- CSR: `openssl req -new -key "$SSL_KEY_PATH" -out "$SSL_CSR_PATH" -subj "/C=.../ST=.../L=.../O=.../CN=$DOMAIN_NAME"`
- Self-signed cert: `openssl x509 -req -days 365 -in "$SSL_CSR_PATH" -signkey "$SSL_KEY_PATH" -out "$SSL_CERT_PATH"`
- Cleans CSR; sets liberal file perms (777) for demo convenience.

4) Render NGINX config from template
- `envsubst` injects env vars into `default.conf.template` → `default.conf`.

5) Validate and start
- `nginx -t` tests configuration.
- On success: `exec "$@"` runs the container’s CMD (`nginx -g 'daemon off;'`).

## VHost Template: `conf/default.conf.template`

Important directives and keywords:

- `listen 443 ssl; http2 on;` — TLS with HTTP/2.
- `server_name ${DOMAIN_NAME};` — virtual host name.
- `ssl_certificate ${SSL_CERT_PATH}; ssl_certificate_key ${SSL_KEY_PATH};` — cert/key paths.
- `ssl_protocols ${SSL_PROTOCOLS};` — allowed TLS versions, e.g. `TLSv1.2 TLSv1.3`.
- `root ${WEB_ROOT}; index index.html index.php;` — docroot and index order.
- `location / { try_files $uri $uri/ /index.php?$query_string; }` — typical WordPress-friendly routing.
- `location ~ \.php$ { ... fastcgi_pass wordpress:9000; }` — forwards PHP to PHP-FPM in the `wordpress` container.
  - `fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;` — tells PHP-FPM which script to execute.
  - `fastcgi_read_timeout 300;` — extends timeout for slow PHP responses.
- `location ~ /\.` — denies access to hidden files (security).

## Environment Variables (.env)

Configured in `srcs/Containers/NGINX/.env`:
- `DOMAIN_NAME` — primary host name.
- `SSL_CERT_PATH` — full path to certificate file inside the container.
- `SSL_KEY_PATH` — full path to private key inside the container.
- `WEB_ROOT` — document root directory (mounted from WordPress volume).
- `SSL_PROTOCOLS` — allowed TLS versions (e.g., `TLSv1.2 TLSv1.3`).
- `SSL_CIPHERS` — cipher suite list (optional; not currently injected in the template).
- `HSTS_MAX_AGE` — if you add HSTS, this controls duration (not currently used in template).

## Secrets

- `secrets/nginx.txt` → `/run/secrets/nginx_domain` — sets `DOMAIN_NAME`.
- `secrets/ssl_config.txt` → `/run/secrets/ssl_config` — 4-line subject fields used by `openssl req -subj`.

Example development vs production updates can be made by editing these secret files before `docker compose up`.

## Commands Used Cheat Sheet

- `apk add --no-cache <pkg>` — install packages on Alpine without cache.
- `openssl genrsa -out key.pem 2048` — generate RSA private key.
- `openssl req -new -key key.pem -out site.csr -subj "/C=..../CN=domain"` — create CSR non-interactively.
- `openssl x509 -req -days 365 -in site.csr -signkey key.pem -out cert.pem` — self-signed cert.
- `envsubst` — substitute environment variables in a text template.
- `nginx -t` — test NGINX config for syntax/consistency.

## Security Notes

- Secrets keep sensitive data out of the image and logs.
- Self-signed certificates are fine for local use; use real certs in production.
- The container runs NGINX with files owned by a non-root `www` user.
