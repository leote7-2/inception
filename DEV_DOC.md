# Developer Documentation

## 1. Overview

This document explains how to configure, build, run, maintain and troubleshoot the Inception project.

The project uses Docker Compose to create a small infrastructure composed of three services:

- **NGINX:** Web server and HTTPS entry point.
- **WordPress:** Website and PHP-FPM application.
- **MariaDB:** Database used by WordPress.

Each service runs in its own container, built from a custom Dockerfile based on Debian Bookworm.

## 2. Requirements

Before starting, make sure the system has:

- A Linux virtual machine.
- Docker Engine.
- Docker Compose plugin.
- GNU Make.
- `sudo` privileges.

Check the installations:

```bash
docker --version
docker compose version
make --version
```

The project is designed to run with the user-specific paths required by the 42 Inception subject.

## 3. Project Structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── init.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── init.sh
```

## 4. Configuration

### 4.1 Environment variables

The environment variables are defined in `srcs/.env`.

```env
DOMAIN_NAME=jhenriq2.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WP_ADMIN_USER=jhenriq2_owner
WP_ADMIN_EMAIL=admin@example.com
WP_USER=wp_user
WP_USER_EMAIL=user@example.com
```

These variables configure the domain, database and WordPress accounts.

The WordPress administrator username must not contain `admin` or `administrator`.

Do not put passwords in this file. Passwords are stored separately using Docker secrets.

### 4.2 Docker secrets

The project uses four secret files:

| File | Purpose |
|---|---|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | MariaDB application user password |
| `secrets/wp_admin_password.txt` | WordPress administrator password |
| `secrets/wp_user_password.txt` | WordPress author password |

If the files need to be recreated, create the directory and add a password to each file:

```bash
mkdir -p secrets

