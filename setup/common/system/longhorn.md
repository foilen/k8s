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
