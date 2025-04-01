#!/bin/bash

if [ $# -eq 1 ]; then
    SECONDS=$1
else
    SECONDS=2
fi

watch -n $SECONDS k8s_top.sh
