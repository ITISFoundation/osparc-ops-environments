# Longhorn (LH) Knowledge Base

### Can LH be used for critical services (e.g. Database)

As of now we shall avoid using LH for critical services. Instead we should refer to a more reliable and easy-to-maintain solution (e.g. Application-Level replication [Postgres Operators], S3, ...)

LH is using networking for keeping replicas in sync and IO-heavy workloads may overload it easily leading to unpredictable consequances. Before we manage to extensively monitor LH and scale properly on demand, we shall not use it for critical services or IO-heave services

### How does LH decide which node's disk to use as storage

It depends on configuration. There are 3 possibilities:
* https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/

As long as we use `Create Default Disk on Labeled Nodes` it relies on `node.longhorn.io/create-default-disk` kubernetes node's label

Source: https://longhorn.io/docs/1.8.1/nodes-and-volumes/nodes/default-disk-and-node-config/#customizing-default-disks-for-new-nodes

### Will LH pick up storage from a newly-added node

By default LH will use storage on all (newly created as well) Nodes where it runs. If `createDefaultDiskLabeledNodes` is configured, then it depends on label of the node

Source:
* https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
* https://longhorn.io/docs/1.8.1/nodes-and-volumes/nodes/default-disk-and-node-config/#customizing-default-disks-for-new-nodes

### Can workloads be run on nodes where there is no LH

They can as long as LH is not bound to specific nodes via `nodeSelector` or `systemManagedComponentsNodeSelector` settings. If LH is configure to run on specific nodes, then workloads can only be run on these nodes only.

Source: https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
