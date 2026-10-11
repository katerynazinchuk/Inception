# Developer documentation

## Project structure

```
.
├── Makefile                      # builds and runs the project via docker compose
├── secrets/                      # passwords (not in git, create manually)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                      # non-secret configuration (not in git)
    ├── docker-compose.yml        # services, network, volumes, secrets
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf    # MariaDB server configuration
        │   └── tools/init.sh         # creates the database and users on first start
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/init.sh         # downloads and installs WordPress on first start
        └── nginx/
            ├── Dockerfile
            └── conf/nginx.conf       # TLS and FastCGI configuration
```

## Setting up the environment from scratch

### Prerequisites

- A Linux virtual machine (Debian is used here)
- Docker Engine with the Docker Compose plugin
- `make` and `git`
- The domain name pointing to the local machine:
```bash
  echo "127.0.0.1 kzinchuk.42.fr" | sudo tee -a /etc/hosts
```

### Configuration: `srcs/.env`

| Variable | Meaning |
|---|---|
| `DOMAIN_NAME` | Domain of the website (`kzinchuk.42.fr`) |
| `MYSQL_DATABASE` | Name of the WordPress database |
| `MYSQL_USER` | Database user that WordPress connects with |
| `WP_TITLE` | Title of the website |
| `WP_ADMIN_USER` | WordPress administrator login (must not contain "admin") |
| `WP_ADMIN_EMAIL` | Administrator email |
| `WP_USER` | Second WordPress user (role: author) |
| `WP_USER_EMAIL` | Second user's email |

### Secrets: `secrets/`

```bash
mkdir -p secrets
openssl rand -hex 12 > secrets/db_password.txt
openssl rand -hex 12 > secrets/db_root_password.txt
```

`secrets/credentials.txt` contains the WordPress user passwords:
```
WP_ADMIN_PASSWORD=...
WP_USER_PASSWORD=...
```

Each secret is mounted only into the containers that need it, as a file in
`/run/secrets/`:

| Secret | mariadb | wordpress | nginx |
|---|---|---|---|
| `db_password` | ✓ | ✓ | |
| `db_root_password` | ✓ | | |
| `credentials` | | ✓ | |

### Using a different login

The login `kzinchuk` appears in several places. To run the project under another
login, update:
- `DATA_DIR` in the `Makefile`
- the `device:` paths of both volumes in `srcs/docker-compose.yml`
- `server_name` in `srcs/requirements/nginx/conf/nginx.conf`
- the certificate subject (`-subj "/CN=..."`) in `srcs/requirements/nginx/Dockerfile`
- `DOMAIN_NAME` in `srcs/.env` and the line in `/etc/hosts`

## Building and launching

```bash
make
```

`make` creates the data directories in `/home/kzinchuk/data` and runs
`docker compose up --build -d`. The images are built from the Dockerfiles, then
the containers start in order: mariadb → wordpress → nginx (`depends_on`).

On the first start:
- **mariadb** initializes the data directory, creates the database, the WordPress
  database user and sets the root password;
- **wordpress** downloads WordPress, creates `wp-config.php`, installs the site and
  creates both users;
- **nginx** starts directly, with no setup script.

On later starts, each step that was already done is skipped.

## Managing containers and volumes

| Command | Description |
|---|---|
| `make ps` | Status of the project's containers |
| `make logs` | Follow the logs of all services |
| `docker logs <service>` | Logs of one service (`mariadb`, `wordpress`, `nginx`) |
| `docker exec -it <service> bash` | Open a shell inside a running container |
| `docker compose -f srcs/docker-compose.yml up --build -d <service>` | Rebuild and restart only one service |
| `docker volume ls` | List volumes |
| `docker volume inspect srcs_mariadb_data` | Show details of a volume, including its host path |
| `docker exec -it mariadb mariadb -u root -p` | Connect to the database as root |
| `docker exec wordpress wp user list --path=/var/www/html --allow-root` | List WordPress users |

## Where the data is stored

The project uses two named volumes, bound to directories on the host:

| Volume | Path in the container | Path on the host |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` (mariadb) | `/home/kzinchuk/data/mariadb` |
| `wordpress_data` | `/var/www/html` (wordpress, nginx) | `/home/kzinchuk/data/wordpress` |

The `wordpress_data` volume is shared by two containers: nginx serves the static
files from it, and php-fpm executes the PHP files from it.

| Command | Containers | Images | Data |
|---|---|---|---|
| `make down` | removed | kept | kept |
| `make clean` | removed | removed | kept |
| `make fclean` | removed | removed | **deleted** |

Because the data lives outside the containers, it persists across `make down` and
`make`. Only `make fclean` deletes it, and the next `make` starts with a fresh
installation.