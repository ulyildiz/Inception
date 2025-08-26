# Variables
SRCS_FILE = ./srcs
LOGIN = ulyildiz
DATA_FILE = ${HOME}/${LOGIN}/data
COMPOSE_FILE = $(SRCS_FILE)/docker-compose.yml
COMPOSE_CMD = docker-compose -f $(COMPOSE_FILE)

# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
NC = \033[0m

all: up

# Create data directories
$(DATA_FILE):
	@echo "$(YELLOW)Creating data directories...$(NC)"
	@mkdir -p $(DATA_FILE)/mariadb
	@mkdir -p $(DATA_FILE)/wordpress

# Build and start containers
up: $(DATA_FILE)
	@echo "$(GREEN)Starting Docker Inception...$(NC)"
	@$(COMPOSE_CMD) up -d --build

# Down containers
down:
	@echo "$(YELLOW)Stopping Docker Inception...$(NC)"
	@$(COMPOSE_CMD) down

# Stop containers
stop:
	@echo "$(YELLOW)Stopping containers...$(NC)"
	@$(COMPOSE_CMD) stop

# Show container status
status:
	@echo "$(GREEN)Container status:$(NC)"
	@$(COMPOSE_CMD) ps

# Show logs
logs:
	@$(COMPOSE_CMD) logs -f

# Clean non-persistent data
clean: stop
	@echo "$(RED)Cleaning up...$(NC)"
	@docker system prune -f

# Full cleanup
fclean:
	@echo "$(RED)Performing full cleanup...$(NC)"
	@$(COMPOSE_CMD) down --remove-orphans --volumes --rmi all
	@sudo rm -rf $(DATA_FILE)
	@docker system prune -a --volumes -f
	@docker network prune -f

# Restart everything
re: fclean all

# Enter a container shell
shell-mariadb:
	@docker exec -it mariadb /bin/sh

shell-wordpress:
	@docker exec -it wordpress /bin/sh

shell-nginx:
	@docker exec -it nginx /bin/sh

# Development helpers
dev-logs-mariadb:
	@$(COMPOSE_CMD) logs -f mariadb

dev-logs-wordpress:
	@$(COMPOSE_CMD) logs -f wordpress

dev-logs-nginx:
	@$(COMPOSE_CMD) logs -f nginx

.PHONY: all up down stop status logs clean fclean re shell-mariadb shell-wordpress shell-nginx dev-logs-mariadb dev-logs-wordpress dev-logs-nginx