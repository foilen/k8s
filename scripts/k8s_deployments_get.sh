#!/bin/bash

kubectl get deployments -o wide --all-namespaces | tee _get_deployments.txt
