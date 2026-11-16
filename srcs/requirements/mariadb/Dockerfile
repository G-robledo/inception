FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends mariadb-server mariadb-client \
    && rm -rf /var/lib/apt/lists/* /var/lib/mysql/* \
    && sed -i 's/bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/mariastart.sh /mariastart.sh
RUN chmod +x /mariastart.sh

EXPOSE 3306
ENTRYPOINT ["/mariastart.sh"]
