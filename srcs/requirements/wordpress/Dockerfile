FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y curl php php-fpm php-mysql mariadb-client netcat-openbsd net-tools iproute2

COPY ./conf/wp_conf.sh /

RUN chmod +x wp_conf.sh

ENTRYPOINT [ "./wp_conf.sh" ]