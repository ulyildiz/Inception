FROM alpine:latest

RUN apk update && apk upgrade && \
	apk add --no-cache nginx && \
	apk add --no-cache openssl

RUN adduser -D -g 'www' www && \
	mkdir /www && \
	chown -R www:www /var/lib/nginx && \
	chown -R www:www /www 

RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig


COPY ./tools/nginx_setup.sh /
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

RUN chmod +x /nginx_setup.sh

ENTRYPOINT ["sh", "/nginx_setup.sh"]
CMD ["nginx", "-g", "daemon off;"]