# Exaplaining misc. questions regarding Longhorn (LH)

### How does LH decide which node's disk to use as storage

There are 3 ways https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
* storag tag feature https://longhorn.io/docs/1.8.1/nodes-and-volumes/nodes/storage-tags/
* node selectors that will restrict LH to certain nodes only (and disks on these nodes)
* using https://longhorn.io/docs/archives/1.2.2/references/settings/#create-default-disk-on-labeled-nodes

### Will LH pick up disks from a newly-added node

Use 2 articles below to get detailed information
* https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
* https://longhorn.io/docs/1.8.1/nodes-and-volumes/nodes/default-disk-and-node-config/
