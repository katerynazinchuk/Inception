# User documentation

## Services

The project provides a WordPress website, available only over HTTPS. It runs as
three services, each in its own container:

| Service | Role |
|---|---|
| **NGINX** | The only entry point: accepts HTTPS connections on port 443, serves static files and forwards PHP requests to WordPress |
| **WordPress + php-fpm** | The website itself: runs the WordPress PHP code |
| **MariaDB** | The database: stores posts, pages, users and settings |

Only NGINX is reachable from outside; WordPress and MariaDB are accessible only
inside the internal Docker network.

## Starting and stopping

Run these commands from the root of the project:

| Command | Effect |
|---|---|
| `make` | Build and start the whole project |
| `make stop` | Pause the containers (they can be resumed) |
| `make start` | Resume paused containers |
| `make down` | Stop and remove the containers; the website data is kept |

After `make down`, running `make` again brings the website back with all its
content.

## Accessing the website

- **Website:** `https://kzinchuk.42.fr`
- **Administration panel:** `https://kzinchuk.42.fr/wp-admin`

The site uses a self-signed certificate, so the browser shows a security warning
on the first visit. Click **Advanced → Accept the Risk and Continue** (the exact
wording depends on the browser).

## Credentials

| What | Where |
|---|---|
| WordPress administrator login | `WP_ADMIN_USER` in `srcs/.env` |
| WordPress administrator password | `WP_ADMIN_PASSWORD` in `secrets/credentials.txt` |
| Second WordPress user login | `WP_USER` in `srcs/.env` |
| Second WordPress user password | `WP_USER_PASSWORD` in `secrets/credentials.txt` |
| Database user password | `secrets/db_password.txt` |
| Database root password | `secrets/db_root_password.txt` |

These files are not part of the git repository and must be kept private.

**Important:** the passwords in these files are used only during the first
installation. Changing them afterwards does not change the existing passwords.
- To change a WordPress user's password, log in to the administration panel and
  go to **Users → Profile**.
- To reinstall everything with new credentials, run `make fclean` and then `make`.
  **This deletes all website data.**

## Checking that the services are running

1. Check the status of the containers:
```bash
   make ps
```
   All three containers (`mariadb`, `wordpress`, `nginx`) should be `Up`.

2. If a container is not running or keeps restarting, check its logs:
```bash
   docker logs mariadb
   docker logs wordpress
   docker logs nginx
```

3. Check that the website responds:
```bash
   curl -k https://kzinchuk.42.fr
```
   The output should be the HTML of the website. You can also simply open the
   website in a browser.