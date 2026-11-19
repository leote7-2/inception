#!/bin/bash
set -e

# Read Docker secrets
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Validate required settings
if [ -z "$MYSQL_DATABASE" ] || \
   [ -z "$MYSQL_USER" ] || \
   [ -z "$MYSQL_ROOT_PASSWORD" ] || \
   [ -z "$MYSQL_PASSWORD" ]; then
    echo "Error: required database settings are missing."
    exit 1
fi

# Prepare MariaDB directories
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Initialize system tables if needed
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MariaDB..."
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-test-db
fi

# Configure the database on first initialization
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Starting temporary MariaDB server..."

    mysqld \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-networking \
        --socket=/run/mysqld/mysqld.sock \
        --pid-file=/run/mysqld/mysqld-temp.pid &

    TEMP_PID=$!

    # Wait for the temporary server
    for i in $(seq 1 30); do
        if mariadb-admin \
            --socket=/run/mysqld/mysqld.sock \
            ping --silent >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    if ! mariadb-admin \
        --socket=/run/mysqld/mysqld.sock \
        ping --silent >/dev/null 2>&1; then
        echo "Error: temporary MariaDB server failed to start."
        kill "$TEMP_PID" 2>/dev/null || true
        exit 1
    fi

    echo "Configuring database and users..."

    mariadb \
        --protocol=socket \
        --socket=/run/mysqld/mysqld.sock \
        -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Stop the temporary server
    mariadb-admin \
        --socket=/run/mysqld/mysqld.sock \
        -uroot \
        -p"${MYSQL_ROOT_PASSWORD}" \
        shutdown

    echo "Database configured successfully."
else
    echo "Database directory exists; skipping initial configuration."
fi

# Start MariaDB normally
echo "Starting MariaDB..."
exec mysqld --user=mysql --console

