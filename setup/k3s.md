# Prepare the environment on each node

Tested on Ubuntu 24.04

Install the following packages. Some details:
- `open-iscsi` is used for Longhorn (distributed storage). If you don't want to install it, then you can skip it.


```
sudo -i

apt update && \
apt dist-upgrade -y && \
apt install -y \
    curl less net-tools pv rsync vim wget \
    haveged \
    open-iscsi \
    zip unzip && \
apt autoremove -y
```

Then disable the firewall

```
ufw disable
```

Ensure your hostname is fully qualified

```
# Check (expect the full name)
hostname

# Set it if not fully qualified
hostnamectl set-hostname xxxxxxxxx
```

You can reboot if you want to ensure everything is fine

```
reboot
```

# Install with single main node

## Main node

Based on:
- https://docs.k3s.io/quick-start
- https://docs.k3s.io/installation/configuration

Set the following environment variables to tell which node is the main. You can have a different hostname than the one of the machine if you want it to be dynamic in the future. As long as it resolves to the IP of the node with the API, it is fine.

```
K3S_MAIN=xxxxxxx
```

You can also save it in `main.txt` file in your repository for future reference.

Create the config file

```
mkdir -p /etc/rancher/k3s && \
cat > /etc/rancher/k3s/config.yaml << _EOF
tls-san:
  - "$K3S_MAIN"

flannel-backend: wireguard-native

disable: traefik

embedded-registry: true
cluster-init: true
secrets-encryption: true

_EOF
```

If you want to add some labels on the node to be able to schedule pods on it, you can add the following:

```
cat >> /etc/rancher/k3s/config.yaml << _EOF
node-label:
  - "gpu=NVIDIA"
_EOF
```

If you need access to a private Docker registry, you can add the following:

```
cat > /etc/rancher/k3s/registries.yaml << _EOF
configs:
  "docker.myhost.com":
    auth:
      username: theUserName
      password: thePassword
_EOF
```

Finally, you can install the latest version of k3s:

```
curl -sfL https://get.k3s.io | sh -
```

or a specific version:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.30.3+k3s1" sh -
```

## Get the node token

If you want to add more nodes, you will need to save the token:

```
cat /var/lib/rancher/k3s/server/node-token
```

You can save it in the `node-token.txt` file in your repository.

```
K3S_MAIN=xxxxxxx
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME
scp root@$K3S_MAIN:/var/lib/rancher/k3s/server/node-token node-token.txt
```

## Install on the other nodes

Set the following environment variables to tell which node is the main and the token to use (the one in the `node-token.txt` file).

```
export K3S_MAIN=xxxxxxx
export K3S_URL=https://$K3S_MAIN:6443
export K3S_TOKEN=K104...::server:6eac592a76...6eac592a76
```

Create the config file

```
mkdir -p /etc/rancher/k3s && \
cat > /etc/rancher/k3s/config.yaml << _EOF
_EOF
```

Yes it is empty for the other nodes unless you want to add some labels on the node to be able to schedule pods on it, you can add the following:

```
cat >> /etc/rancher/k3s/config.yaml << _EOF
node-label:
  - "gpu=NVIDIA"
_EOF
```

If you need access to a private Docker registry, you can add the following:

```
cat > /etc/rancher/k3s/registries.yaml << _EOF
configs:
  "docker.myhost.com":
    auth:
      username: theUserName
      password: thePassword
_EOF
```

Finally, you can install the latest version of k3s:

```
curl -sfL https://get.k3s.io | sh -
```

or a specific version:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.30.3+k3s1" sh -
```


# Get the kubeconfig file

```
K3S_MAIN=xxxxxxx
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME
scp root@$K3S_MAIN:/etc/rancher/k3s/k3s.yaml kubeconfig.yaml
sed -i "s|https://127.0.0.1:6443|https://$K3S_MAIN:6443|g" $KUBECONFIG
```

# High Availability
TODO https://docs.k3s.io/datastore/ha-embedded
