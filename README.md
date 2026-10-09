*This project has been created as part of the 42 curriculum by kzinchuk.*

# Inception

## Description

<!-- 2–4 речення: що це за проект і яка його мета.
Підказка: інфраструктура з трьох сервісів (NGINX, WordPress + php-fpm, MariaDB),
кожен у своєму контейнері, зібраному з власного Dockerfile на Debian bookworm,
пов'язані через docker compose. Мета — зрозуміти Docker і основи системного адміністрування. -->


## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed
- `make`
- The domain `kzinchuk.42.fr` pointing to the local machine:

```bash
echo "127.0.0.1 kzinchuk.42.fr" | sudo tee -a /etc/hosts
```

### Secrets and environment

Credentials are not stored in the repository. Before the first run, create:

- `secrets/db_password.txt` — password of the WordPress database user
- `secrets/db_root_password.txt` — password of the MariaDB root user
- `secrets/credentials.txt` — WordPress user passwords, in the format:
WP_ADMIN_PASSWORD=...
WP_USER_PASSWORD=...

- `srcs/.env` — non-secret configuration (domain, database name, user names)

<!-- Пізніше: приклад вмісту .env без реальних значень. Детальна інструкція буде в DEV_DOC.md -->

### Usage

| Command | Description |
|---|---|
| `make` | Build the images and start all containers |
| `make down` | Stop and remove the containers |
| `make stop` / `make start` | Stop / restart containers without removing them |
| `make ps` | Show the status of the containers |
| `make logs` | Follow the logs of all services |
| `make clean` | Remove containers and images |
| `make fclean` | Remove containers, images, volumes and all data |
| `make re` | Full rebuild from scratch |

The website is then available at `https://kzinchuk.42.fr`.

## Project description

### Use of Docker and sources

<!-- Своїми словами: як влаштований проект.
- три сервіси і що кожен робить (ланцюжок браузер → NGINX → php-fpm → MariaDB)
- структура папок: srcs/requirements/<service>/{Dockerfile, conf, tools}
- що робить init.sh кожного сервісу (перший запуск vs наступні)
- два томи і де фізично лежать дані -->

### Main design choices

<!-- Твої рішення і чому. Підказки:
- Debian bookworm, а не Alpine — чому
- ENTRYPOINT у exec-формі + exec у скрипті → сервіс є PID 1
- MariaDB: bootstrap-режим для створення бази при першому запуску
- WordPress: встановлення через WP-CLI, а не браузер
- php-fpm слухає порт 9000, а не сокет-файл — чому
- ідемпотентні скрипти з if -->

### Virtual Machines vs Docker

<!-- Ключова різниця: VM має своє ядро, контейнер — ні.
Згадай експеримент з uname -r всередині контейнера.
Наслідки: розмір, швидкість запуску, рівень ізоляції. -->

### Secrets vs Environment Variables

<!-- Згадай схему: .env → змінні, secrets → файли в /run/secrets/.
Чому паролі не в змінних (docker inspect, видно всім процесам),
і чому не в Dockerfile (вшилися б в образ). -->

### Docker Network vs Host Network

<!-- Що дає своя мережа inception: контейнери знаходять один одного за іменем
(mariadb, wordpress), а назовні відкрито лише порт 443 nginx.
Що було б з network: host — і чому сабджект це забороняє. -->

### Docker Volumes vs Bind Mounts

<!-- Згадай "двері" і флешку: дані переживають видалення контейнера.
Різниця: іменований том — окремий об'єкт Docker (видно в docker volume ls),
bind mount — пряме підключення шляху з хоста.
Чому сабджект вимагає саме іменовані томи, і як ми поєднали це з /home/kzinchuk/data. -->

## Resources

<!-- Документація, яка реально допомогла. Наприклад:
- Docker documentation (Dockerfile reference, Compose file reference)
- MariaDB Knowledge Base
- WP-CLI documentation
- NGINX documentation
- туторіали, якими користувалась -->

### Use of AI

<!-- Сабджект вимагає чесно описати, для чого використовувався AI і в яких частинах.
Наприклад: пояснення концепцій Docker, покроковий супровід налаштування VM,
допомога з дебагом помилок, перевірка конфігурацій; і що всі файли були
розібрані, протестовані й зрозумілі тобою. Опиши так, як було насправді. -->