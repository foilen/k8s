# Description

MongoDB is a NoSQL database.

Here is the operator's documentation: https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/README.md .

# Install

```
CLUSTER_NAME=my-cluster

./use.sh $CLUSTER_NAME

helm repo add mongodb https://mongodb.github.io/helm-charts
helm install community-operator mongodb/community-operator
```
