## How to delete volumes with `recalimPolicy: retain`
Delete pvc (happens automatically when deleting PVC's namespace)
```
kubectl delete pvc <pvc-name>
```

Verify PV is `released`
```
kubectl get pv <pv-name>
```

Manually remove EBS in AWS
1. Go to AWS GUI and List EBS Volumes
1. Filter by tag `ebs.csi.aws.com/cluster=true`
1. Identify the volume associated with your PV (check `kubernetes.io/created-for/pv/name` tag of the EBS Volume)
1. Verify that EBS Volume is `Available`
1. Delete EBS Volume

Delete the PV
```
kubectl delete pv <pv-name>
```

Remove Finalizers (if necessary)
If the PV remains in a Terminating state, remove its finalizers:
```
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'
```

## How to resize volume

Change `requests.storage` value and deploy.

Warning: only increasing volume size is supported
