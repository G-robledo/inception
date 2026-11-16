COMPOSE ?= docker compose
COMPOSE_FILE := srcs/docker-compose.yml
DATA_DIR ?= $(CURDIR)/data
export DATA_DIR

all:
	@mkdir -p "$(DATA_DIR)/mariadb" "$(DATA_DIR)/wordpress" "$(DATA_DIR)/nginx/ssl"
	@$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

down:
	@$(COMPOSE) -f $(COMPOSE_FILE) down

re:
	@$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

clean:
	@$(COMPOSE) -f $(COMPOSE_FILE) down --rmi local --volumes --remove-orphans

.PHONY: all re down clean
