# Virtual Cluster Template

Copy `cluster_template/` (this folder) to a new folder to being working on a specific feature

### Requirements ###

To deploy on your own host, you need:

- Linux, (tested with Ubuntu 18.04)
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/docs/)
- Working NFS server installed ([Ubuntu](https://help.ubuntu.com/stable/serverguide/network-file-system.html)/Debian = nfs-kernel-server ; RedHat/CentOS = nfsd) to use an [NFS synced vagrant folder](https://www.vagrantup.com/docs/synced-folders/nfs.html).  Using NFS significantly outperforms standard Vagrant rsync folder share method.  If not using NFS, comment out the following line in Vagrantfile:
`  config.vm.synced_folder ".", "/vagrant", type: "nfs"`
- Sufficeint (SSD hopefully) disk storage to host the VM images and any persistent container disk images.


**Recommended**

- Install [Vagrant-hostsupdater plugin](https://github.com/cogitatio/vagrant-hostsupdater)
`$ vagrant plugin install vagrant-hostsupdater`
Else, you will need to add contents of `./config/hosts` to your own `/etc/hosts` file to allow your own host to communicate with all nodes by name (and disable hostsupdater parts of Vagrantfile).
- Modify your host's sudoers file to allow passwordless operation of Vagrant to setup an NFS share and use the persistent-storage plugin above.  Example for Ubuntu hosts:
```
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
Cmnd_Alias VAGRANT_HOSTS_ADD = /bin/sh -c 'echo "*" >> /etc/hosts'
Cmnd_Alias VAGRANT_HOSTS_REMOVE = /bin/sed -i -e /*/ d /etc/hosts
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY, VAGRANT_HOSTS_ADD, VAGRANT_HOSTS_REMOVE
```
 Else you will need to type your `sudo` password when you `vagrant up` to allow vagrant-hostsupdater to modify your `/etc/hosts` file. [  *I still need to type in sudo... why? ~EHZ* ]

### Resources ###

Ansible's docs:
> http://docs.ansible.com/ansible/latest/

Nice guide to setup/manage docker swarm with ansible:
> https://caylent.com/manage-docker-swarm-using-ansible/


### Instructions ###

Clone this repo onto your local machine, perform setup described in 'Requirements' section.

**Copy `cluster_template/` to a new folder to being working on a specific feature**

```
$ cp -r ./cluster_template/ ./osparc-ops-myfeature
$ cd osparc-ops-myfeature
```

**Clone osparc-simcore repository into a top level folder: `_source`**

- git will ignore anything in this directory

**Configure your virtual cluster**

- Edit `./cluster_settings.yaml` as desired.

**Fire up all nodes and provision them**

```
$ ./vagrant up
```

This will:

- take ~3-5 minutes per node
- instantiate the VMs
- install minimal packages to get Ansible running on node `ans`
- create an Ansible hosts file for the cluster
- setup SSH key-based login from `ans` to all other nodes in your cluster


Finally, you can start working.  As a test, try this command from the Ansible control node:
```
$ ansible all -m setup -a "filter=ansible_distribution*"
```

When finished, stop the Vagrant VMs:
```
$ vagrant halt -f
```

Destroy the VM environment:
```
$ vagrant destroy -f
```
