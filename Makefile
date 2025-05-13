SRCS_FILE = ./srcs 
VOLUME_FILE = /var/lib/docker/volumes
DATA_FILE = ${HOME}/data

all: up

up:
	@docker-compose -f $(SRCS_FILE)/docker-compose.yml up -d --build

down:
	@docker-compose -f $(SRCS_FILE)/docker-compose.yml down

clean:
	sudo rm -rf ${DATA_FILE}

fclean: clean
	docker system prune -a --volumes -f
	@docker volume rm srcs_mariadb srcs_wordpress

re: fclean all

.PHONY: all up down clean fclean re