#!/bin/bash

kubectl get secrets -o wide --all-namespaces | tee _get_secrets.txt
