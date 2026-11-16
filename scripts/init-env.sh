#!/bin/sh
set -eu
umask 077

env_file=${1:-.env}
if [ -f "$env_file" ]; then
    printf 'Using existing configuration: %s\n' "$env_file"
    exit 0
fi

domain=${DOMAIN_NAME:-localhost}
port=${HTTPS_PORT:-8443}
case "$domain" in
    ''|*[!A-Za-z0-9.-]*)
        echo 'DOMAIN_NAME must be an IPv4 address or DNS hostname (without scheme, port or path).' >&2
        exit 1 ;;
esac
case "$port" in
    ''|*[!0-9]*) echo 'HTTPS_PORT must be a number between 1 and 65535.' >&2; exit 1 ;;
esac
if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo 'HTTPS_PORT must be between 1 and 65535.' >&2
    exit 1
fi

random_password() {
    password=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
    [ ${#password} -eq 48 ] || exit 1
    printf '%s' "$password"
}

temporary=$(mktemp "${env_file}.tmp.XXXXXX")
trap 'rm -f "$temporary"' EXIT HUP INT TERM
cat > "$temporary" <<EOF
DOMAIN_NAME=$domain
HTTPS_PORT=$port
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_ROOT_PASSWORD=$(random_password)
MYSQL_PASSWORD=$(random_password)
WP_ADMIN_USER=siteowner
WP_ADMIN_PASSWORD=$(random_password)
WP_ADMIN_EMAIL=admin@example.test
WP_USER=reader
WP_USER_PASSWORD=$(random_password)
WP_USER_EMAIL=reader@example.test
EOF
# Link atomically without replacing a configuration another invocation created.
if ln "$temporary" "$env_file" 2>/dev/null; then
    printf 'Created %s for https://%s:%s (local passwords generated).\n' "$env_file" "$domain" "$port"
elif [ ! -f "$env_file" ]; then
    echo "Could not create $env_file" >&2
    exit 1
fi
