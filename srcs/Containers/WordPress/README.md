# WordPress Container & Setup Script

This document explains how the WordPress container in this project is built, configured, and initialized, with a focus on the `tools/wordpress_setup.sh` script. It also covers inputs (env + secrets), persistence, and integration with MariaDB and NGINX.

## Overview

- Base image: `alpine:3.22.1`
- PHP-FPM: PHP 8.2 with common extensions
- Bootstrap: `wp-cli` is installed in the image and used at runtime to install/configure WordPress
- Database: Connects to the `mariadb` service on the shared `inception` network
- Web server: Served by NGINX, which forwards PHP requests to this container’s PHP-FPM on port 9000
- Persistence: WordPress files are stored in a Docker volume mounted at `/var/www/html`

## File Layout

```
srcs/Containers/WordPress/
├── .env                       # Non-secret defaults and runtime configuration
├── Dockerfile                 # Builds PHP-FPM + wp-cli image
├── conf/
│   ├── php.ini                # Custom PHP overrides (e.g., memory_limit)
│   └── www.conf               # PHP-FPM pool config (listens on 0.0.0.0:9000)
└── tools/
    └── wordpress_setup.sh     # Initialization and bootstrap logic
```

## Inputs: Environment Variables and Secrets

The container consumes both an `.env` file and Docker secrets. Sensitive values are provided via secrets and sourced at runtime by the setup script.

- `.env` (see `srcs/Containers/WordPress/.env`):
  - `DB_HOST` (default `mariadb`) — hostname of the MariaDB service
  - `WP_URL` — site URL (e.g., `https://example.com`)
  - `WP_TITLE` — site title
  - `WP_PATH` (default `/var/www/html`) — WordPress install path
  - Placeholders for admin/user fields exist here but are intended to come from secrets

- Secrets (mounted under `/run/secrets/` from files in `secrets/`):
  - `db_password.txt` → sets `MARIADB_USER_PASSWORD`
  - `db_root_password.txt` → sets `MARIADB_ROOT_PASSWORD` (not used by this script but used by MariaDB)
  - `mariadb.txt` → sets `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_ROOT`
  - `wordpress.txt` → sets `WP_ADMIN`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`, `WP_USER_PASSWORD`

> Note: The setup script explicitly sources `/run/secrets/db_password`, `/run/secrets/mariadb`, and `/run/secrets/wordpress` and exits if any are missing.

## What `tools/wordpress_setup.sh` Does

1. Loads secrets: sources the three secret files to populate DB and WordPress credentials.
2. Waits for MariaDB: retries until the database is reachable using `mariadb -h${DB_HOST} ...`.
3. Ensures wp-cli is current: runs `wp-cli.phar cli update --yes --allow-root` and sets `PHP_MEMORY_LIMIT=512M` for wp-cli.
4. Downloads WordPress core into `WP_PATH` (default `/var/www/html`) and verifies the download via `wp-config-sample.php`.
5. Creates `wp-config.php` using `wp config create` with DB name, user, password, and host.
6. Installs WordPress using `wp core install` with URL, title, and admin credentials from secrets.
7. Creates an additional user (role: subscriber) if provided.
8. Fixes ownership/permissions for the install path (`chown -R www:www`, `chmod -R 755`).
9. Starts PHP-FPM 8.2 in the foreground: `exec /usr/sbin/php-fpm82 -F -R`.

Idempotency: If `${WP_PATH}/wp-config.php` already exists, the script assumes WordPress is installed and skips the install steps.

## Docker Compose Integration

From `srcs/docker-compose.yml`:

- Service name: `wordpress`
- Exposes: `9000` (PHP-FPM) to the `inception` network; NGINX connects to this
- Volume: `wordpress` → `/var/www/html` (persists code and uploaded content)
- Depends on: `mariadb`
- Secrets: `db_password`, `db_root_password`, `wordpress`, `mariadb`
- Env file: `srcs/Containers/WordPress/.env`

## Configuration Notes

- PHP-FPM pool (`conf/www.conf`) listens on `0.0.0.0:9000`, user/group `www`.
- `conf/php.ini` adds/overrides INI values (e.g., `memory_limit = 512M`).
- The image installs many common PHP extensions (mysqli, pdo_mysql, mbstring, gd, intl, zip, etc.).
- `wp-cli` binary lives at `/usr/local/bin/wp-cli.phar` and is invoked as `wp-cli.phar`.

## How to Use

1. Fill secrets under `secrets/`:
   - `mariadb.txt` with DB name/user
   - `db_password.txt` with DB user password
   - `wordpress.txt` with admin and optional subscriber user details
2. Ensure `WP_URL` and `DB_HOST` are correct in `srcs/Containers/WordPress/.env`.
3. Start the stack from the project root:

```powershell
# Windows PowerShell
docker compose -f srcs/docker-compose.yml up -d --build
```

Once healthy, access the site at `WP_URL` via NGINX (port 443 is published by the `nginx` service).

## Troubleshooting

- Database connectivity:
  - Confirm the `mariadb` service is up and the `wordpress` container can resolve `DB_HOST`.
  - Verify `MARIADB_DATABASE`, `MARIADB_USER`, and `MARIADB_USER_PASSWORD` values in secrets.
- Re-install/first-run logic:
  - If `wp-config.php` already exists in the volume, the script won’t reinstall. Remove it only if you intend to reinstall.
- File permissions:
  - The script sets ownership to `www:www`. If you override volumes or paths, ensure PHP-FPM can read/write as needed.
- URL and NGINX:
  - `WP_URL` should match your NGINX TLS/host configuration; mismatches can cause redirects or mixed content warnings.

## Security Considerations

- Secrets are used for all sensitive values (DB creds, WP admin credentials). Avoid committing secrets to version control.
- The database port is only exposed internally to the `inception` network; it is not published to the host.
- PHP runs as the unprivileged `www` user.

## Commands & Keywords Cheat Sheet

- `wp-cli.phar core download --path=... --allow-root` — download WordPress core files.
- `wp-cli.phar config create --dbname=... --dbuser=... --dbpass=... --dbhost=...` — generate `wp-config.php`.
- `wp-cli.phar core install --url=... --title=... --admin_user=... --admin_password=... --admin_email=...` — perform initial install.
- `wp-cli.phar user create <user> <email> --user_pass=... --role=subscriber` — add user.
- `php-fpm82 -F -R` — start PHP-FPM in foreground and do not chroot workers.

### Developer Tips

- To run arbitrary wp-cli commands in the running container:
  ```powershell
  docker exec -it wordpress sh -lc "cd /var/www/html && wp-cli.phar plugin list --allow-root"
  ```
- To reinstall from scratch (DANGER: deletes content), remove the WordPress volume and re-up.
