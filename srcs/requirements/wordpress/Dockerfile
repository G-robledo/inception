FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-cli \
        mariadb-client curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && php_version="$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')" \
    && sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' "/etc/php/$php_version/fpm/pool.d/www.conf" \
    && ln -s "/usr/sbin/php-fpm$php_version" /usr/local/bin/php-fpm

RUN curl --fail --silent --show-error --location \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        --output /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html
COPY tools/wordpress_start.sh /wordpress_start.sh
RUN chmod +x /wordpress_start.sh

EXPOSE 9000
ENTRYPOINT ["/wordpress_start.sh"]
