# Description

MariaDB is a relational database.

Documentation: https://github.com/mariadb-operator/mariadb-operator

# Install

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

helm repo add mariadb-operator https://helm.mariadb.com/mariadb-operator
helm install mariadb-operator-crds mariadb-operator/mariadb-operator-crds
helm install mariadb-operator mariadb-operator/mariadb-operator

```

# Uninstall

**Important**: Delete all MariaDB custom resources BEFORE uninstalling the operator to ensure proper cleanup.

```
# 1. List and delete all MariaDB instances
kubectl get mariadb --all-namespaces
kubectl delete mariadb <name> -n <namespace>

# 2. Uninstall the operator
helm uninstall mariadb-operator

# 3. Uninstall the CRDs
helm uninstall mariadb-operator-crds

# 4. (Optional) Remove any remaining CRDs manually
kubectl get crd | grep mariadb
kubectl delete crd <crd-name>

# 5. (Optional) Clean up remaining resources
kubectl get pvc --all-namespaces | grep mariadb
kubectl get secrets --all-namespaces | grep mariadb
```
