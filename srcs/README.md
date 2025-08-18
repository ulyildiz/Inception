# srcs: Compose & Services Reference

This folder contains the Docker Compose file and the three service definitions.

## docker-compose.yml: Key Keywords & Concepts

- `networks:` — defines a custom bridge network `inception` used for inter-service communication.
- `secrets:` — declares secrets and their source files under `../secrets` (mounted into containers under `/run/secrets`).
- `volumes:` — defines named volumes backed by bind mounts to `${HOME}/${LOGIN}/data/...` (see Makefile).
- `services:` — declares `mariadb`, `wordpress`, `nginx`.
  - `build:` — sets context to a container folder.
  - `image:` — names the resulting image tag.
  - `restart: on-failure` — auto-restart policy.
  - `env_file:` — points to a `.env` with non-sensitive defaults.
  - `volumes:` — mounts named volumes into the service.
  - `expose:` — exposes ports to the internal Docker network only (not to host).
  - `ports:` — publishes container port to the host (used only by nginx 443).
  - `secrets:` — makes declared secrets available inside the service.
  - `depends_on:` — startup ordering; not a health check.

## Service Wiring

- MariaDB exposes 3306 internally. WordPress connects to `DB_HOST=mariadb`.
- WordPress exposes 9000 internally for PHP-FPM. NGINX uses `fastcgi_pass wordpress:9000`.
- NGINX publishes 443 to host; TLS cert/key are created or read at startup.

## Common Compose Commands (PowerShell)

```powershell
# Build and start
docker compose -f srcs/docker-compose.yml up -d --build

# Stop
docker compose -f srcs/docker-compose.yml down

# Logs for a service
docker compose -f srcs/docker-compose.yml logs -f wordpress

# Recreate a single service
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

## Volume Paths

- MariaDB: `${HOME}/${LOGIN}/data/mariadb` → `/var/lib/mysql`
- WordPress: `${HOME}/${LOGIN}/data/wordpress` → `/var/www/html`

## Tips

- If you change secrets, recreate affected services so entrypoint scripts re-run with new values.
- If WordPress is already installed (wp-config.php exists), the WordPress setup script will skip reinstall.
