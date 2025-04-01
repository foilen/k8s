#!/bin/bash

set -e

# Create a namespace and a pod
echo "Creating a namespace and a pod..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: temp-shell

---

# Pod
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleep
  namespace: temp-shell
spec:
  containers:
    - name: ubuntu
      image: ubuntu:24.04
      command: ["sleep", "3600"]
EOF

# Wait for the pod to be running
echo "Waiting for the pod to be running..."
kubectl wait --for=condition=Ready pod/ubuntu-sleep -n temp-shell

# Install some tools
echo "Installing some tools..."
kubectl exec -it -n temp-shell ubuntu-sleep -- /bin/bash -c 'export TERM=dumb ; export DEBIAN_FRONTEND=noninteractive ; apt-get update && apt-get install -y curl netcat-traditional net-tools vim'

# Go into it
echo; echo
echo "Going into the shell for $(basename "$PWD")"
kubectl exec -it -n temp-shell ubuntu-sleep -- /bin/bash
