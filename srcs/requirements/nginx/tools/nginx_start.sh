#!/bin/sh
set -eu

: "${DOMAIN_NAME:=localhost}"
: "${HTTPS_PORT:=8443}"
case "$DOMAIN_NAME" in
    ''|*[!A-Za-z0-9.-]*) echo 'DOMAIN_NAME must be an IPv4 address or DNS hostname.' >&2; exit 1 ;;
esac
SSL_DIR=/data/nginx/ssl
mkdir -p "$SSL_DIR"

if [ ! -s "$SSL_DIR/server.crt" ] || [ ! -s "$SSL_DIR/server.key" ] \
    || [ "$(cat "$SSL_DIR/.domain" 2>/dev/null || true)" != "$DOMAIN_NAME" ] \
    || ! openssl x509 -in "$SSL_DIR/server.crt" -noout -checkend 86400 >/dev/null 2>&1; then
    case "$DOMAIN_NAME" in
        *[!0-9.]*|'') alternative="DNS:$DOMAIN_NAME" ;;
        *) alternative="IP:$DOMAIN_NAME" ;;
    esac
    openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
        -keyout "$SSL_DIR/server.key" -out "$SSL_DIR/server.crt" \
        -subj "/CN=$DOMAIN_NAME" -addext "subjectAltName=$alternative"
    chmod 600 "$SSL_DIR/server.key"
    printf '%s\n' "$DOMAIN_NAME" > "$SSL_DIR/.domain"
fi

envsubst '${DOMAIN_NAME} ${HTTPS_PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
nginx -t
exec nginx -g 'daemon off;'
