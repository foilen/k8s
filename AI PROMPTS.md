# Fix memory and disk limits

```
For those alerts, update the yaml files by putting new limits. Round to the 10MB. To choose the limit to put:
- for high memory usage: augment the limit
- for high disk usage: augment the limit to the closest GB
- for low memory usage: lower the limit
- for low disk usage: do nothing because that needs a migration

Alerts:

```

# Lower PVC size

```
Take the steps in `cookbook/Migrate PVC.md` and lower the size of the `XXXXX` PVC to `XX GB`.
Use the new name `XXXX` for the migrated PVC.
Execute all the steps and ask for confirmation before applying any changes to the cluster.
```
