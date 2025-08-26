FROM alpine:3.21.4

RUN apk update && apk upgrade && \
	apk add --no-cache mariadb mariadb-client

COPY ./tools/mariadb_setup.sh /
COPY ./conf/db.cnf /etc/my.cnf.d/mariadb-server.cnf

RUN	mkdir -p /var/log/mysql /run/mysqld && \
	chown -R mysql:mysql /var/log/mysql /run/mysqld /var/lib/mysql && \
	chmod 755 /run/mysqld

RUN chmod +x /mariadb_setup.sh

ENTRYPOINT ["sh", "/mariadb_setup.sh"]
CMD ["/usr/bin/mariadbd"]