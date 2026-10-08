FROM debian::bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        php-fpm php-mysql curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html /run/php

COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init.sh"]