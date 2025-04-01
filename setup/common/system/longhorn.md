# Description

When you have at least 3 nodes, you can use Longhorn to create a distributed storage system.

It works on any Kubernetes provider which is great to have a consistent storage system.

Limitations:
- It can attach the volume to one node at a time.

# Install

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

wget -O deployment/system/longhorn.yaml https://raw.githubusercontent.com/longhorn/longhorn/v1.7.1/deploy/longhorn.yaml

k8s_apply_and_add.sh deployment/system/longhorn.yaml
```

# To view the Longhorn UI

```
kubectl port-forward -n longhorn-system svc/longhorn-frontend 11111:80
```

Then open your browser at http://localhost:11111

# TODO Update version
