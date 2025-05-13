#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <NAMESPACE> <PVC_NAME>"
	exit 1
fi

NAMESPACE=$1
PVC_NAME=$2

POD_NAME="k8s-pvc-shell-$PVC_NAME"

# Get all pod names in the namespace
POD_NAMES=$(kubectl get pods -n $NAMESPACE -o jsonpath="{.items[*].metadata.name}")

# Search a pod with the PVC mounted
for POD in $POD_NAMES; do
  POD_YAML=$(kubectl get pod $POD -n $NAMESPACE -o yaml)
  # Check if the PVC is mounted
  if echo "$POD_YAML" | grep -q "claimName: $PVC_NAME"; then
    NODE_NAME=$(echo "$POD_YAML" | kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
    break
  fi
done

if [ -z "$NODE_NAME" ]; then
  echo "No pod found with the PVC mounted. Will use any node"
else
  echo "The PVC is mounted on node: $NODE_NAME"
fi

# Create a pod
echo "Creating a pod..."
if [ -z "$NODE_NAME" ]; then
  kubectl apply -f - <<EOF
# Pod
apiVersion: v1
kind: Pod
metadata:
  namespace: $NAMESPACE
  name: $POD_NAME
spec:
  containers:
    - name: ubuntu
      image: ubuntu:24.04
      command: ["sleep", "3600"]
      volumeMounts:
      - name: data
        mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF
else
  kubectl apply -f - <<EOF
# Pod
apiVersion: v1
kind: Pod
metadata:
  namespace: $NAMESPACE
  name: $POD_NAME
spec:
  nodeSelector:
    kubernetes.io/hostname: $NODE_NAME
  containers:
    - name: ubuntu
      image: ubuntu:24.04
      command: ["sleep", "3600"]
      volumeMounts:
      - name: data
        mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF
fi

# Wait for the pod to be running
echo "Waiting for the pod to be running..."
kubectl wait --for=condition=Ready pod/$POD_NAME -n $NAMESPACE

# Install some tools
echo "Installing some tools..."
kubectl exec -it -n $NAMESPACE $POD_NAME -- /bin/bash -c 'export TERM=dumb ; export DEBIAN_FRONTEND=noninteractive ; apt-get update && apt-get install -y curl netcat-traditional net-tools vim'

# Go into it
echo; echo
echo "Going into the shell for $(basename "$PWD")"
kubectl exec -it -n $NAMESPACE $POD_NAME -- /bin/bash
