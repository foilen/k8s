#!/bin/bash

set -e

if [ "$#" -eq 1 ]; then
    TEXT=$1
else
    echo "Usage: $0 <text>"
    exit 1
fi

echo -n $TEXT | base64 -d
echo
