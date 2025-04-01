#!/bin/bash

set -e

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 <NAMESPACE> <MARIADB_NAME> <DB_NAME> <SQL_FILE>"
	exit 1
fi

NAMESPACE=$1
MARIADB_NAME=$2
DB_NAME=$3
SQL_FILE=$4

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

# Load the database
echo "Load the database"
echo Processing Database $DB_NAME
docker run -i --rm mariadb mariadb -h $DOCKER_HOST_IP -P $LOCAL_PORT -u root -p$ROOT_PASSWORD $DB_NAME < $SQL_FILE

# Stop the port forward
echo "Stop the port forward"
kill $PORT_FORWARD_PID
