# User Documentation

This guide explains how to use the Inception infrastructure, including how to start and stop the services, access WordPress, manage credentials and check that everything is working correctly.

## Services Provided

The Inception stack consists of three services:

| Service | Description |
|---|---|
| **NGINX** | Receives HTTPS connections on port 443 and forwards PHP requests to WordPress. |
| **WordPress** | Runs the website and provides the administration panel through PHP-FPM. |
| **MariaDB** | Stores the WordPress database, including posts, users and website settings. |

The services communicate through a dedicated Docker network. Only NGINX is accessible directly from outside the Docker network.

Website files and database data are stored persistently on the host machine under `/home/jhenriq2/data/`.

## Starting and Stopping the Project

All commands must be executed from the project root directory.

### Start the project

```bash
make
```

This command checks the required configuration and secret files, creates the persistent data directories, builds the Docker images and starts the containers in the background.

On the first start, Docker builds the images and WordPress downloads and installs itself. This may take a few minutes.

### Stop the project

```bash
make stop
```

Stops the running containers without removing them.

### Start stopped containers

```bash
make start
```

Starts containers that were previously stopped.

### Stop and remove containers

```bash
make down
```

Stops and removes the containers and Docker network. Persistent data is kept.

### Remove everything

```bash
make fclean
```

**Warning:** This command removes containers, images, volumes and the persistent data directories. All WordPress content and database data will be lost.

## Accessing the Website

The website is available at:

**https://jhenriq2.42.fr**

Make sure the domain resolves to the virtual machine's local IP address.

For a local setup, the domain can be added to `/etc/hosts`:

```bash
echo "127.0.0.1 jhenriq2.42.fr" | sudo tee -a /etc/hosts
```

When using a different local IP address, replace `127.0.0.1` with the correct address.

The website uses a self-signed TLS certificate. The browser may display a security warning. This is expected for this project.

The infrastructure serves HTTPS on port 443. HTTP on port 80 is not configured.

### WordPress Administration Panel

The administration panel is available at:

**https://jhenriq2.42.fr/wp-admin**

Log in using the WordPress administrator username and password.

The project creates two WordPress accounts during the first installation:

| Account | Username configuration | Role |
|---|---|---|
| Administrator | `WP_ADMIN_USER` in `srcs/.env` | Administrator |
| Regular user | `WP_USER` in `srcs/.env` | Author |

The administrator username configured for this project is `jhenriq2_owner`.

## Credentials

Credentials are stored in two locations:

- `srcs/.env`: contains general configuration, including the domain, database name, usernames and email addresses.
- `secrets/`: contains the passwords used by the database and WordPress.

The four secret files are:

| File | Purpose |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | Password for the MariaDB user used by WordPress |
| `secrets/wp_admin_password.txt` | WordPress administrator password |
| `secrets/wp_user_password.txt` | WordPress regular user password |

To read a password, use:

```bash
cat secrets/wp_admin_password.txt
```

Replace the filename with the secret you want to inspect.

**Important:** The initial passwords are applied when the services are first configured. Editing a secret file later does not automatically change an existing WordPress account or MariaDB password.

WordPress passwords can be changed through the administration panel. Database credentials must be changed consistently in MariaDB and the WordPress configuration.

Reinitializing the project with `make re` resets the persistent data and causes the services to be configured again using the current environment variables and secret files. This operation deletes all existing website and database data.

## Checking That Everything Works

### Check container status

```bash
make ps
```

The three containers should be running:

- `nginx`
- `wordpress`
- `mariadb`

### Check service logs

```bash
make logs
```

This displays the logs of all services.

To inspect an individual container:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check website response

```bash
curl -kI https://jhenriq2.42.fr
```

The `-k` option allows curl to accept the self-signed certificate.

A successful response should include an HTTP status such as `200 OK`.

### Check database access

```bash
docker exec -it mariadb mariadb -u root -p
```

Enter the password stored in `secrets/db_root_password.txt`.

Inside the MariaDB shell, check the WordPress database:

```sql
SHOW TABLES FROM wordpress;
```

The database should contain the WordPress tables.

## Troubleshooting

| Problem | Possible cause |
|---|---|
| Website cannot be reached | The domain is missing from `/etc/hosts`, or NGINX is not running. |
| Browser displays a certificate warning | Expected because the project uses a self-signed certificate. |
| `502 Bad Gateway` | WordPress/PHP-FPM may still be starting or may have failed. Check its logs. |
| Database connection error | MariaDB may not be ready, or the database credentials may not match. |
| Missing `.env` or secret file | Check that all required configuration and secret files exist and are not empty. |
| Containers keep restarting | Inspect the logs of the affected service to identify the error. |

For further technical information, environment setup and development commands, see [DEV_DOC.md](DEV_DOC.md).