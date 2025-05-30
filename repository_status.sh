#!/bin/bash

set -e

# Go in the directory where the script is located
RUN_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$RUN_PATH"

# K8S project
git status

# All clusters
cd "$RUN_PATH/clusters"

for CLUSTER_NAME in $(ls); do
    echo
    echo "# Cluster $CLUSTER_NAME"
    cd "$RUN_PATH/clusters/$CLUSTER_NAME"
    git status
done
