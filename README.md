*This project has been created as part of the 42 curriculum by kzinchuk.*

# Inception

## Description
The goal of this project is to learn Docker and the basics of system administration by building a small web infrastructure from scratch, in a way that runs identically and securely on any machine. The infrastructure consists of three services — NGINX, WordPress with php-fpm, and MariaDB — each running in its own container, built from its own Dockerfile based on Debian bookworm. A single docker-compose file describes how the services are connected: a shared network, volumes for persistent data, secrets, and the startup order.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed
- `make` and `openssl`
- The domain `kzinchuk.42.fr` pointing to the local machine:

```bash
echo "127.0.0.1 kzinchuk.42.fr" | sudo tee -a /etc/hosts
```
### Setup

1. Clone the repository:
```bash
   git clone <repository-url> inception
   cd inception
```
2. Build and start:
```bash
   make
```
   On the first run, `make` prepares everything that is not stored in the repository:
   - creates `srcs/.env` from the template `srcs/.env.example`;
   - generates random passwords in `secrets/`;
   - creates the data directories in `/home/kzinchuk/data`.

   Existing files are never overwritten.

3. Open `https://kzinchuk.42.fr` in a browser. The certificate is self-signed,
   so the browser will show a warning: accept it to continue.
   The admin panel is at `https://kzinchuk.42.fr/wp-admin`; the login is
   `WP_ADMIN_USER` from `srcs/.env` and the password is `WP_ADMIN_PASSWORD`
   from `secrets/credentials.txt`.

### Configuration and secrets

Credentials are not stored in the repository. `make` generates them if they are missing:

- `secrets/db_password.txt` — password of the WordPress database user
- `secrets/db_root_password.txt` — password of the MariaDB root user
- `secrets/credentials.txt` — WordPress user passwords, in the format:
```
  WP_ADMIN_PASSWORD=...
  WP_USER_PASSWORD=...
```

Non-secret settings (domain, database name, user names) are in `srcs/.env`,
created from `srcs/.env.example`.

To use your own values, create or edit these files **before the first** `make`:
passwords are applied only when the database and the site are created for the first time.

### Usage

| Command | Description |
|---|---|
| `make` | Build the images and start all containers |
| `make down` | Stop and remove the containers |
| `make stop` / `make start` | Stop / restart containers without removing them |
| `make ps` | Show the status of the containers |
| `make logs` | Follow the logs of all services |
| `make clean` | Remove containers and images |
| `make fclean` | Remove containers, images, volumes and all data |
| `make re` | Full rebuild from scratch |

For more details, see [DEV_DOC.md](DEV_DOC.md) and [USER_DOC.md](USER_DOC.md).

## Project description

### Use of Docker and sources
The WordPress files (PHP files, images, stylesheets) are stored in `/var/www/html`.
NGINX receives the request from the browser, knows where to look, and finds the
requested file: static files are served directly by NGINX, while PHP files are
passed to php-fpm. php-fpm executes the PHP code, retrieves the required data from
the MariaDB database, and generates the HTML page, which NGINX sends back to the browser.

On the first start, the mariadb container creates the WordPress database and its
database user, and the wordpress container downloads WordPress, installs the site
and creates two site users. On later starts, the scripts detect that everything
already exists and start the service directly.

Data is stored in two named volumes: the website files in `/home/kzinchuk/data/wordpress`
and the database in `/home/kzinchuk/data/mariadb`, so it persists when the containers
are removed.

Each service has its own directory `srcs/requirements/<service>/` containing a
`Dockerfile`, a `conf/` directory for configuration files and a `tools/` directory
for the startup script.

### Main design choices

- **Debian bookworm** as the base image: the same distribution as the VM, so the
  same tools and paths apply; PHP extensions come bundled; bash is available.
  The trade-off is larger images than Alpine.
- **Each service runs as PID 1**: the container starts a script via `ENTRYPOINT`
  (exec form), the script prepares everything and then uses `exec` to replace
  itself with the service. The service runs in the foreground and receives
  signals from `docker stop` directly. No `tail -f` or infinite loops.
- **MariaDB is initialized in bootstrap mode** (`mariadbd --bootstrap`): the
  server executes the setup SQL without opening the network and exits, then the
  real server starts. No waiting loops or temporary background server.
- **WordPress is installed with WP-CLI**, not through the browser: the site is
  ready right after `make`, and it is never left in an uninstalled state where
  anyone could complete the setup.
- **php-fpm listens on TCP port 9000** instead of a Unix socket file: NGINX runs
  in a separate container and cannot see files in the WordPress container, so they
  communicate over the Docker network.
- **Idempotent startup scripts**: each step that must run only once is guarded by
  a check (`if`), so restarting a container never recreates or overwrites data.

### Virtual Machines vs Docker

A virtual machine emulates a whole computer and runs its own operating system
kernel. This makes it heavy (gigabytes of disk, minutes to boot) but strongly
isolated. A container has no kernel of its own: all containers share the host
kernel and are isolated from the rest of the system by Linux features (separate
filesystem, processes and network). This makes containers lightweight and fast to
start. In this project, `uname -r` inside a Debian 12 container shows the Debian 13
kernel of the VM. Both are used here: the VM is the host, and the services run in
containers inside it.

### Secrets vs Environment Variables

Environment variables are passed to the container as process variables. They are
easy to use but also easy to expose: `docker inspect` shows them in plain text and
every process in the container can read them. That is why `.env` only contains
non-sensitive configuration: the domain, the database name and user names.
Docker secrets are provided as files in `/run/secrets/`, and only to the containers
that need them: nginx receives no passwords at all, and wordpress does not receive
the database root password. Their content does not appear in `docker inspect`.
Neither the secrets nor `.env` are stored in the git repository.

### Docker Network vs Host Network

The project uses its own Docker network, `inception`. Containers on it find each
other by service name: WordPress connects to `mariadb:3306`, NGINX to
`wordpress:9000`, and Docker resolves these names to IP addresses. Only NGINX's
port 443 is published to the host; the database and php-fpm are reachable only
inside this network. With `network: host`, containers would use the host's network
directly: all their ports, including the database, would be exposed on the machine,
and there would be no network isolation between them.

### Docker Volumes vs Bind Mounts

Both keep data outside the container, so it survives when the container is removed.
A bind mount maps a specific host directory directly into a container, and Docker
does not manage it. A named volume is a Docker object: it has a name, appears in
`docker volume ls`, can be managed with Docker commands, and containers refer to it
by name rather than by a host path. The subject requires named volumes with data
stored in `/home/kzinchuk/data`, so the volumes are declared with the `local` driver
and the options `type: none`, `o: bind` and `device: ...`: Docker treats them as
named volumes, while the files physically live in the required directory.

## Resources

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [The Missing Semester of Your CS Education (MIT)](https://missing.csail.mit.edu/)

### Use of AI

AI (Claude) was used as a mentor throughout the project:
- **Explaining concepts**: images and containers, layers, volumes, secrets,
  networks, PID 1, TLS, FastCGI.
- **Building the services**: together with AI, step by step each service was first
  explored manually in a test container (install it, run it, read the errors), and
  the Dockerfiles, configs and scripts were then written based on what was discovered.
- **Review**: comparing with other implementations and finding improvements
  (for example, the utf8mb4 charset and verifying the allowed TLS versions).
- **Documentation**: written from my own explanations in Ukrainian; AI helped correct
  inaccuracies and translate them into English.
- **Setup and debugging**: guidance with the VM, SSH and git setup, and help reading
  error messages and logs.