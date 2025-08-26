FROM alpine:3.21.4

RUN	apk update && apk upgrade &&\
	apk add php82 php82-fpm php82-cli php82-phar\
		php82-mysqli php82-mbstring php82-iconv \
		php82-sockets &&\
	apk add mariadb-client

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp-cli.phar 
RUN ln -sf /usr/bin/php82 /usr/bin/php

RUN mkdir -p /var/www/html && \
    chmod -R 777 /var/www/html

COPY ./tools/wordpress_setup.sh /
COPY ./conf/www.conf /etc/php82/php-fpm.d/www.conf
COPY ./conf/php.ini /etc/php82/conf.d/custom.ini

RUN chmod +x /wordpress_setup.sh 

WORKDIR /var/www/html

ENTRYPOINT ["sh", "/wordpress_setup.sh"]
CMD ["php-fpm82", "-F", "-R"]