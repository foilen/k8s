#!/bin/bash

set -e

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 <NAMESPACE> <PVC_NAME> <SRC_PATH> <DST_PATH>"
	exit 1
fi

NAMESPACE=$1
PVC_NAME=$2
SRC_PATH=$3
DST_PATH=$4

CONFIG_MAP_NAME="k8s-pvc-authorized-keys"
POD_NAME="k8s-pvc-rsync-$PVC_NAME"

# Check if the ssh keys exist
HOME_DIR=$(eval echo ~$USER)
SSH_PRIVATE_KEY_FILE="$HOME_DIR/.ssh/id_rsa"
SSH_PUBLIC_KEY_FILE="$HOME_DIR/.ssh/id_rsa.pub"
if [ ! -f "$SSH_PRIVATE_KEY_FILE" ]; then
  echo "SSH private key file does not exist: $SSH_PRIVATE_KEY_FILE. Run \"ssh-keygen -t rsa -b 2048\""
  exit 1
fi
if [ ! -f "$SSH_PUBLIC_KEY_FILE" ]; then
  echo "SSH public key file does not exist: $SSH_PUBLIC_KEY_FILE. Run \"ssh-keygen -t rsa -b 2048\""
  exit 1
fi

# Get the content of ~/.ssh/id_rsa.pub as a string
AUTHORIZED_KEYS=$(cat "$SSH_PUBLIC_KEY_FILE")

# Create the ConfigMap object
kubectl create configmap $CONFIG_MAP_NAME --from-literal=authorized_keys="$AUTHORIZED_KEYS" -n $NAMESPACE || \
kubectl create configmap $CONFIG_MAP_NAME --from-literal=authorized_keys="$AUTHORIZED_KEYS" -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

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

# Create the Pod object
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  namespace: $NAMESPACE
  name: $POD_NAME
spec:
  restartPolicy: Always
  nodeSelector:
    kubernetes.io/hostname: $NODE_NAME
  containers:
  - name: ssh
    image: foilen/fdi-openssh:latest
    imagePullPolicy: Always
    ports:
    - containerPort: 22
      name: ssh
    volumeMounts:
    - name: ssh
      mountPath: /config
    - name: data
      mountPath: /data
  volumes:
  - name: ssh
    configMap:
      name: $CONFIG_MAP_NAME
  - name: data
    persistentVolumeClaim:
      claimName: $PVC_NAME
EOF

# Wait for the pod to be running
while [ "$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')" != "Running" ]; do
  sleep 1
done

echo "Pod: $NAMESPACE $POD_NAME is running"

# Forward the port
LOCAL_PORT=$((RANDOM % 10000 + 20000))
kubectl port-forward pod/$POD_NAME $LOCAL_PORT:22 -n $NAMESPACE &

# Wait for the port to be open
while ! nc -z 127.0.0.1 $LOCAL_PORT; do
  sleep 1
done

# Fix the PVC paths
if [[ "$SRC_PATH" == :* ]]; then
  SRC_PATH="127.0.0.1:/data${SRC_PATH:1}"
fi
if [[ "$DST_PATH" == :* ]]; then
  DST_PATH="127.0.0.1:/data${DST_PATH:1}"
fi

# Run the rsync
rsync --compress-level=9 --delete -zrtve "ssh -o StrictHostKeyChecking=no -p $LOCAL_PORT -l root" "$SRC_PATH" "$DST_PATH"

# Delete the pod
kubectl delete pod $POD_NAME -n $NAMESPACE &

# Delete the ConfigMap
kubectl delete configmap $CONFIG_MAP_NAME -n $NAMESPACE
