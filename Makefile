SRCS_FILE = ./srcs 

all: up

up:
	@docker-compose -f $(SRCS_FILE)/docker-compose.yml up -d --build

down:
	@docker-compose -f $(SRCS_FILE)/docker-compose.yml down

clean:

fclean: clean

re:

.PHONY: all up down clean fclean re