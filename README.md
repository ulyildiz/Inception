# Inception Stack: NGINX + WordPress + MariaDB

This repository provisions a three-service stack using Docker Compose:

- NGINX: TLS termination, static file serving, and FastCGI proxy to PHP-FPM
- WordPress (PHP-FPM): WordPress runtime + wp-cli bootstrap
- MariaDB: relational database for WordPress

Key ideas: minimal Alpine images, Docker secrets for sensitive values, and idempotent startup scripts.

## Layout

```
.
├── Makefile
├── secrets/                         # Plain files used as Docker secrets
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── mariadb.txt
│   ├── nginx.txt
│   ├── ssl_config.txt
│   └── wordpress.txt
└── srcs/
    ├── docker-compose.yml
    └── Containers/
        ├── MariaDB/
        │   ├── Dockerfile
        │   ├── README.md
        │   ├── conf/db.cnf
        │   └── tools/mariadb_setup.sh
        ├── NGINX/
        │   ├── Dockerfile
        │   ├── README.md
        │   ├── conf/default.conf.template
        │   └── tools/nginx_setup.sh
        └── WordPress/
            ├── Dockerfile
            ├── README.md
            ├── .env
            ├── conf/php.ini
            ├── conf/www.conf
            └── tools/wordpress_setup.sh
```

## Quick start (Windows PowerShell)

```powershell
# Ensure Docker Desktop is running
# Create data dirs via Makefile (optional)
make up

# Or with compose directly
docker compose -f srcs/docker-compose.yml up -d --build
```

- Then browse to the URL configured in `srcs/Containers/WordPress/.env` as `WP_URL`.

## Secrets format summary

- secrets/mariadb.txt
  - MARIADB_DATABASE=...
  - MARIADB_USER=...
  - MARIADB_ROOT=...
- secrets/db_password.txt
  - MARIADB_USER_PASSWORD=...
- secrets/db_root_password.txt
  - MARIADB_ROOT_PASSWORD=...
- secrets/wordpress.txt
  - WP_ADMIN=...
  - WP_ADMIN_PASSWORD=...
  - WP_ADMIN_EMAIL=...
  - WP_USER=...
  - WP_USER_EMAIL=...
  - WP_USER_PASSWORD=...
- secrets/nginx.txt
  - DOMAIN_NAME=example.com
- secrets/ssl_config.txt (4 lines)
  1. Country (C)
  2. State/Province (ST)
  3. City/Locality (L)
  4. Organization (O)

## Make targets (highlights)

- make up — build and start
- make down — stop
- make stop — stop + remove orphans
- make status — list services
- make logs — follow logs
- make clean — prune non-persistent
- make fclean — full teardown (images, volumes, data)
- make re — fclean + up
- make shell-* — open sh inside a service

## Notes

- Data is persisted under ${HOME}/${LOGIN}/data (see Makefile and docker-compose volumes).
- The stack uses a custom bridge network "inception" for internal connectivity.
