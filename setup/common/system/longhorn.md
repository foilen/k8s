# Description

When you have at least 3 nodes, you can use Longhorn to create a distributed storage system.

It works on any Kubernetes provider which is great to have a consistent storage system.

Limitations:
- It can attach the volume to one node at a time.

# Install

Check the latest version:
- Go on https://github.com/longhorn/longhorn/tags
- Check the latest tags without "rc" or "dev" in them

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

VERSION=1.8.1
wget -O deployment/system/longhorn.yaml https://raw.githubusercontent.com/longhorn/longhorn/v$VERSION/deploy/longhorn.yaml

k8s_apply_and_add.sh deployment/system/longhorn.yaml
```

# To view the Longhorn UI

```
kubectl port-forward -n longhorn-system svc/longhorn-frontend 11111:80
```

Then open your browser at http://localhost:11111

# Update version

Just do like in the install section. That will update the yaml file and apply it.

# Uninstall

Before uninstalling Longhorn, you must ensure all volumes are properly migrated or deleted.

## Step 1: Delete all PVCs and workloads using Longhorn volumes

```bash
# List all PVCs using Longhorn storage class
kubectl get pvc --all-namespaces -o json | jq -r '.items[] | select(.spec.storageClassName=="longhorn") | "\(.metadata.namespace)/\(.metadata.name)"'

# Delete workloads using these PVCs (deployments, statefulsets, etc.)
# Then delete the PVCs themselves
kubectl delete pvc <pvc-name> -n <namespace>
```

## Step 2: Clean up Longhorn volumes via UI or CLI

Option A - Via Longhorn UI:
```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 11111:80
```
Then go to http://localhost:11111 and delete all volumes manually.

Option B - Via kubectl:
```bash
# Delete all Longhorn volumes
kubectl -n longhorn-system delete volumes.longhorn.io --all

# Wait for all volumes to be deleted
kubectl -n longhorn-system get volumes.longhorn.io
```

## Step 3: Enable deletion confirmation flag

Before running the uninstall job, you must enable the deletion confirmation flag:

```bash
kubectl -n longhorn-system patch settings.longhorn.io deleting-confirmation-flag -p '{"value":"true"}' --type=merge
```

## Step 4: Create and run uninstall job

Longhorn requires a cleanup job to remove components properly:

```bash
VERSION=1.8.1
kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v$VERSION/uninstall/uninstall.yaml

# Wait for the job to complete
kubectl -n longhorn-system wait --for=condition=complete --timeout=300s job/longhorn-uninstall

# If the job fails, check the logs:
kubectl -n longhorn-system logs job/longhorn-uninstall
```

## Step 5: Remove Longhorn deployment and namespace

```bash
# Delete the Longhorn deployment
kubectl delete -f deployment/system/longhorn.yaml

# Wait for namespace to be deleted (may take 10-30 seconds)
sleep 10
kubectl get namespace longhorn-system

# If namespace is stuck in Terminating state after waiting, you may need to manually clean it:
kubectl get namespace longhorn-system -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/longhorn-system/finalize" -f -
```

## Step 6: Clean up remaining resources

Remove any leftover Longhorn resources:

```bash
# Remove any remaining StorageClasses
kubectl delete storageclass longhorn-static 2>/dev/null || true

# Clean up uninstall job RBAC resources
kubectl delete clusterrole longhorn-uninstall-role 2>/dev/null || true
kubectl delete clusterrolebinding longhorn-uninstall-bind 2>/dev/null || true
kubectl delete serviceaccount -n longhorn-system longhorn-uninstall-service-account 2>/dev/null || true
```

## Step 7: Clean up node storage (optional)

If you want to completely remove Longhorn data from nodes:

```bash
# SSH into each node and run:
sudo rm -rf /var/lib/longhorn/
```

## Verify uninstall

Verify that all Longhorn resources have been removed:

```bash
echo "=== Checking for remaining Longhorn resources ==="
echo
echo "Namespaces:"
kubectl get namespace | grep longhorn || echo "  ✓ No Longhorn namespaces"
echo
echo "CRDs:"
kubectl get crd | grep longhorn || echo "  ✓ No Longhorn CRDs"
echo
echo "StorageClasses:"
kubectl get storageclass | grep longhorn || echo "  ✓ No Longhorn StorageClasses"
echo
echo "ClusterRoles:"
kubectl get clusterrole | grep longhorn || echo "  ✓ No Longhorn ClusterRoles"
echo
echo "ClusterRoleBindings:"
kubectl get clusterrolebinding | grep longhorn || echo "  ✓ No Longhorn ClusterRoleBindings"
```
