#!/bin/bash

kubectl get pods -o wide --all-namespaces | tee _get_pods.txt
