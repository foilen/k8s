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
