#!/bin/bash
set -e

# Read Docker Secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Validate required settings
if [ -z "$MYSQL_DATABASE" ] || \
   [ -z "$MYSQL_USER" ] || \
   [ -z "$DOMAIN_NAME" ] || \
   [ -z "$WP_ADMIN_USER" ] || \
   [ -z "$WP_ADMIN_EMAIL" ] || \
   [ -z "$WP_USER" ] || \
   [ -z "$WP_USER_EMAIL" ] || \
   [ -z "$MYSQL_PASSWORD" ] || \
   [ -z "$WP_ADMIN_PASSWORD" ] || \
   [ -z "$WP_USER_PASSWORD" ]; then
    echo "Error: required settings or secrets are missing."
    exit 1
fi

mkdir -p /var/www/wordpress /run/php
cd /var/www/wordpress

# Wait for MariaDB to accept authenticated connections
echo "Waiting for MariaDB..."

for i in $(seq 1 30); do
    if mysql \
        -h mariadb \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        "$MYSQL_DATABASE" \
        -e "SELECT 1" >/dev/null 2>&1; then
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "Error: MariaDB did not become ready in time."
        exit 1
    fi

    sleep 2
done

# Download WordPress and create its configuration
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root
fi

# Install WordPress only if it is not installed
if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    echo "Creating additional WordPress user..."

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root

    echo "WordPress installed successfully!"
else
    echo "WordPress is already installed."
fi

# Set WordPress file ownership
chown -R www-data:www-data /var/www/wordpress

# Start PHP-FPM in the foreground
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
