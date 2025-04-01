# Description

This is a service to get metrics from the cluster. It is used by the `top` command as well.

# Install

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

wget -O deployment/system/metrics-server.yaml https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

k8s_apply_and_add.sh deployment/system/metrics-server.yaml
```
