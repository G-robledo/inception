#!/bin/bash
set -euo pipefail

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
for identifier in "$MYSQL_DATABASE" "$MYSQL_USER"; do
    [[ "$identifier" =~ ^[A-Za-z0-9_]+$ ]] || {
        echo 'Database and user names must contain only letters, digits or underscores.' >&2
        exit 1
    }
done

DB_DIR=/var/lib/mysql
SOCKET=/run/mysqld/mysqld.sock
mkdir -p "$DB_DIR" /run/mysqld
chown -R mysql:mysql "$DB_DIR" /run/mysqld

if [ ! -d "$DB_DIR/mysql" ]; then
    mariadb-install-db --user=mysql --datadir="$DB_DIR" --skip-test-db
fi

if [ ! -f "$DB_DIR/.inception-initialized" ]; then
    mariadbd --user=mysql --datadir="$DB_DIR" --skip-networking --socket="$SOCKET" &
    temporary_pid=$!
    stop_temporary() {
        if kill -0 "$temporary_pid" 2>/dev/null; then
            MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mariadb-admin --protocol=socket --socket="$SOCKET" --user=root shutdown >/dev/null 2>&1 \
                || kill "$temporary_pid" 2>/dev/null || true
        fi
        wait "$temporary_pid" 2>/dev/null || true
    }
    trap stop_temporary EXIT
    trap 'exit 143' TERM
    trap 'exit 130' INT

    # Root initially uses socket authentication; the password path also recovers
    # an interrupted bootstrap that already set the root password.
    ready=false
    for attempt in {1..60}; do
        if mariadb --protocol=socket --socket="$SOCKET" --user=root --execute='SELECT 1' >/dev/null 2>&1; then
            root_password=''
            ready=true
            break
        elif MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mariadb --protocol=socket --socket="$SOCKET" --user=root --execute='SELECT 1' >/dev/null 2>&1; then
            root_password=$MYSQL_ROOT_PASSWORD
            ready=true
            break
        fi
        kill -0 "$temporary_pid" 2>/dev/null || { echo 'MariaDB bootstrap exited.' >&2; exit 1; }
        sleep 1
    done
    "$ready" || { echo 'MariaDB bootstrap timed out.' >&2; exit 1; }

    # SQL literals use doubled quotes with backslash escaping disabled.
    app_password=${MYSQL_PASSWORD//\'/\'\'}
    admin_password=${MYSQL_ROOT_PASSWORD//\'/\'\'}
    MYSQL_PWD="$root_password" mariadb --protocol=socket --socket="$SOCKET" --user=root <<SQL
SET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES';
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$app_password';
ALTER USER '$MYSQL_USER'@'%' IDENTIFIED BY '$app_password';
GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$admin_password';
FLUSH PRIVILEGES;
SQL
    stop_temporary
    trap - EXIT TERM INT
    touch "$DB_DIR/.inception-initialized"
fi

exec mariadbd --user=mysql --datadir="$DB_DIR" --socket="$SOCKET"
