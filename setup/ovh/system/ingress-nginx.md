# Description

To use NGINX for ingress.

For OVH, it is using the baremetal flavor.

- https://kubernetes.github.io/ingress-nginx/deploy/#ovhcloud
- https://support.us.ovhcloud.com/hc/en-us/articles/1500004961501-Installing-Nginx-Ingress-on-OVHcloud-Managed-Kubernetes

# Install

Check the latest version:
- Go on https://github.com/kubernetes/ingress-nginx/tags
- Check the tags that start with `controller-`

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

VERSION=1.12.2
wget -O deployment/system/ingress-nginx.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$VERSION/deploy/static/provider/baremetal/deploy.yaml

k8s_apply_and_add.sh deployment/system/ingress-nginx.yaml
```

To add the load-balancer that forwards the client's IP to the NGINX controller, edit deployment/system/ingress-nginx.yaml and:
- In the `ConfigMap`, set the `data`:
```
data:
  use-proxy-protocol: "true"
  real-ip-header: "proxy_protocol"
  proxy-real-ip-cidr: "10.1.0.0/16"
```
- In the `Service` named `ingress-nginx-controller`, set the `annotations`:
```
  annotations:
    loadbalancer.openstack.org/proxy-protocol : "v2"
```
- In the `Service` named `ingress-nginx-controller`, add to the `spec`:
```
spec:
  externalTrafficPolicy: Local
```
- In the `Service` named `ingress-nginx-controller`, change the `type` from `NodePort` to `LoadBalancer`

Then execute:
```
k8s_apply_and_add.sh deployment/system/ingress-nginx.yaml
```

# Update version

Just do like in the install section. That will update the yaml file and apply it.
