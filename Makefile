COMPOSE = docker compose -f srcs/docker-compose.yml
DATA    = /home/tiade-al/data
SECRETS = secrets/db_root_password.txt secrets/db_password.txt \
          secrets/wp_admin_password.txt secrets/wp_user_password.txt

all: up

check:
	@test -f srcs/.env || (echo "Missing srcs/.env (copy srcs/.env.example)"; exit 1)
	@for f in $(SECRETS); do \
		test -s $$f || (echo "Missing or empty $$f"; exit 1) || exit 1; \
	done

up: check
	mkdir -p $(DATA)/wordpress $(DATA)/mariadb
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --rmi all

fclean:
	$(COMPOSE) down -v --rmi all
	sudo rm -rf $(DATA)

re: fclean all

.PHONY: all check up down start stop ps logs clean fclean re