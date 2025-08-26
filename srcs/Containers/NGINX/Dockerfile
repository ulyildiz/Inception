FROM	alpine:3.21.4

RUN		apk update && apk upgrade && \
		apk add --no-cache nginx && \
		apk add --no-cache openssl && \
		apk add --no-cache gettext

RUN		mkdir -p /www && \
		mkdir -p /var/www/html && \
		mkdir -p /etc/nginx/ssl
		
COPY	./tools/nginx_setup.sh /
COPY	./conf/default.conf.template /etc/nginx/http.d/default.conf.template

RUN 	chmod +x /nginx_setup.sh

ENTRYPOINT ["sh", "/nginx_setup.sh"]
CMD ["nginx", "-g", "daemon off;"]