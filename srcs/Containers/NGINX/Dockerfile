FROM	alpine:latest

RUN		apk update && apk upgrade && \
		apk add --no-cache nginx && \
		apk add --no-cache openssl && \
		apk add --no-cache gettext

RUN		adduser -D -g 'www' www && \
		mkdir -p /www && \
		mkdir -p /var/www/html && \
		mkdir -p /etc/nginx/ssl && \
		chown -R www:www /var/lib/nginx && \
		chown -R www:www /www && \
		chown -R www:www /var/www/html

RUN		mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

COPY	./tools/nginx_setup.sh /
COPY	./conf/nginx.conf /etc/nginx/nginx.conf
COPY	./conf/default.conf.template /etc/nginx/http.d/default.conf.template

RUN 	chmod +x /nginx_setup.sh

EXPOSE	443

ENTRYPOINT ["sh", "/nginx_setup.sh"]
CMD ["nginx", "-g", "daemon off;"]