printf '%s' 'your_root_password' > secrets/db_root_password.txt
printf '%s' 'your_database_password' > secrets/db_password.txt
printf '%s' 'your_wordpress_admin_password' > secrets/wp_admin_password.txt
printf '%s' 'your_wordpress_user_password' > secrets/wp_user_password.txt
```

Restrict access to the directory and files:

```bash
chmod 700 secrets
chmod 600 secrets/*.txt
```

The Compose file makes these secrets available to the services that need them.

Changing a secret file after the database has already been initialized does not automatically change the password stored inside MariaDB or WordPress.

**Repository warning:** Keep credentials out of public repositories and out of the official 42 submission. A private GitHub repository is still a place where credentials are stored remotely, so use unique passwords and never reuse them elsewhere.

## 5. Docker Compose

The infrastructure is defined in:

```text
srcs/docker-compose.yml
```

It defines three services, a dedicated network, two persistent volumes and the required secrets.

### 5.1 Services

| Service | Image | Main function |
|---|---|---|
| NGINX | `nginx:inception` | HTTPS entry point |
| WordPress | `wordpress:inception` | PHP-FPM and WordPress |
| MariaDB | `mariadb:inception` | Database |

Each image is built from its own Dockerfile.

### 5.2 Network

All three containers communicate through a dedicated Docker bridge network.

The communication flow is:

1. The browser connects to NGINX through HTTPS on port `443`.
2. NGINX forwards PHP requests to WordPress through FastCGI on port `9000`.
3. WordPress connects to MariaDB on port `3306`.

Only NGINX publishes a port to the host. WordPress and MariaDB are accessible internally through the Docker network.

Containers use their Compose service names to find each other. For example, WordPress connects to the database using `mariadb`.

### 5.3 Volumes and persistent data

The project uses two named Docker volumes:

| Volume | Container path | Host path |
|---|---|---|
| `wordpress_data` | `/var/www/wordpress` | `/home/jhenriq2/data/wordpress` |
| `mariadb_data` | `/var/lib/mysql` | `/home/jhenriq2/data/mariadb` |

The volumes use Docker's local driver with bind-backed storage, meaning the data is stored in the specified host directories.

This ensures that WordPress files and MariaDB data persist when containers are stopped, removed or recreated.

## 6. Makefile

The Makefile provides commands to manage the infrastructure.

| Command | Description |
|---|---|
| `make` | Checks required files and starts the project |
| `make check` | Checks that `.env` and all secret files exist |
| `make up` | Creates data directories and builds/starts containers |
| `make down` | Stops and removes containers and the Compose network |
| `make start` | Starts existing stopped containers |
| `make stop` | Stops running containers |
| `make ps` | Displays container status |
| `make logs` | Displays and follows service logs |
| `make clean` | Removes containers, network and images |
| `make fclean` | Removes containers, network, volumes, images and persistent data |
| `make re` | Performs a full cleanup and starts the project again |

**Important:** `make clean` does not delete persistent volume data. `make fclean` deletes the project data stored under `/home/jhenriq2/data`.

Use `make fclean` carefully: it permanently removes the WordPress and database data.

## 7. Building and Running

From the root of the repository:

```bash
make
```

The `up` target first checks the required configuration files, creates the persistent data directories and then runs:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

To check the containers:

```bash
make ps
```

To follow the logs:

```bash
make logs
```

To stop the project:

```bash
make stop
```

To remove the containers and network while keeping persistent data:

```bash
make down
```

To rebuild and restart a specific service after changing its Dockerfile or related build files:

```bash
docker compose -f srcs/docker-compose.yml up -d --build nginx
```

Replace `nginx` with `wordpress` or `mariadb` when needed.

## 8. Domain and HTTPS

The project uses the domain defined by `DOMAIN_NAME` in `srcs/.env`.

For local testing, the domain must resolve to the machine running the project.

For example, if the browser is running inside the same VM:

```text
127.0.0.1 jhenriq2.42.fr
```

Add the entry to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

If the browser is running on a different machine, use the VM's reachable IP address instead of `127.0.0.1`.

NGINX listens on port `443` and uses a self-signed SSL certificate. The certificate is generated by the NGINX initialization script if it does not already exist.

Access the website through:

```text
https://jhenriq2.42.fr
```

The browser may display a security warning because the certificate is self-signed.

## 9. Container Initialization

Each service has an initialization script that prepares its environment before starting the main process.

### 9.1 MariaDB

The MariaDB initialization script:

1. Reads the root and application passwords from Docker secrets.
2. Checks that the required database environment variables and passwords are available.
3. Creates the MariaDB runtime directory and sets its permissions.
4. Initializes the database system if it has not been initialized before.
5. If the database does not yet exist, starts a temporary MariaDB server with networking disabled.
6. Configures the root password, creates the application database and user, and grants the required privileges.
7. Stops the temporary server and starts the final MariaDB process.

If the database already exists, the initialization step is skipped so that existing data is preserved.

### 9.2 WordPress

The WordPress initialization script:

1. Reads the required passwords from Docker secrets.
2. Waits for MariaDB to become available, attempting an authenticated connection.
3. Downloads WordPress using WP-CLI if the WordPress configuration file does not exist.
4. Creates the WordPress configuration.
5. Installs WordPress if it has not already been installed.
6. Creates the additional WordPress author account.
7. Sets the correct ownership of the WordPress files.
8. Starts PHP-FPM in the foreground.

The script waits for a maximum of 30 attempts, with a two-second interval between attempts.

### 9.3 NGINX

The NGINX initialization script:

1. Checks that `DOMAIN_NAME` is defined.
2. Replaces the domain placeholder in the NGINX configuration.
3. Generates a self-signed SSL certificate if one does not already exist.
4. Tests the NGINX configuration.
5. Starts NGINX in the foreground.

## 10. Useful Development Commands

### Inspect containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Follow logs

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### Enter a container

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Access MariaDB

```bash
docker exec -it mariadb mariadb -u root -p
```

### Inspect the Docker network

```bash
docker network ls
docker network inspect srcs_inception
```

### Inspect volumes

```bash
docker volume ls
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

### Test the HTTPS response

```bash
curl -kI https://jhenriq2.42.fr
```

The `-k` option allows curl to accept the self-signed certificate for testing.

## 11. Troubleshooting

### Containers are not starting

Check their status and logs:

```bash
make ps
make logs
```

### WordPress cannot connect to MariaDB

Check that MariaDB is running and inspect its logs:

```bash
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
```

Verify that the database environment variables and secret files are correct.

### Website cannot be reached

Check that:

- NGINX is running.
- Port `443` is published.
- The domain resolves to the correct machine.
- The NGINX configuration passes its syntax test.

You can test the NGINX configuration inside its container:

```bash
docker exec nginx nginx -t
```

### WordPress changes are disappearing

Check that the named volumes are mounted correctly and that the host directories exist:

```bash
ls -la /home/jhenriq2/data/wordpress
ls -la /home/jhenriq2/data/mariadb
```

Do not use `make fclean` if you need to preserve the existing website or database.

## 12. Important Notes

- Each service runs in its own container.
- Containers communicate through a dedicated Docker bridge network.
- Only NGINX exposes a port to the host.
- Persistent data is stored under `/home/jhenriq2/data`.
- Docker secrets are used for passwords.
- NGINX provides HTTPS using a self-signed certificate.
- The main service processes run in the foreground.
- `make fclean` deletes persistent data and should only be used when a complete reset is intended.