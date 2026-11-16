FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx openssl gettext-base curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/default \
    && mkdir -p /var/www/html /data/nginx/ssl

RUN sed -E '/^[[:space:]]*fastcgi_param[[:space:]]+(HTTP_HOST|SERVER_PORT)[[:space:]]/d' \
        /etc/nginx/fastcgi_params > /etc/nginx/fastcgi_params_inception

COPY conf/default.conf /etc/nginx/templates/default.conf.template
COPY tools/nginx_start.sh /nginx_start.sh
RUN chmod +x /nginx_start.sh

EXPOSE 443
ENTRYPOINT ["/nginx_start.sh"]
