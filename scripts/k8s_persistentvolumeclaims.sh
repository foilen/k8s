#!/bin/bash

kubectl get persistentvolumeclaims -o wide --all-namespaces | tee _get_persistentvolumeclaims.txt
