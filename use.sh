#!/bin/bash

set -e

# Go in the directory where the script is located
RUN_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$RUN_PATH"

# Validate the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster_name>"
    echo
    ls -1 clusters
    exit 1
fi

# Go in the directory where the script is located
cd "$(dirname "$0")"

export PATH=$PATH:$(pwd)/scripts

CLUSTER_NAME=$1
echo "Using cluster $CLUSTER_NAME"

cd clusters/$CLUSTER_NAME
export KUBECONFIG=$(pwd)/kubeconfig.yaml
echo "KUBECONFIG set to $KUBECONFIG"

bash
