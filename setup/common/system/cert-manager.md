# Description

The cert manager is used to get certificates from Let's Encrypt.

Some documentation:
- https://cert-manager.io/docs/tutorials/acme/dns-validation/
- https://cert-manager.io/docs/tutorials/acme/http-validation/

# Install

Check the latest version:
- Go on https://github.com/cert-manager/cert-manager/tags
- Check the latest tags

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

VERSION=v1.19.1
wget -O deployment/system/cert-manager.yaml https://github.com/cert-manager/cert-manager/releases/download/$VERSION/cert-manager.yaml

k8s_apply_and_add.sh deployment/system/cert-manager.yaml
```

# Setup for DNS via Digital Ocean

```
cat > deployment/system/cert-letsencrypt.yaml <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-digitalocean-dns-issuer
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: admin@foilen.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-digitalocean-dns-issuer
    solvers:
    # An empty 'selector' means that this solver matches all domains
    - selector: {}
      dns01:
        digitalocean:
          tokenSecretRef:
            name: lets-encrypt-do-dns
            key: access-token
EOF

cat > secrets/cert-manager_lets-encrypt-do-dns.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager

---
apiVersion: v1
kind: Secret
metadata:
  name: lets-encrypt-do-dns
  namespace: cert-manager
stringData:
  access-token: xxxxxxxxxxxx
EOF

k8s_apply_and_add.sh deployment/system/cert-letsencrypt.yaml
k8s_apply_and_add.sh secrets/cert-manager_lets-encrypt-do-dns.yaml
```

Then, on any `Ingress`, you can add the annotation:

```
cert-manager.io/cluster-issuer: letsencrypt-digitalocean-dns-issuer
```

# Update version

Just do like in the install section. That will update the yaml file and apply it.
