#!/bin/bash

kubectl get nodes -o wide | tee _get_nodes.txt
