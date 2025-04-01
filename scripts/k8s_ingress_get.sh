#!/bin/bash

kubectl get ingress -o wide --all-namespaces | tee _get_ingress.txt
