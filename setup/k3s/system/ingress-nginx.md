# Description

To use NGINX for ingress.

For k3s, it is using the default flavor.

# Install

Check the latest version:
- Go on https://github.com/kubernetes/ingress-nginx/tags
- Check the tags that start with `controller-`

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

VERSION=1.12.1
wget -O deployment/system/ingress-nginx.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$VERSION/deploy/static/provider/cloud/deploy.yaml

k8s_apply_and_add.sh deployment/system/ingress-nginx.yaml
```

# Update version

Just do like in the install section. That will update the yaml file and apply it.
