WP_DATA = /home/USER/data/wordpress #define the path to the wordpress data
DB_DATA = /home/USER/data/mariadb #define the path to the mariadb data
ENV_BACKUP_LOCATION = /home/USER/Documents/secrets/.env # define the path to the back-up file location for .env
ENV_LOCATION = ./srcs/.env # define the path to the .env file location

# default target
all: up

# start the biulding process
# create the wordpress and mariadb data directories.
# start the containers in the background and leaves them running
up: build
	
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	@chmod 777 $(WP_DATA)
	@chmod 777 $(DB_DATA)
	docker-compose -f ./srcs/docker-compose.yml up -d

# stop the containers and removes them and the network
down:
	docker-compose -f ./srcs/docker-compose.yml down

# stop the containers
stop:
	docker-compose -f ./srcs/docker-compose.yml stop

# start the containers
start:
	docker-compose -f ./srcs/docker-compose.yml start

# build the containers
build:
	@if set -x; [ ! -f $(ENV_LOCATION)] ; then \
		echo "Copying backup .env file to $(ENV_LOCATION)"; \
		cp -f $(ENV_BACKUP_LOCATION) $(ENV_LOCATION) || echo "Failed to copy .env file"; \
	fi;
	docker-compose -f ./srcs/docker-compose.yml build

# clean the containers
# stop all running containers and remove them.
# remove all images, volumes and networks.
# remove the wordpress and mariadb data directories.
# the (|| true) is used to ignore the error if there are no containers running to prevent the make command from stopping.
clean:
	@docker stop $$(docker ps -qa) || true
	@docker rm $$(docker ps -qa) || true
	@docker rmi -f $$(docker images -qa) || true
	@docker volume rm $$(docker volume ls -q) || true
	@docker network rm $$(docker network ls -q) || true
	@rm -rf $(WP_DATA) || true
	@rm -rf $(DB_DATA) || true

# clean and start the containers
re: clean up

# prune the containers: execute the clean target and remove all containers, images, volumes and networks from the system.
prune: clean
	@docker system prune -a --volumes -f

.PHONY: all up down stop start build clean re prune