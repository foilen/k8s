#!/bin/bash

set -e

if [ "$#" -eq 1 ]; then
    AMOUNT=$1
else
    AMOUNT=20
fi

openssl rand -hex $AMOUNT
