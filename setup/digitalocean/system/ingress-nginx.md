# Description

To use NGINX for ingress.

For DigitalOcean, it is using the specific flavor.

https://kubernetes.github.io/ingress-nginx/deploy/#digital-ocean

# Install

Check the latest version:
- Go on https://github.com/kubernetes/ingress-nginx/tags
- Check the tags that start with `controller-`

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

VERSION=1.12.2
wget -O deployment/system/ingress-nginx.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$VERSION/deploy/static/provider/do/deploy.yaml

```
Update for load-balancer: 
- Search for `service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"`
- Add a hostname for your load balancer `service.beta.kubernetes.io/do-loadbalancer-hostname: "xxxxxx.example.com"`

```
k8s_apply_and_add.sh deployment/system/ingress-nginx.yaml
```

# Update version

Just do like in the inst all section. That will update the yaml file and apply it.
