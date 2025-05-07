FROM alpine:latest

RUN apk update && apk add --no-cache \
    bash \
    curl \
    mariadb-client \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    freetype-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd zip pdo pdo_mysql \
    && rm -rf /var/cache/apk/*

COPY ./tools/wordpress_setup.sh /
#COPY ./conf/wp-config.php /var/www/html/wp-config.php
#COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN chmod +x /wordpress_setup.sh 
	#&& chown -R www-data:www-data /var/www/wordpress \  ??
	#&& chmod -R 755 /var/www/wordpress		??
ENTRYPOINT ["sh", "/wordpress_setup.sh"]
