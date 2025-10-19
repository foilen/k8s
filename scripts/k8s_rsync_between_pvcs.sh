#!/bin/bash

set -e

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 <SRC_NAMESPACE> <SRC_PVC_NAME> <DST_NAMESPACE> <DST_PVC_NAME>"
	exit 1
fi

SRC_NAMESPACE=$1
SRC_PVC_NAME=$2
DST_NAMESPACE=$3
DST_PVC_NAME=$4

CONFIG_MAP_NAME="k8s-pvc-authorized-keys"
SRC_POD_NAME="k8s-pvc-rsync-src-$SRC_PVC_NAME"
DST_POD_NAME="k8s-pvc-rsync-dst-$DST_PVC_NAME"

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
PRIVATE_KEY=$(cat "$SSH_PRIVATE_KEY_FILE")

# Function to create ConfigMap in a namespace
create_configmap() {
  local NAMESPACE=$1
  local INCLUDE_PRIVATE_KEY=$2

  if [ "$INCLUDE_PRIVATE_KEY" = "true" ]; then
    kubectl create configmap $CONFIG_MAP_NAME \
      --from-literal=authorized_keys="$AUTHORIZED_KEYS" \
      --from-literal=id_rsa="$PRIVATE_KEY" \
      -n $NAMESPACE 2>/dev/null || \
    kubectl create configmap $CONFIG_MAP_NAME \
      --from-literal=authorized_keys="$AUTHORIZED_KEYS" \
      --from-literal=id_rsa="$PRIVATE_KEY" \
      -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
  else
    kubectl create configmap $CONFIG_MAP_NAME \
      --from-literal=authorized_keys="$AUTHORIZED_KEYS" \
      -n $NAMESPACE 2>/dev/null || \
    kubectl create configmap $CONFIG_MAP_NAME \
      --from-literal=authorized_keys="$AUTHORIZED_KEYS" \
      -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
  fi
}

# Function to find node for a PVC
find_node_for_pvc() {
  local NAMESPACE=$1
  local PVC_NAME=$2

  # Get all pod names in the namespace
  local POD_NAMES=$(kubectl get pods -n $NAMESPACE -o jsonpath="{.items[*].metadata.name}")

  # Search a pod with the PVC mounted
  for POD in $POD_NAMES; do
    POD_YAML=$(kubectl get pod $POD -n $NAMESPACE -o yaml)
    # Check if the PVC is mounted
    if echo "$POD_YAML" | grep -q "claimName: $PVC_NAME"; then
      local NODE_NAME=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.nodeName}')
      echo "$NODE_NAME"
      return
    fi
  done

  echo ""
}

# Function to create pod for PVC
create_pod_for_pvc() {
  local NAMESPACE=$1
  local PVC_NAME=$2
  local POD_NAME=$3
  local NODE_NAME=$4

  if [ -z "$NODE_NAME" ]; then
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  namespace: $NAMESPACE
  name: $POD_NAME
spec:
  restartPolicy: Never
  containers:
  - name: ssh
    image: foilen/fdi-openssh:latest
    imagePullPolicy: IfNotPresent
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
  else
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  namespace: $NAMESPACE
  name: $POD_NAME
spec:
  restartPolicy: Never
  nodeSelector:
    kubernetes.io/hostname: $NODE_NAME
  containers:
  - name: ssh
    image: foilen/fdi-openssh:latest
    imagePullPolicy: IfNotPresent
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
  fi
}

# Function to wait for pod to be running
wait_for_pod() {
  local POD_NAME=$1
  local NAMESPACE=$2

  while [ "$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')" != "Running" ]; do
    sleep 1
  done
}

# Function to cleanup
cleanup() {
  echo "Cleaning up..."
  kubectl delete pod $SRC_POD_NAME -n $SRC_NAMESPACE 2>/dev/null || true
  kubectl delete pod $DST_POD_NAME -n $DST_NAMESPACE 2>/dev/null || true
  kubectl delete configmap $CONFIG_MAP_NAME -n $SRC_NAMESPACE 2>/dev/null || true
  if [ "$SRC_NAMESPACE" != "$DST_NAMESPACE" ]; then
    kubectl delete configmap $CONFIG_MAP_NAME -n $DST_NAMESPACE 2>/dev/null || true
  fi
  # Kill port-forward processes
  jobs -p | xargs -r kill 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Create ConfigMaps
echo "Creating ConfigMaps..."
create_configmap $SRC_NAMESPACE true  # Source needs private key for rsync
if [ "$SRC_NAMESPACE" != "$DST_NAMESPACE" ]; then
  create_configmap $DST_NAMESPACE false  # Destination only needs authorized_keys
fi

# Find nodes for PVCs
echo "Finding nodes for PVCs..."
SRC_NODE=$(find_node_for_pvc $SRC_NAMESPACE $SRC_PVC_NAME)
DST_NODE=$(find_node_for_pvc $DST_NAMESPACE $DST_PVC_NAME)

if [ -z "$SRC_NODE" ]; then
  echo "Source PVC is not currently mounted, will use any node"
else
  echo "Source PVC is mounted on node: $SRC_NODE"
fi

if [ -z "$DST_NODE" ]; then
  echo "Destination PVC is not currently mounted, will use any node"
else
  echo "Destination PVC is mounted on node: $DST_NODE"
fi

# Create pods
echo "Creating source pod..."
create_pod_for_pvc $SRC_NAMESPACE $SRC_PVC_NAME $SRC_POD_NAME "$SRC_NODE"

echo "Creating destination pod..."
create_pod_for_pvc $DST_NAMESPACE $DST_PVC_NAME $DST_POD_NAME "$DST_NODE"

# Wait for pods to be running
echo "Waiting for source pod to be running..."
wait_for_pod $SRC_POD_NAME $SRC_NAMESPACE
echo "Source pod is running"

echo "Waiting for destination pod to be running..."
wait_for_pod $DST_POD_NAME $DST_NAMESPACE
echo "Destination pod is running"

# Get the destination pod IP
echo "Getting destination pod IP..."
DST_POD_IP=$(kubectl get pod $DST_POD_NAME -n $DST_NAMESPACE -o jsonpath='{.status.podIP}')
echo "Destination pod IP: $DST_POD_IP"

# Copy private key to source pod and set permissions
echo "Setting up SSH key in source pod..."
kubectl exec -n $SRC_NAMESPACE $SRC_POD_NAME -- sh -c "cat /config/id_rsa > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa"

# Run rsync from source pod to destination pod
# Using -a (archive mode) which includes -rlptgoD:
#   -r: recursive
#   -l: copy symlinks as symlinks
#   -p: preserve permissions
#   -t: preserve modification times
#   -g: preserve group
#   -o: preserve owner
#   -D: preserve device files and special files
# Additional flags:
#   -z: compress during transfer
#   --numeric-ids: preserve numeric user/group IDs
echo "Starting rsync from source PVC to destination PVC..."
kubectl exec -n $SRC_NAMESPACE $SRC_POD_NAME -- \
  rsync --compress-level=9 -azv --numeric-ids --delete \
  -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  /data/ root@$DST_POD_IP:/data/

echo "Rsync completed successfully!"

# Cleanup will be handled by trap
