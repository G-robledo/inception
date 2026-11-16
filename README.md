# Inception

An École 42 project running WordPress, MariaDB and NGINX in separate containers, built from custom Debian Bookworm Dockerfiles.

## Quick start

On a Linux VM with Docker, Docker Compose v2.20 or newer, and Make installed:

```sh
git clone https://github.com/G-robledo/inception.git
cd inception
make
```

Open **https://localhost:8443** on that machine. The certificate is self-signed, so the browser will ask you to accept it for this local demo.

The first run generates an ignored `.env` with random passwords. The WordPress administrator is `siteowner`; its password is `WP_ADMIN_PASSWORD` in that file. `make` waits for the services to be healthy before finishing.

## Access from another machine

Set the VM's reachable IPv4 address or DNS hostname on the first run:

```sh
make DOMAIN_NAME=192.0.2.10
```

Replace the example address with the VM's address and open **https://YOUR_VM_IP:8443**. A DNS name must resolve to that VM. The chosen port must also be reachable through the VM's firewall or hosting provider.

Choose another port if needed:

```sh
make DOMAIN_NAME=your-vm.example HTTPS_PORT=9443
```

You can also edit `DOMAIN_NAME` and `HTTPS_PORT` in `.env` and run `make` again. WordPress's canonical URL and the local certificate follow the configured hostname and port. Command-line settings apply to that invocation; edit `.env` to keep them as the new defaults.

No user-specific host directory or fixed container name is required. The setup accepts DNS hostnames and IPv4 addresses; `DOMAIN_NAME` must not include `https://`, a port or a path.

## Architecture and storage

| Service | Role |
| --- | --- |
| MariaDB | Initialize the database and application user, then serve database requests |
| WordPress | Download and install WordPress, manage the initial users and run PHP-FPM |
| NGINX | Generate a local HTTPS certificate and serve the site through PHP-FPM |

Compose waits for MariaDB to be healthy before starting WordPress, then for WordPress before starting NGINX. Startup scripts can resume an interrupted first installation without deleting WordPress files or recreating an existing database.

Docker manages three project-scoped named volumes for the database, WordPress files and certificates. The data survives service restarts, container recreation, `make down` and `make clean`. Keep `.env` with those volumes so the database credentials continue to match. Changing password variables does not reset existing WordPress accounts or reconfigure an already initialized database.

## Commands

| Command | Action |
| --- | --- |
| `make` / `make all` | Generate missing configuration, build and start the services, and wait for readiness |
| `make init` | Generate `.env` if missing, preserving an existing file |
| `make config` | Validate the resolved Compose configuration |
| `make ps` | Show service status |
| `make logs` | Follow service logs |
| `make down` | Stop and remove the project's containers and network |
| `make re` | Build and start again, keeping data |
| `make clean` | Remove the project's containers, network and local service images, keeping data volumes |
| `make fclean` | Also delete the project's database, WordPress and certificate volumes; keep the local configuration file |
| `make test` | Run isolated Docker integration checks; requires curl |

`make clean` removes the project's containers, network and service images while preserving stored data.

`make fclean` also deletes the database, WordPress files and certificate volumes. The local `.env` configuration is preserved.

Use `PROJECT_NAME=another-name` for an independent Compose project, `ENV_FILE=another.env` for another configuration file, or `WAIT_TIMEOUT=300` if startup needs more time. Each simultaneously running project needs a different published port.

`.env.example` documents the variables; `make init` generates fresh local passwords instead of copying the example values. Application and database identifiers should contain only letters, digits or underscores. Do not commit real credentials.

## Integration checks

```sh
make test
```

The smoke test builds a temporary Compose project and checks:

- A first installation, healthy services and the WordPress page over HTTPS.
- Database and file persistence through restart and container recreation.
- A hostname change from an IPv4 address to `localhost`, including the certificate and WordPress URL.
- Data preservation after the real `make clean` command.
- Removal of the project's data volumes after `make fclean`.

The test removes only its own temporary project and test volumes when finished. It uses port `18443` by default; override it with `TEST_HTTPS_PORT=19443 make test`.

## Existing VM installations

The previous configuration used bind mounts under `/home/greg/data`. This version creates Docker-managed volumes and does not import or delete those old directories. Back up the old database, WordPress files and configuration before switching if you want to retain an existing site, then restore them into the new setup. Stop the old containers before starting another instance on the same port.

## References

- [Compose startup order and health checks](https://docs.docker.com/compose/how-tos/startup-order/)
- [MariaDB system-table initialization](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-install-db)
- [WP-CLI installation command](https://developer.wordpress.org/cli/commands/core/install/)
