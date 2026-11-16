#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d)
env_file=$test_dir/.env
project_name=inception-smoke-$$
port=${TEST_HTTPS_PORT:-18443}
# Keep caller settings from taking precedence over this isolated test's env file.
unset DOMAIN_NAME HTTPS_PORT MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD MYSQL_ROOT_PASSWORD
unset WP_ADMIN_USER WP_ADMIN_PASSWORD WP_ADMIN_EMAIL WP_USER WP_USER_PASSWORD WP_USER_EMAIL

dc() {
    docker compose --env-file "$env_file" --project-name "$project_name" \
        -f "$repo_root/srcs/docker-compose.yml" "$@"
}
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ "$status" -ne 0 ]; then dc logs --no-color --tail 60 >&2 || true; fi
    dc down --volumes --rmi local --remove-orphans >/dev/null 2>&1 || true
    rm -rf "$test_dir"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

DOMAIN_NAME=127.0.0.1 HTTPS_PORT="$port" sh "$repo_root/scripts/init-env.sh" "$env_file"
dc config --quiet
dc up --build --wait --wait-timeout 180

check_site() {
    expected=$1
    curl --ipv4 --fail --silent --show-error --insecure --location --max-time 20 "$expected/" > "$test_dir/home.html"
    grep -q 'Inception Project' "$test_dir/home.html"
    actual=$(dc exec -T wordpress wp option get siteurl --allow-root)
    [ "$actual" = "$expected" ] || { echo 'Incorrect WordPress URL.' >&2; exit 1; }
}
check_data() {
    [ "$(dc exec -T wordpress wp option get inception_smoke_marker --allow-root)" = retained ]
    [ "$(dc exec -T wordpress cat /var/www/html/.inception-smoke-sentinel)" = retained ]
}

check_site "https://127.0.0.1:$port"
dc exec -T wordpress wp option update inception_smoke_marker retained --allow-root
dc exec -T wordpress sh -c 'printf retained > /var/www/html/.inception-smoke-sentinel'
echo 'PASS: first startup, HTTPS and WordPress installation'

dc restart
dc up --wait --wait-timeout 180
check_site "https://127.0.0.1:$port"
check_data
echo 'PASS: restart preserves database and files'

dc down
dc up --wait --wait-timeout 180
check_data
echo 'PASS: container recreation preserves database and files'

sed 's/^DOMAIN_NAME=.*/DOMAIN_NAME=localhost/' "$env_file" > "$test_dir/changed.env"
mv "$test_dir/changed.env" "$env_file"
dc up --wait --wait-timeout 180
check_site "https://localhost:$port"
dc exec -T nginx openssl x509 -in /data/nginx/ssl/server.crt -noout -checkhost localhost
check_data
echo 'PASS: hostname change updates WordPress URL and certificate'

make -C "$repo_root" clean "ENV_FILE=$env_file" "PROJECT_NAME=$project_name"
docker volume inspect "${project_name}_mariadb_data" "${project_name}_wordpress_data" >/dev/null
dc up --build --wait --wait-timeout 180
check_site "https://localhost:$port"
check_data
echo 'PASS: make clean preserves stored data'

make -C "$repo_root" fclean "ENV_FILE=$env_file" "PROJECT_NAME=$project_name"
if docker volume inspect "${project_name}_mariadb_data" >/dev/null 2>&1 \
    || docker volume inspect "${project_name}_wordpress_data" >/dev/null 2>&1 \
    || docker volume inspect "${project_name}_ssl_data" >/dev/null 2>&1; then
    echo 'fclean left a project data volume behind.' >&2
    exit 1
fi
echo 'PASS: make fclean removes the project data volumes'
