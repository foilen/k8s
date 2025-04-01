#!/bin/bash

kubectl get persistentvolumes -o wide --all-namespaces | tee _get_persistentvolumes.txt
