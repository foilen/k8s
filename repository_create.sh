#!/bin/bash

set -e

# Validate the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster_name>"
    exit 1
fi

# Go in the directory where the script is located
RUN_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$RUN_PATH"

CLUSTER_NAME=$1
echo "Creating cluster $CLUSTER_NAME"

mkdir -p clusters/$CLUSTER_NAME
cd clusters/$CLUSTER_NAME
git init

# Create the .gitignore file
cat > .gitignore << EOF
_*
EOF

# Create base folders
mkdir -p \
    deployment/jobs \
    deployment/permanent \
    deployment/temporary \
    deployment/system \
    secrets

# Touch a placeholder file in each folder
touch \
    deployment/jobs/.gitkeep \
    deployment/permanent/.gitkeep \
    deployment/temporary/.gitkeep \
    deployment/system/.gitkeep \
    secrets/.gitkeep

git add .
git commit -m "Initial commit"
