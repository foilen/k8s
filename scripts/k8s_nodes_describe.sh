#!/bin/bash

for NODE_NAME in $(kubectl get nodes | grep -v NAME | awk '{print $1}'); do
    echo $NODE_NAME
    kubectl describe node $NODE_NAME > _node_$NODE_NAME.txt
done
