#!/bin/bash

kubectl get services -o wide --all-namespaces | tee _get_services.txt
