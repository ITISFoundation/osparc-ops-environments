## How to delete volumes with `recalimPolicy: retain`
1. Delete pvc:
```
kubectl delete pvc <pvc-name>
```

2. Verify PV is `released`
```
kubectl get pv <pv-name>
```

3. Manually remove EBS in AWS
    1. Go to AWS GUI and List EBS Volumes
    1. Filter by tag `ebs.csi.aws.com/cluster=true`
    1. Identify the volume associated with your PV (check `kubernetes.io/created-for/pv/name` tag of the EBS Volume)
    1. Verify that EBS Volume is `Available`
    1. Delete EBS Volume

4. Delete the PV
```
kubectl delete pv <pv-name>
```

5. Remove Finalizers (if necessary)
If the PV remains in a Terminating state, remove its finalizers:
```
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'
```
