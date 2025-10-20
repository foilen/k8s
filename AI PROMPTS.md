# Fix memory and disk limits

```
For those alerts, update the yaml files by putting new limits. Round to the 10MB. To choose the limit to put:
- for high memory usage: augment the limit
- for high disk usage: augment the limit to the closest GB
- for low memory usage: lower the limit
- for low disk usage: do nothing because that needs a migration

Alerts:

```