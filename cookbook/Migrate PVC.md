# Migrate PVC

## Description

This procedure allows you to migrate data from one PersistentVolumeClaim (PVC) to another. Common use cases include:

- **Switching storage classes**: Moving from local storage to Longhorn, or vice versa
- **Reducing PVC size**: Kubernetes doesn't support shrinking PVCs, so you must create a smaller one and migrate
- **Changing PVC configuration**: Modifying access modes, volume modes, or other PVC specifications
- **Consolidating or splitting data**: Reorganizing storage allocation across applications

## Steps

### 1. Create the New PVC

Create a new PVC definition with your desired specifications in the same namespace as the existing PVC. For example, create a file `deployment/permanent/my-app-pvc-new.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data-new
  namespace: my-namespace
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn  # or your desired storage class
  resources:
    requests:
      storage: 5Gi  # your desired size
```

Apply the new PVC:

```bash
kubectl apply -f deployment/permanent/my-app-pvc-new.yaml
```

Verify the PVC is bound:

```bash
kubectl get pvc -n my-namespace
```

### 2. (Optional) Perform Initial Sync While Application is Running

For large datasets, you can perform an initial sync while the application is still running to copy the bulk of the data. This minimizes downtime by reducing the final sync to only the changed files.

```bash
k8s_rsync_between_pvcs.sh my-namespace my-app-data my-namespace my-app-data-new
```

**Note**: This step is optional but recommended for:
- Large datasets (multi-GB)
- Applications where minimizing downtime is critical
- Situations where you want to verify the sync works before stopping the application

The initial sync will copy most of the data while the application continues running. Later, after stopping the application, you'll run the sync again to capture any changes made during this time.

### 3. Stop Applications Using the Current PVC

Scale down all deployments/statefulsets that are currently using the old PVC:

```bash
kubectl scale deployment/my-app -n my-namespace --replicas=0
```

Or for StatefulSets:

```bash
kubectl scale statefulset/my-app -n my-namespace --replicas=0
```

Verify all pods are terminated:

```bash
kubectl get pods -n my-namespace
```

**Important**: Ensure no pods are accessing the PVC before proceeding to avoid data corruption.

### 4. Perform Final Sync Between PVCs

Use the `k8s_rsync_between_pvcs.sh` script to transfer the final data changes:

```bash
k8s_rsync_between_pvcs.sh <src-namespace> <src-pvc-name> <dst-namespace> <dst-pvc-name>
```

Example (same namespace):

```bash
k8s_rsync_between_pvcs.sh my-namespace my-app-data my-namespace my-app-data-new
```

Example (different namespaces):

```bash
k8s_rsync_between_pvcs.sh old-namespace my-app-data new-namespace my-app-data
```

The script will:
- Create temporary SSH-enabled pods with the PVCs mounted
- Use rsync over SSH to copy all data from source to destination
- Preserve permissions, timestamps, ownership, and special files
- Clean up the temporary pods and ConfigMaps when complete

Monitor the output to ensure the transfer completes successfully.

**Note**: If you performed the optional initial sync in step 2, this final sync will be much faster as rsync will only transfer the files that changed while the application was running. The `--delete` flag ensures files deleted from the source are also removed from the destination.

### 5. Update Application to Use New PVC

Edit your deployment/statefulset to reference the new PVC:

```yaml
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-app-data-new  # changed from my-app-data
```

Apply the changes:

```bash
kubectl apply -f deployment/permanent/my-app.yaml
```

Or use the helper script:

```bash
k8s_apply_and_add.sh deployment/permanent/my-app.yaml
```

### 6. Start the Application

Scale the application back up:

```bash
kubectl scale deployment/my-app -n my-namespace --replicas=1
```

Or for StatefulSets:

```bash
kubectl scale statefulset/my-app -n my-namespace --replicas=1
```

Verify the application starts correctly and can access its data:

```bash
kubectl get pods -n my-namespace
kubectl logs -n my-namespace <pod-name>
```

Test the application to ensure all data is accessible and the application functions correctly.

### 7. Verify Data and Delete Old PVC

Once you've confirmed the application is working correctly with the new PVC:

1. **Verify data integrity**: Check that all expected data is present
2. **Test application functionality**: Ensure the application operates normally
3. **Wait a reasonable period**: Keep the old PVC for a day or two as a backup

After verification, delete the old PVC:

```bash
kubectl delete pvc my-app-data -n my-namespace
```

**Warning**: This action is irreversible. Ensure you have verified the new PVC contains all necessary data before deleting the old one.

## Notes

- The rsync process preserves file permissions, ownership, and timestamps
- For large datasets, the sync operation may take significant time
- Consider backing up critical data before migration using database dump scripts or other backup methods
- If the destination PVC is smaller than the source, ensure you have enough space or the rsync will fail
