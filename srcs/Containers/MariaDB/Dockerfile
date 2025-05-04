FROM alpine:latest

RUN apk update && apk upgrade && \
	apk add --no-cache mariadb mariadb-client

COPY ./tools/db_setup.sh /
COPY ./conf/db.cnf /etc/mysql/conf.d

RUN chmod +x /db_setup.sh

ENTRYPOINT ["/db_setup.sh"]
#CMD