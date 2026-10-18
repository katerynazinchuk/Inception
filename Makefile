COMPOSE  = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/kzinchuk/data
ENV_FILE = srcs/.env
SECRETS  = secrets/db_password.txt secrets/db_root_password.txt secrets/credentials.txt

all: up

up: $(ENV_FILE) $(SECRETS)
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up --build -d

$(ENV_FILE):
	cp srcs/.env.example $@

secrets/db_password.txt secrets/db_root_password.txt:
	mkdir -p secrets
	openssl rand -hex 12 > $@

secrets/credentials.txt:
	mkdir -p secrets
	echo "WP_ADMIN_PASSWORD=$$(openssl rand -hex 12)" > $@
	echo "WP_USER_PASSWORD=$$(openssl rand -hex 12)" >> $@

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --rmi all

fclean:
	$(COMPOSE) down --rmi all -v
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all up down stop start ps logs clean fclean re