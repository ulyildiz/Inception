FROM alpine:latest

RUN apk update && apk upgrade && \
	apk add --no-cache nginx openssl \
	&& mkdir -p /run/nginx

COPY ./tools/nginx_setup.sh /
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

RUN chmod +x /nginx_setup.sh

ENTRYPOINT ["/nginx_setup.sh"]
#CMD