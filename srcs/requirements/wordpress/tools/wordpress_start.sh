#!/bin/bash
set -euo pipefail

for variable in MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD WP_URL WP_ADMIN_USER WP_ADMIN_PASSWORD WP_ADMIN_EMAIL WP_USER WP_USER_PASSWORD WP_USER_EMAIL; do
    [ -n "${!variable:-}" ] || { echo "$variable is required." >&2; exit 1; }
done
[ "$WP_ADMIN_USER" != "$WP_USER" ] || { echo 'The administrator and subscriber must have different names.' >&2; exit 1; }
mkdir -p /run/php /var/www/html
cd /var/www/html

ready=false
for attempt in {1..60}; do
    if MYSQL_PWD="$MYSQL_PASSWORD" mariadb --protocol=TCP --host=mariadb --user="$MYSQL_USER" --database="$MYSQL_DATABASE" --execute='SELECT 1' >/dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 2
done
"$ready" || { echo 'WordPress could not connect to MariaDB.' >&2; exit 1; }

if [ ! -f .inception-core-ready ]; then
    wp core download --allow-root --force
    touch .inception-core-ready
fi

if [ ! -f wp-config.php ]; then
    wp config create --allow-root --skip-check \
        --dbname="$MYSQL_DATABASE" --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" --dbhost=mariadb:3306
fi
wp config set FORCE_SSL_ADMIN true --raw --allow-root

if ! wp core is-installed --allow-root; then
    wp core install --allow-root --url="$WP_URL" --title='Inception Project' \
        --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" --skip-email
fi

# A new hostname or published port must also update WordPress's canonical URL.
wp option update home "$WP_URL" --allow-root
wp option update siteurl "$WP_URL" --allow-root
if ! wp user get "$WP_ADMIN_USER" --allow-root >/dev/null 2>&1; then
    wp user create "$WP_ADMIN_USER" "$WP_ADMIN_EMAIL" --role=administrator \
        --user_pass="$WP_ADMIN_PASSWORD" --allow-root
fi
if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" --role=subscriber \
        --user_pass="$WP_USER_PASSWORD" --allow-root
fi

chown -R www-data:www-data /var/www/html
exec php-fpm -F
