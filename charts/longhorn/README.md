# Longhorn (LH) Knowledge Base

### Can LH be used for critical services (e.g., Databases)?

No. We should not use it for volumes of critical services.

As of now, we should avoid using LH for critical services. Instead, we should rely on easier-to-maintain solutions (e.g., application-level replication [Postgres Operators], S3, etc.). Once we get hands-on experience, extensive monitoring and ability to scale LH, we can consider using it for critical services.

LH uses networking to keep replicas in sync, and IO-heavy workloads may easily overload it, leading to unpredictable consequences. Until we can extensively monitor LH and scale it properly on demand, it should not be used for critical or IO-heavy services.

### How does LH decide which node's disk to use as storage?

It depends on the configuration. There are three possibilities:
* https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/

When using the `Create Default Disk on Labeled Nodes` option, it relies on the `node.longhorn.io/create-default-disk` Kubernetes node label.

Source: https://longhorn.io/docs/1.8.1/nodes-and-volumes/nodes/default-disk-and-node-config/#customizing-default-disks-for-new-nodes

### Will LH pick up storage from a newly added node?

By default, LH will use storage on all nodes (including newly created ones) where it runs. If `createDefaultDiskLabeledNodes` is configured, it will depend on the label of the node.

Source:
* https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
* https://longhorn.io/docs/1.8.1/nodes-and-volumes/nodes/default-disk-and-node-config/#customizing-default-disks-for-new-nodes

### How to configure disks for LH

Manual configuration performed (to be moved to ansible)
1. Create partition on the disk
    * e.g. via using `fdisk` https://phoenixnap.com/kb/linux-create-partition
2. Format partition as XFS
    * `sudo mkfs.xfs -f /dev/sda1`
3. Mount partition `sudo mount -t xfs /dev/sda1 /longhorn`
4. Persist mount in `/etc/fstab` by adding line
    * `UUID=<partition's uuid> /longhorn xfs pquota 0 0`
    * UUID can be received from `lsblk -f`

Issue asking LH to clearly document requirements: https://github.com/longhorn/longhorn/issues/11125

### Can workloads be run on nodes where LH is not installed?

Workloads can run on nodes without LH as long as LH is not restricted to specific nodes via the `nodeSelector` or `systemManagedComponentsNodeSelector` settings. If LH is configured to run on specific nodes, workloads can only run on those nodes.

Note: There is an [ongoing bug](https://github.com/longhorn/longhorn/discussions/7312#discussioncomment-13030581) where LH will raise warnings when workloads run on nodes without LH. However, it will still function correctly.

Source: https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/

### Adding new volumes to (PVs that rely on) LH

Monitor carefully whether LH is capable of handling new volumes. Test the new volume under load (when many read/write operations occur) and ensure LH does not fail due to insufficient resource capacities (e.g., network or CPU). You can also consider LH's performance section from this Readme.

LH's minimum recommended resource requirements:
* https://longhorn.io/docs/1.8.1/best-practices/#minimum-recommended-hardware

### LH's performance / resources

Insights into LH's performance:
* https://longhorn.io/blog/performance-scalability-report-aug-2020/
* https://github.com/longhorn/longhorn/wiki/Performance-Benchmark

Resource requirements:
* https://github.com/longhorn/longhorn/issues/1691

### (Kubernetes) Node maintenance

https://longhorn.io/docs/1.8.1/maintenance/maintenance/

Note: you can use Longhorn GUI to perform some operations

### Zero downtime updating longhorn disks (procedure)
Notes:
* Update one node at a time so that other nodes can still serve data

1. Go to LH GUI and select a Node
    1. Disable scheduling
    2. Request eviction
1. Remove disk from the node
    * If remove icon is disabled, disable eviction on disk to enable the remove button
2. Perform disks updates on the node
3. Make sure LH didn't pick up wrongly configured disk in the meantime and remove the wrong disk if it did so
4. Wait till LH automatically adds the disk to the Node
