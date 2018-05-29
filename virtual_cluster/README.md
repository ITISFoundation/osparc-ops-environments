# oSparc Simcore Operations Development - Virtual Cluster

**Virtual Cluster for osparce platform operations development**

- Quickly provision a cluster of VMs using Vagrant & VirtualBox
- Setup one node as an ansible control host, with passwordless SSH access to all other nodes
- Cluster defined in files: 
  - `cluster_settings.yml`
  - `cluster_secrets.yml`

### Requirements ###

To deploy on your own host, you need:

- Linux, here we assume Ubuntu 18.04
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/docs/)
- Working NFS server installed ([Ubuntu](https://help.ubuntu.com/stable/serverguide/network-file-system.html)/Debian = nfs-kernel-server ; RedHat/CentOS = nfsd) to use an [NFS synced vagrant folder](https://www.vagrantup.com/docs/synced-folders/nfs.html).  Using NFS outperforms standard Vagrant rsync folder share method significantly.  Else comment out the following line in Vagrantfile:
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
 Else you will need to type your `sudo` password when you `vagrant up` to allow vagrant-hostsupdater to modify your `/etc/hosts` file

### Resources ###

Ansible's docs:
> http://docs.ansible.com/ansible/latest/

Nice guide to setup/manage docker swarm with ansible:
> https://caylent.com/manage-docker-swarm-using-ansible/

### Instructions ###

Clone this repo onto your local machine, perform setup described in 'Requirements' section.

**Configure your virtual cluster**

- Edit `cluster_settings.yaml` as desired.
- Rename `cluster_secrets.example.yml` to `cluster_secrets.yml` and edit as desired

Note: `cluster_secrets.yml` is covered by `.gitignore`

**Fire up all nodes and provision them**

```
$ ./vagrant up
```

This will:

- take ~3-5 minutes per node
- instantiate the VMs
- install minimal packages to get Ansible running on node `ansible`
- create an Ansible hosts file for the cluster
- setup SSH key-based login from `ansible` to `node00` through `nodeXX`

*ToDo: vagrant-hostsupdater still asks me for sudo password... why?*

Finally, you can start working...

When finished, stop the Vagrant VMs:
```
vagrant halt -f
```

Destroy the VM environment:
```
vagrant destroy -f
```
