# Inception

A small Docker infrastructure that serves a WordPress site over HTTPS, built entirely from scratch (custom Dockerfiles, no pre-built application images) as three containers orchestrated by Docker Compose:

- **NGINX** — the only entry point, terminates TLS on port 443 and proxies PHP requests to WordPress via FastCGI.
- **WordPress** (PHP-FPM 8.2) — the application itself, installed and configured automatically with [WP-CLI](https://wp-cli.org/) on first boot.
- **MariaDB** — the database backing WordPress.

Each service runs in its own Alpine-based container, on its own Dockerfile, and talks to the others only over a dedicated Docker network.

## Architecture

```
                         ┌──────────────┐
   host:443  ───────────▶│    nginx     │  TLS termination (self-signed cert)
                         └──────┬───────┘
                                │ FastCGI :9000
                         ┌──────▼───────┐
                         │  wordpress   │  PHP-FPM 8.2 + WP-CLI bootstrap
                         └──────┬───────┘
                                │ :3306
                         ┌──────▼───────┐
                         │   mariadb    │
                         └──────────────┘

        all three containers share the "inception" bridge network
```

- Only `nginx` is exposed to the host (port `443`). `wordpress` (`9000`) and `mariadb` (`3306`) are reachable only from inside the `inception` network.
- WordPress files live in a named volume shared between the `wordpress` and `nginx` containers (mounted at `/var/www/html` in both), so NGINX can serve WordPress's static assets directly while forwarding `.php` requests to PHP-FPM.
- Database files live in their own named volume, mounted into `mariadb` at `/var/lib/mysql`.
- Both volumes are backed by bind mounts on the host, under `${HOME}/${LOGIN}/data/` (see [Data persistence](#data-persistence)).

## Requirements

- Docker and Docker Compose (`docker-compose` v1 CLI, as used by the Makefile — `docker compose` v2 works too if you adjust the Makefile)
- `make`

## Project layout

```
.
├── Makefile
├── secrets/
│   ├── mariadb.txt          # DB name, app user, root label, both passwords
│   └── wordpress.txt        # WP admin + a second WP user
└── srcs/
    ├── docker-compose.yml
    └── Containers/
        ├── .env               # WP_URL, WP_TITLE, DOMAIN_NAME
        ├── MariaDB/
        │   ├── Dockerfile
        │   ├── conf/db.cnf              # server config (utf8mb4, port 3306, ...)
        │   └── tools/mariadb_setup.sh   # first-boot DB/user bootstrap
        ├── WordPress/
        │   ├── Dockerfile
        │   ├── conf/php.ini             # memory_limit, etc.
        │   ├── conf/www.conf            # php-fpm pool, listens on 0.0.0.0:9000
        │   └── tools/wordpress_setup.sh # WP-CLI download/config/install
        └── NGINX/
            ├── Dockerfile
            ├── conf/default.conf.template
            └── tools/nginx_setup.sh     # generates the self-signed cert, renders the vhost
```

## Configuration

### `srcs/Containers/.env`

Non-sensitive settings, loaded by both the `wordpress` and `nginx` services:

```env
WP_URL=https://your-login.42.fr
WP_TITLE="Your site title"
DOMAIN_NAME=your-login.42.fr
```

### `secrets/mariadb.txt`

```env
MARIADB_DATABASE=db
MARIADB_USER=mysql
MARIADB_ROOT=root
MARIADB_ROOT_PASSWORD=...
MARIADB_USER_PASSWORD=...
```

### `secrets/wordpress.txt`

```env
WP_ADMIN=...
WP_ADMIN_PASSWORD=...
WP_ADMIN_EMAIL=...

WP_USER=...
WP_USER_PASSWORD=...
WP_USER_EMAIL=...
```

These two files are mounted read-only into their containers by Docker Compose as `secrets:` (`/run/secrets/mariadb` and `/run/secrets/wordpress`), and are `source`d by the setup scripts at startup. **They should never contain real/production credentials in version control** — treat the committed values as placeholders to replace locally.

> Note: TLS subject fields (country/state/city/org) and the domain used for the certificate's `CN` are not read from a secret file — they're generated on the fly by `nginx_setup.sh` using `DOMAIN_NAME` from `.env`, with the rest hardcoded in the script.

## Setup

1. Edit `secrets/mariadb.txt` and `secrets/wordpress.txt` with your own values.
2. Edit `srcs/Containers/.env` — set `DOMAIN_NAME` (and `WP_URL` to match, `https://<DOMAIN_NAME>`).
3. Edit the `LOGIN` variable at the top of the `Makefile` if you're not `ulyildiz` — it's used to build the bind-mount path for persisted data.
4. Point the domain at your machine, e.g. add to `/etc/hosts`:
   ```
   127.0.0.1   your-login.42.fr
   ```
5. Build and start everything:
   ```bash
   make up
   ```
6. Visit `https://your-login.42.fr` (the certificate is self-signed, so your browser will warn you — that's expected).

## Make targets

| Target | Effect |
|---|---|
| `make up` / `make` | Create the data directories, build the images, start all containers (detached) |
| `make down` | Stop and remove the containers |
| `make stop` | Stop the containers without removing them |
| `make status` | Show `docker-compose ps` |
| `make logs` | Follow logs for all services |
| `make dev-logs-nginx` / `-wordpress` / `-mariadb` | Follow logs for a single service |
| `make shell-nginx` / `-wordpress` / `-mariadb` | Open a shell inside a running container |
| `make clean` | Stop containers and run `docker system prune` |
| `make fclean` | Full teardown: remove containers, volumes, images, the host data directory, and prune the network/system |
| `make re` | `fclean` followed by `up` |

## How each service bootstraps itself

- **MariaDB** — on first run, initializes the data directory with `mariadb-install-db`, then runs a one-off SQL script (via `mariadbd --bootstrap`) that creates the application database and user, and sets the root password — all values coming from `secrets/mariadb.txt`. A marker file (`/var/lib/mysql/.srcs_mariadb`) prevents this from running again on subsequent starts.
- **WordPress** — waits for MariaDB to accept connections, then uses `wp-cli.phar` to download WordPress core (if not already present in the volume), generate `wp-config.php`, run the site install (admin user from `secrets/wordpress.txt`), and create a second, `subscriber`-role user. All of this is idempotent — it's skipped on subsequent restarts once already done.
- **NGINX** — generates a self-signed TLS certificate for `DOMAIN_NAME` on first run (skipped if one already exists), renders `default.conf.template` into the final NGINX config via `envsubst`, validates it with `nginx -t`, and only then starts NGINX.

## Data persistence

The `mariadb` and `wordpress` named volumes are bind-mounted to the host filesystem so data survives `docker compose down`/container recreation:

- `${HOME}/${LOGIN}/data/mariadb` → `/var/lib/mysql` (in the `mariadb` container)
- `${HOME}/${LOGIN}/data/wordpress` → `/var/www/html` (shared between `wordpress` and `nginx`)

`make fclean` deletes this data directory entirely — use it only when you actually want a clean slate.

## License

MIT — see [LICENSE](LICENSE).
