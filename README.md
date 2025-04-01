# Description

This project is meant to help managing a single or multiple Kubernetes clusters. It also contains the instructions to create a new cluster and some cookbook recipes for common pattern.

You can use the script to quickly switch from one cluster to another and do some common operations.

The suggested setup enables us to use the same templates to easily move from one cluster to another.

# Setup

Create a new cluster repository:

```
CLUSTER_NAME=my-cluster

./repository_create.sh $CLUSTER_NAME
```

Then follow the step specific to the provider you are using to retrieve the kubeconfig file and put it in `kubeconfig.yaml`.
You can then decide if you want to persist that file in the repository or not by updating `.gitignore` to include that file if you want each user to get it themselves.

For the secrets, you can decide if you want to put them in the repository or not by updating `.gitignore` to include the `secrets` directory if you want each user to get them themselves.

# Use

To switch to a cluster, run:

```
./use.sh $CLUSTER_NAME
```

That will set the `KUBECONFIG` environment variable to the right value, go in the directory of the repository and add the common scripts to the path.

You can then `exit` to go back to your previous environment.
