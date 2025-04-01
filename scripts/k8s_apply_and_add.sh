#!/bin/bash


set -e

# Validate the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <DEPLOY_PATH>"
    exit 1
fi

DEPLOY_PATH=$1

kubectl apply -f $DEPLOY_PATH
git add $DEPLOY_PATH
