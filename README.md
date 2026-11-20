*This project has been created as part of the 42 curriculum by jhenriq2.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. Its goal is to build a small infrastructure using Docker and Docker Compose, running several services inside dedicated containers.

The infrastructure consists of three services:

- **NGINX:** acts as the entry point to the infrastructure and handles HTTPS connections.
- **WordPress:** runs the website using PHP-FPM.
- **MariaDB:** stores the WordPress database.

Each service is built from its own Dockerfile, using Debian Bookworm as its base image.

The services communicate through a dedicated Docker bridge network. Only NGINX exposes a port to the host machine: port `443`, using TLS.

The project also uses Docker Secrets to handle passwords and persistent storage to preserve WordPress files and MariaDB data.

## Project Description

### Infrastructure overview

The infrastructure follows this communication flow:

flowchart TD
    A[User / Browser] -->|HTTPS :443| B[NGINX]
    B -->|FastCGI :9000| C[WordPress]
    C -->|MariaDB :3306| D[MariaDB]

- NGINX receives HTTPS requests.
- NGINX forwards PHP requests to WordPress through PHP-FPM.
- WordPress communicates with MariaDB to access the database.
- All three services communicate through the dedicated Docker network.

### Docker

Docker is used to package each service and its dependencies into an isolated container.

Each service has its own Dockerfile, which defines the base image, required packages, configuration files and startup script.

The Docker images are built locally and use the `:inception` tag.

Docker Compose manages the containers, network, volumes and secrets.

### Services

#### NGINX

NGINX is the only service exposed to the host machine.

- Listens on port `443`.
- Uses HTTPS with TLS 1.2 and TLS 1.3.
- Uses a self-signed SSL certificate generated with OpenSSL.
- Forwards PHP requests to the WordPress container through PHP-FPM.

#### WordPress

WordPress runs with PHP-FPM 8.2.

- Uses WP-CLI to configure and install WordPress.
- Connects to the MariaDB service.
- Creates the WordPress administrator account and an additional user.
- Stores its website files in persistent storage.
- Waits for MariaDB to become available before attempting installation.

#### MariaDB

MariaDB is responsible for database management.

- Initializes the database on the first startup.
- Creates the WordPress database and database user.
- Reads passwords from Docker Secrets.
- Stores database files in persistent storage.

### Docker Network

The project uses a dedicated bridge network named `inception`.

This allows the containers to communicate using their service names, without exposing WordPress or MariaDB ports directly to the host.

Only NGINX publishes a host port.

### Persistent Storage

The project uses two named Docker volumes:

- `wordpress_data`: stores WordPress website files.
- `mariadb_data`: stores MariaDB database files.

The volumes use the local driver with host directories under:

flowchart TD
    A["/home/jhenriq2/data/"] --> B["wordpress/"]
    A --> C["mariadb/"]

This ensures that the data remains available after containers are stopped, removed or recreated.

### Docker Secrets

Docker Secrets are used to provide passwords to the containers without placing them directly in Dockerfiles or environment variables.

The project uses four secret files:

- `db_root_password.txt`
- `db_password.txt`
- `wp_admin_password.txt`
- `wp_user_password.txt`

Inside the containers, these secrets are made available under `/run/secrets/`.

### Environment Variables

The `srcs/.env` file contains configuration values shared by the services, such as:

- Domain name.
- Database name.
- Database username.
- WordPress usernames and email addresses.

Passwords are handled separately through Docker Secrets.

## Sources Included

The project follows this structure:

```text
inception/
├── Makefile
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

## Main Design Choices

### Virtual Machines vs Docker

A virtual machine emulates an entire computer, including its own operating system and kernel. Each virtual machine requires its own system resources.

Docker containers share the host operating system kernel while keeping applications and their dependencies isolated.

Containers are generally lighter and faster to start than virtual machines.

In this project, Docker is used to isolate NGINX, WordPress and MariaDB into separate services.

### Secrets vs Environment Variables

Environment variables are useful for passing configuration values to containers. However, passwords stored directly as environment variables can be exposed through container inspection or process information.

Docker Secrets provide a separate mechanism for delivering sensitive information to containers as files, usually under `/run/secrets/`.

In this project, environment variables are used for general configuration, while passwords are provided through Docker Secrets.

### Docker Network vs Host Network

A bridge network provides an isolated network where containers can communicate with each other.

A host network shares the host machine's network namespace, removing much of that network isolation.

This project uses a dedicated bridge network so that the services can communicate internally without publishing every service port to the host.

### Docker Volumes vs Bind Mounts

Docker volumes are managed by Docker and are designed to persist data independently of container lifecycles.

Bind mounts directly connect a specific host filesystem path to a container path.

This project declares named Docker volumes and configures their local driver to store their data under `/home/jhenriq2/data/`, as required by the subject.

This allows the services to use named volumes while keeping persistent data in the required host directories.

## Instructions

### Requirements

- A Linux virtual machine.
- Docker Engine.
- Docker Compose.
- `make`.
- A domain configured to point to the virtual machine's local IP address.

### Configuration

1. Clone the project repository.
2. Make sure the domain in `srcs/.env` follows the required format:

```env
DOMAIN_NAME=jhenriq2.42.fr
```

3. Make sure the four Docker Secret files exist inside the root `secrets/` directory and contain their respective passwords.
4. Configure the domain in the virtual machine's `/etc/hosts` file so that it resolves to the virtual machine's local IP address.

### Building and Starting the Project

From the project root, run:

```bash
make
```

This checks the required configuration files, creates the persistent data directories and builds and starts the containers.

### Useful Commands

| Command | Description |
|---|---|
| `make` | Builds and starts the infrastructure |
| `make up` | Builds and starts the containers |
| `make down` | Stops and removes the containers |
| `make start` | Starts existing stopped containers |
| `make stop` | Stops running containers |
| `make ps` | Displays container status |
| `make logs` | Displays service logs |
| `make clean` | Removes containers and project images |
| `make fclean` | Removes containers, images, volumes and persistent data |
| `make re` | Performs a full cleanup and rebuild |

**Warning:** `make fclean` removes persistent project data, including the WordPress files and MariaDB database.

### Accessing WordPress

Once the infrastructure is running, open the following address in a browser:

```text
https://jhenriq2.42.fr
```

Because the project uses a self-signed SSL certificate, the browser may display a security warning.

## Resources

### Documentation and References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/docs/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [WP-CLI Documentation](https://developer.wordpress.org/cli/commands/)
- [PHP Documentation](https://www.php.net/docs.php)

### Use of Artificial Intelligence

Artificial intelligence tools, including ChatGPT, were used as learning and support tools throughout this project.

They were used to:

- Explain Docker, Docker Compose, containers, networks, volumes and secrets.
- Help understand the purpose and interaction of the different services.
- Clarify configuration files, Dockerfiles and initialization scripts.
- Assist with troubleshooting and understanding errors.
- Help organize and review the project documentation.

The implementation, configuration and testing of the project were carried out by the student. AI was used to support the learning process and clarify technical concepts.