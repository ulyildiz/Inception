FROM alpine:latest

RUN apk update && apk upgrade \
	&& apk add --no-cache php8-fpm php8-mysqli php8-gd php8-curl php8-mbstring \
	php8-xml php8-session php8-json php8-openssl php8-zip \
	php8-pdo_mysql php8-tokenizer php8-dom \
	&& mkdir -p /run/php

COPY ./tools/wp_setup.sh /
COPY ./conf/wp-config.php /var/www/wordpress/

RUN chmod +x /wp_setup.sh 
	#&& chown -R www-data:www-data /var/www/wordpress \  ??
	#&& chmod -R 755 /var/www/wordpress		??
ENTRYPOINT ["/wp_setup.sh"]
#CMD