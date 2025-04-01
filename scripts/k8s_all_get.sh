#!/bin/bash

kubectl get all -o wide --all-namespaces | tee _get_all.txt
