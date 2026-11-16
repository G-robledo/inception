# Inception

An École 42 project running NGINX, WordPress with PHP-FPM, and MariaDB in three containers, built from the original Debian Bullseye Dockerfiles. WordPress uses PHP 7.4.

## Configuration

On a Linux VM with Docker, the Docker Compose plugin and Make installed:

```sh
git clone https://github.com/G-robledo/inception.git
cd inception
cp srcs/.env.example srcs/.env
cp secrets/.env.example secrets/.env
```

Edit the passwords in `secrets/.env`. In `srcs/.env`, set `DOMAIN_NAME` to the hostname or IPv4 address you will use to open the site. The WordPress administrator is configured through `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` and `WP_ADMIN_PASSWORD`.

For local access, the example uses `localhost`. For access from another machine, use the VM's reachable IP or a DNS name pointing to that VM. Port **443** must be available and reachable.

The environment files are local and ignored by Git. Their names and locations match the original project.

## Start

```sh
make
```

Open **https://localhost**, or **https://YOUR_VM_HOSTNAME** using the configured `DOMAIN_NAME`. NGINX generates a self-signed certificate; expect the browser's local-certificate warning.

Persistent files keep the original directory layout: `mariadb`, `wordpress` and `nginx/ssl`. Their default parent is `data/` in the checkout. Select another absolute path when needed:

```sh
make DATA_DIR=/home/YOUR_LOGIN/data
```

Use the same `DATA_DIR` for subsequent commands. To reuse existing data, point `DATA_DIR` at its parent directory and retain the matching database credentials.

## Commands

| Command | Action |
| --- | --- |
| `make` / `make all` | Create the data directories, build and start the services |
| `make down` | Stop and remove the project's containers and network |
| `make re` | Build and start the services again |
| `make clean` | Remove the project's containers, local service images, Compose volumes and network; host data directories are preserved |

```sh
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f
```

For a custom data directory, pass `DATA_DIR` to these commands too. The Makefile defaults to `docker compose`; a machine using the original standalone executable can use `make COMPOSE=docker-compose`.

## Source layout

- `srcs/docker-compose.yml`: the three services, network and persistent mounts.
- `srcs/requirements/nginx/`: NGINX configuration and certificate startup script.
- `srcs/requirements/wordpress/`: PHP 7.4, WP-CLI and WordPress startup.
- `srcs/requirements/mariadb/`: database image and initialization script.
- `srcs/.env` and `secrets/.env`: local configuration created from the examples.
