# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a multi-cluster Kubernetes management repository. It provides a unified structure for managing multiple K8s clusters (home, DigitalOcean, OVH) with scripts for common operations and standardized deployment patterns.

## Core Architecture

### Repository Structure

```
clusters/
  <cluster-name>/
    kubeconfig.yaml          # Cluster connection credentials
    node-token.txt           # K3s node join token (for K3s clusters)
    deployment/
      system/                # Infrastructure: ingress, cert-manager, longhorn
      permanent/             # Long-running applications
      temporary/             # Short-lived deployments
      jobs/                  # One-time job definitions
    secrets/                 # Kubernetes secrets (may be gitignored per cluster)
setup/
  k3s.md                     # K3s cluster creation
  digitalocean.md            # DigitalOcean cluster setup
  ovh.md                     # OVH cluster setup
  common/system/             # Common system component guides
scripts/                     # Helper scripts (added to PATH by use.sh)
```

### Cluster Switching Mechanism

The `use.sh` script is the primary entry point:
- Sets `KUBECONFIG` environment variable to cluster-specific config
- Adds `scripts/` directory to PATH
- Spawns a new shell in the cluster directory
- Exit the shell to return to the original environment

### Deployment Categories

1. **System**: Core infrastructure (ingress-nginx, cert-manager, longhorn, metrics-server, skooner)
2. **Permanent**: Long-running applications (databases, web apps, services)
3. **Temporary**: Short-lived deployments for testing or debugging
4. **Jobs**: One-time Kubernetes jobs

## Common Commands

### Cluster Operations

Switch to a cluster:
```bash
./use.sh <cluster-name>
```

Create new cluster repository:
```bash
./repository_create.sh <cluster-name>
```

### Deployment Management

Apply and stage a deployment:
```bash
k8s_apply_and_add.sh deployment/permanent/myapp.yaml
```

Get all resources:
```bash
k8s_all_get.sh  # Outputs to _get_all.txt
```

Restart deployments:
```bash
k8s_deployments_rollout_restart.sh <namespace> <deployment-name>
```

### Database Operations

Dump all databases from MariaDB:
```bash
k8s_mariadb_dump_all.sh <namespace> <mariadb-name> <output-dir>
```

Dump one database:
```bash
k8s_mariadb_dump_one.sh <namespace> <mariadb-name> <database-name> <output-file>
```

Load databases:
```bash
k8s_mariadb_load_all.sh <namespace> <mariadb-name> <sql-dir>
k8s_mariadb_load_one.sh <namespace> <mariadb-name> <sql-file>
```

### Debug Utilities

Create temporary shell pod:
```bash
k8s_shell.sh  # Creates ubuntu pod in temp-shell namespace
```

Create shell with PVC access:
```bash
k8s_shell_with_pvc.sh <namespace> <pvc-name>
```

Resource monitoring:
```bash
k8s_top.sh              # One-time snapshot
k8s_top_continuous.sh   # Continuous monitoring
```

Get specific resources:
```bash
k8s_pods_get.sh
k8s_deployments_get.sh
k8s_services_get.sh
k8s_ingress_get.sh
k8s_secrets_get.sh
k8s_namespaces_get.sh
k8s_nodes_get.sh
k8s_nodes_describe.sh
k8s_persistentvolumes_get.sh
k8s_persistentvolumeclaims.sh
```

### Utility Scripts

Generate password:
```bash
tools_gen_pass.sh
```

Base64 encoding/decoding:
```bash
tools_base64_encode.sh <string>
tools_base64_decode.sh <encoded-string>
```

## Infrastructure Components

### MariaDB Operator
- Installed via Helm: `mariadb-operator/mariadb-operator`
- CRD-based database management
- Auto-generates root and user passwords
- Uses Longhorn for persistent storage

### MongoDB Operator
- Installed via Helm: `mongodb/mongodb-kubernetes`
- Community operator from MongoDB

### Cert-Manager
- Downloaded from GitHub releases
- Supports both DNS-01 (DigitalOcean) and HTTP-01 validation
- ClusterIssuer: `letsencrypt-digitalocean-dns-issuer`

### Longhorn
- Distributed storage for clusters with 3+ nodes
- Requires `open-iscsi` on each node
- Single-node attachment limitation

### Ingress
- K3s: Uses ingress-nginx (Traefik disabled)
- DigitalOcean: Uses ingress-nginx
- OVH: Uses ingress-nginx

## Deployment Patterns

### Database Deployment Pattern
```yaml
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  namespace: <namespace>
  name: <name>
spec:
  rootPasswordSecretKeyRef:
    generate: true
  storage:
    storageClassName: longhorn
```

### Application with Secrets Pattern
Secrets stored in `secrets/<namespace>_<secret-name>.yaml`

### Port Forwarding Pattern
Many scripts use random high ports (20000-30000) to avoid conflicts

## K3s Specific Details

- **Networking**: Uses `wireguard-native` for flannel backend
- **Disabled Components**: Traefik (uses ingress-nginx instead)
- **Features**: Embedded registry, cluster-init, secrets-encryption
- **Main Node**: Defined by `K3S_MAIN` environment variable
- **Node Token**: Stored in `/var/lib/rancher/k3s/server/node-token`
- **Kubeconfig**: Retrieved from `/etc/rancher/k3s/k3s.yaml`

## Important Notes

- All scripts assume they're run from within a cluster context (after `use.sh`)
- Files prefixed with `_` are gitignored (temporary outputs)
- The `k8s_apply_and_add.sh` script both applies and stages changes for git
- Database dump scripts use Docker to run MariaDB client tools
- Secrets may or may not be in git depending on cluster `.gitignore` configuration
