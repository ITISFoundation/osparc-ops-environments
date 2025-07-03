## topolvm components and architecture
See diagram https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/design.md

## Preqrequisites
`topolvm` does not automatically creates Volume Groups (specified in device-classes). This needs to be configured additionally (e.g. manually, via ansible, ...)

Manual example (Ubuntu 22.04):
1. Create partition to use later (`sudo fdisk /dev/sda`)
2. Create PV (`sudo pvcreate /dev/sda2`)
    * Prerequisite: `sudo apt install lvm2`
3. Create Volume group (`sudo vgcreate topovg-sdd /dev/sda2`)
    * Note: Volume group's name must correspond to the setting of `volume-group` inside `lvmd.deviceClasses`
4. Check volume group (`sudo vgdisplay`)

Source: https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/getting-started.md#prerequisites

## Deleting PV(C)s with `retain` reclaim policy
1. Delete release (e.g. helm uninstall -n test test)
2. Find LogicalVolume CR (`kubectl get logicalvolumes.topolvm.io`
3. Delete LogicalVolume CR (`kubectl delete logicalvolumes.topolvm.io <lv-name>`)
4. Delete PV (`kubectl delete PV <pv-name>`)

## Backup / Snapshotting
1. Only possible while using thin provisioning
2. We use thick (non-thin provisioned) volumes --> no snapshot support

   Track this feature request for changes https://github.com/topolvm/topolvm/issues/1070

Note: there might be alternative not documented ways (e.g. via Velero)

## Resizing PVs
1. Update storage capacity in configuration
2. Deploy changes

Note: storage size can only be increased. Otherwise, one gets `Forbidden: field can not be less than previous value` error

## Node maintenance

Read https://github.com/topolvm/topolvm/blob/topolvm-chart-v15.5.5/docs/node-maintenance.md

## Using topolvm. Notes
* `topolvm` may not work with pods that define `spec.nodeName` Use node affinity instead
  https://github.com/topolvm/topolvm/blob/main/docs/faq.md#the-pod-does-not-start-when-nodename-is-specified-in-the-pod-spec
