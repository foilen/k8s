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

# To add the load-balancer
cat > deployment/system/ingress-loadbalancer.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.12.2
  name: ingress-nginx-controller-loadbalancer
  namespace: ingress-nginx
spec:
  ipFamilies:
    - IPv4
  ipFamilyPolicy: SingleStack
  ports:
    - appProtocol: http
      name: http
      port: 80
      protocol: TCP
      targetPort: http
    - appProtocol: https
      name: https
      port: 443
      protocol: TCP
      targetPort: https
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  type: LoadBalancer
EOF
k8s_apply_and_add.sh deployment/system/ingress-loadbalancer.yaml
```

# Update version

Just do like in the install section. That will update the yaml file and apply it.
