#!/bin/bash

FLAG_FILE="/var/lib/mysql/.setup_done"

# Check if setup has already been done
if [ -f "$FLAG_FILE" ]; then
    echo "MariaDB setup already completed. Skipping setup."
    mysqld_safe --port=3306 --bind=0.0.0.0 --datadir='/var/lib/mysql'
    exec mysqld_safe
fi

START_TIME=$(date +%s)
TIMEOUT=120 # max amount of seconds for mariadb to start

#--------------mariadb start--------------#
if ! pgrep -x "mariadbd" > /dev/null; then
    echo "Starting MariaDB..."
    service mariadb start
fi

check_mariadb() {
    mysqladmin ping -h 127.0.0.1 --silent
}

while true; do
    sleep 5
    if check_mariadb; then
        echo "Mariadb service has started."
        break
    fi

    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if ((ELAPSED_TIME >= TIMEOUT)); then
        echo "Mariadb failed to start withing 120 seconds"
        exit 1
    fi
done

echo "Starting MariaDB in skip-grant-tables mode..."
mysqld_safe --skip-grant-tables --bind-address=0.0.0.0 &
sleep 5

# Wait for MariaDB to be ready
until mysqladmin ping --silent; do
    echo "Waiting for MariaDB (skip-grant-tables mode) to be ready..."
    sleep 2
done

mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

if [ $? -ne 0 ]; then
    echo "Failed to set root password. Exiting."
    exit 1
fi

echo "Root password set successfully."


#--------------mariadb config--------------#
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

if [ $? -ne 0 ]; then
    echo "Failed to configure database and user. Exiting."
    exit 1
fi

echo "Database and user setup completed."

touch "$FLAG_FILE"

#--------------mariadb restart--------------#
#Shutdown mariadb to restart with new config
mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown || { echo "Failed to shutdown MariaDB"; exit 1; }

#Restart mariadb with new config in the background to keep the container running
mysqld_safe --port=3306 --bind=0.0.0.0 --datadir='/var/lib/mysql'

# "Waiting for MariaDB to restart"
echo "Waiting for MariaDB to restart..."
until check_mariadb; do
    sleep 5
done

echo "MariaDB restarted with new configuration."

exec mysqld_safe