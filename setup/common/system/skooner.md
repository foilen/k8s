# Description

Skooner is a Kubernetes dashboard that helps you understand & manage your cluster.

# Install

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

wget -O deployment/system/kubernetes-skooner.yaml https://raw.githubusercontent.com/skooner-k8s/skooner/master/kubernetes-skooner.yaml

k8s_apply_and_add.sh deployment/system/kubernetes-skooner.yaml

# TODO Ingress
```

# Usage

```
# Create the token
kubectl create token skooner-sa
```