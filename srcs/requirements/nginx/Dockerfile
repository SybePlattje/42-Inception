FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y nginx openssl

RUN apt-get install -y netcat-openbsd

#making ssl sertivicate
RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout \
	 /etc/nginx/ssl/inception.key -subj "/C=MO/ST=KH/L=KH/O=42/OU=42/CN=${DOMAIN_NAME}/UID=${WP_ADMIN_N}"

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

# nginx needs permitions for the html folder
RUN mkdir -p /var/www/html

RUN chown -R www-data:www-data /var/www/html && find /var/www/html -type d -exec chmod 755 {} \; && find /var/www/html -type f -exec chmod 644 {} \;

CMD [ "nginx", "-g", "daemon off;" ]