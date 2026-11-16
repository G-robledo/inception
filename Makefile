COMPOSE ?= docker compose
PROJECT_NAME ?= inception
ENV_FILE ?= .env
WAIT_TIMEOUT ?= 180
COMPOSE_CMD = $(COMPOSE) --env-file "$(ENV_FILE)" --project-name "$(PROJECT_NAME)" -f srcs/docker-compose.yml

all: init
	@$(COMPOSE_CMD) up -d --build --wait --wait-timeout $(WAIT_TIMEOUT)
	@printf 'Inception is ready. See .env for the hostname, port and local credentials.\n'

init:
	@sh scripts/init-env.sh "$(ENV_FILE)"

config: init
	@$(COMPOSE_CMD) config --quiet

down: init
	@$(COMPOSE_CMD) down

re: all

clean: init
	@$(COMPOSE_CMD) down --rmi local --remove-orphans

fclean: init
	@$(COMPOSE_CMD) down --rmi local --volumes --remove-orphans

logs: init
	@$(COMPOSE_CMD) logs -f

ps: init
	@$(COMPOSE_CMD) ps

test:
	@sh tests/smoke.sh

.PHONY: all init config down re clean fclean logs ps test
