# Description

The cert manager is used to get certificates from Let's Encrypt.

Some documentation:
- https://cert-manager.io/docs/tutorials/acme/dns-validation/
- https://cert-manager.io/docs/tutorials/acme/http-validation/

# Install

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

wget -O deployment/system/cert-manager.yaml https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml

k8s_apply_and_add.sh deployment/system/cert-manager.yaml
```

# TODO Setup DNS

cert-manager_lets-encrypt-do-dns.yaml