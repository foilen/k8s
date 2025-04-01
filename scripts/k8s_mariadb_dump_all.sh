#!/bin/bash

set -e

if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <NAMESPACE> <MARIADB_NAME> <DIR_SQL>"
	exit 1
fi

NAMESPACE=$1
MARIADB_NAME=$2
DIR_SQL=$3

ROOT_PASSWORD=$(kubectl get -n $NAMESPACE secret $MARIADB_NAME-root -o jsonpath='{.data.password}' | base64 --decode)

# Forward the port
LOCAL_PORT=$((RANDOM % 10000 + 20000))
kubectl port-forward -n $NAMESPACE service/$MARIADB_NAME $LOCAL_PORT:3306 --address 0.0.0.0 &
PORT_FORWARD_PID=$!

# Wait for the port to be open
while ! nc -z 127.0.0.1 $LOCAL_PORT; do
  sleep 1
done

# Get the host ip
echo "Get the host ip"
DOCKER_HOST_IP=$(ip route | grep docker0 | awk '{print $9}')

# Get all the databases
echo "Get all the databases"
set +e
DB_NAMES=$(echo 'show databases' | docker run -i --rm mariadb mariadb -h $DOCKER_HOST_IP -P $LOCAL_PORT -u root -p$ROOT_PASSWORD | grep -v Database | grep -v information_schema | grep -v performance_schema | grep -v mariadb | grep -v mysql | grep -v sys)
set -e

# Dump all the databases
mkdir -p $DIR_SQL
echo "Databases: $DB_NAMES"
for DB_NAME in $DB_NAMES; do
  echo Processing Database $DB_NAME
  docker run -i --rm mariadb mariadb-dump -h $DOCKER_HOST_IP -P $LOCAL_PORT -u root -p$ROOT_PASSWORD $DB_NAME > $DIR_SQL/$DB_NAME.sql
done

# Stop the port forward
echo "Stop the port forward"
kill $PORT_FORWARD_PID
