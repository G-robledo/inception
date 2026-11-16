COMPOSE ?= docker compose
COMPOSE_FILE := srcs/docker-compose.yml

all:
	@$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

down:
	@$(COMPOSE) -f $(COMPOSE_FILE) down

re:
	@$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

clean:
	@$(COMPOSE) -f $(COMPOSE_FILE) down --rmi local --volumes --remove-orphans

.PHONY: all re down clean
