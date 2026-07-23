## TopoLVM
Topolvm is a storage [CSI](https://github.com/container-storage-interface/spec/blob/v1.12.0/spec.md) used on Kubernetes cluster to manage PV/PVC via [Volume Groups](https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)).

## TopoLVM components and architecture
See diagram https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/design.md

## Preqrequisites
`topolvm` does not automatically creates Volume Groups (specified in device-classes).
This needs to be configured separately. Use ansible playbooks to configure volume groups

Source: https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/getting-started.md#prerequisites

## Deleting PV(C)s with `retain` reclaim policy
1. Delete release (e.g. helm uninstall -n test test)
2. Find LogicalVolume CR (`kubectl get logicalvolumes.topolvm.io`)
3. Delete LogicalVolume CR (`kubectl delete logicalvolumes.topolvm.io <lv-name>`)
4. Delete PV (`kubectl delete PV <pv-name>`)
5. Remove PV's finalizers (`kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'`)

Useful source: https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/advanced-setup.md#storageclass

## Backup / Snapshotting
We can try using velero. See https://velero.io/docs/main/file-system-backup/

## Resizing PVs
1. Update storage capacity in configuration
2. Deploy changes

Note: storage size can only be increased. Otherwise, one gets `Forbidden: field can not be less than previous value` error

## Node maintenance

Read https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/node-maintenance.md

## Uninstalling
Read https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/uninstall.md

## Using topolvm. Notes
* `topolvm` may not work with pods that define `spec.nodeName` Use node affinity instead
  https://github.com/topolvm/topolvm/blob/main/docs/faq.md#the-pod-does-not-start-when-nodename-is-specified-in-the-pod-spec
