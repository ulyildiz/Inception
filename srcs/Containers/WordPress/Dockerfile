FROM alpine:latest

RUN		apk update && apk upgrade &&\
		apk add php82 php82-fpm php82-bcmath php82-bz2 php82-calendar php82-cli php82-ctype \
			php82-curl php82-dom php82-exif php82-fileinfo php82-gd php82-gmp \
			php82-iconv php82-imap php82-intl php82-json php82-mbstring \
			php82-mysqli php82-mysqlnd php82-openssl php82-pcntl php82-pdo php82-pdo_mysql \
			php82-pdo_pgsql php82-pdo_sqlite php82-pgsql php82-phar php82-posix php82-session \
			php82-shmop php82-simplexml php82-soap php82-sockets php82-sodium php82-sqlite3 \
			php82-sysvsem php82-sysvshm php82-tokenizer php82-xml php82-xmlreader php82-xmlwriter \
			php82-xsl php82-zip php82-zlib &&\
		apk add mariadb-client

COPY ./tools/wordpress_setup.sh /
#COPY ./conf/wp-config.php /var/www/html/wp-config.php
#COPY ./conf/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN chmod +x /wordpress_setup.sh 
	#&& chown -R www-data:www-data /var/www/wordpress \  ??
	#&& chmod -R 755 /var/www/wordpress		??
ENTRYPOINT ["sh", "/wordpress_setup.sh"]
