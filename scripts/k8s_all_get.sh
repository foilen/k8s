#!/bin/bash

kubectl get all -o wide --all-namespaces | tee _get_all.txt

echo | tee -a _get_all.txt
echo '== ConfigMap ==' | tee -a _get_all.txt
kubectl get configmap --all-namespaces | tee -a _get_all.txt

echo | tee -a _get_all.txt
echo '== Secrets ==' | tee -a _get_all.txt
kubectl get secret --all-namespaces | tee -a _get_all.txt

echo | tee -a _get_all.txt
echo '==Persistent Volume Claim==' | tee -a _get_all.txt
kubectl get pvc --all-namespaces | tee -a _get_all.txt

echo | tee -a _get_all.txt
echo '==Persistent Volume==' | tee -a _get_all.txt
kubectl get pv --all-namespaces | tee -a _get_all.txt
