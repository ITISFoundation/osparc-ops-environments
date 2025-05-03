# Longhorn (LH) Knowledge Base

### Can LH be used for critical services (e.g. Database)

As of now we shall avoid using LH for critical services. Instead we should refer to a more reliable and easy-to-maintain solution (e.g. Application-Level replication [Postgres Operators], S3, ...)

LH is using networking for keeping replicas in sync and IO-heavy workloads may overload it easily leading to unpredictable consequances. Before we manage to extensively monitor LH and scale properly on demand, we shall not use it for critical services or IO-heave services

### How does LH decide which node's disk to use as storage

It depends on configuration. There are 3 possibilities:
* https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/#deploy-longhorn-components-only-on-a-specific-set-of-nodes

### Will LH pick up storage from a newly-added node

By default LH will use storage on all (newly created as well) Nodes where it runs. If `createDefaultDiskLabeledNodes` is configured, then it depends on label of the node

https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/#deploy-longhorn-components-only-on-a-specific-set-of-nodes

### Can workloads be run on nodes where there is no LH

They can as long as LH is not bound to specific nodes via `nodeSelector` or `systemManagedComponentsNodeSelector` settings. If LH is configure to run on specific nodes, then workloads can only be run on these nodes only.

Source: https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/#deploy-longhorn-components-only-on-a-specific-set-of-nodes
