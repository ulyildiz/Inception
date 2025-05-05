FROM alpine:latest

RUN apk update && apk upgrade && \
	apk add --no-cache mariadb mariadb-client

COPY ./tools/mariadb_setup.sh /
COPY ./conf/db.cnf /etc/my.cnf.d/mariadb-server.cnf

RUN chmod +x /mariadb_setup.sh

ENTRYPOINT ["sh", "/mariadb_setup.sh"]
CMD ["mariadbd"]