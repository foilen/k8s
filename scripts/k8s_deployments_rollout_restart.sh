#!/bin/bash

set -e

if [ "$#" -eq 2 ]; then
    NAMESPACE=$1
    NAME=$2
elif [ "$#" -eq 1 ]; then
    NAME=$1
else
    echo "Usage: $0 [NAMESPACE] NAME"
    exit 1
fi

# Find namespace if none provided
if [ -z "$NAMESPACE" ]; then
    NAMESPACE=$(kubectl get deployments --all-namespaces | grep $NAME | awk '{print $1}')
fi

# If no namespace found, exit
if [ -z "$NAMESPACE" ]; then
    echo "Namespace not found for deployment $NAME"
    exit 1
fi

kubectl rollout restart deployment -n $NAMESPACE $NAME 
kubectl rollout status deployment -n $NAMESPACE $NAME
