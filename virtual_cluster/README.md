# osparc-simcore Operations Development - Virtual Cluster

Quick start:

```bash
  # installs som pre-requisites
  sudo apt install virtualbox vagrant nfs-kernel-server
  sudo vagrant plugin install vagrant-hostsupdater # optional

  git clone git@github.com:itisfoundation/osparc-ops.git
  cd osparc-ops/virtual_cluster

  mkdir -p ./conf/generated/
  vagrant up

  # see that everything is up and running
  vagrant status

  # connect to ansible maghine
  vagrant ssh ansible

  # in ansible machine, we can run ansible

  # connect to manager01
  vagrant ssh manager01

  # stops all
  vagrant halt

  # destroys all virtual machines
  vagrant destroy -f
```

## Virtual Cluster for osparce platform operations development

- Quickly provision a cluster of VMs using Vagrant & VirtualBox
- Setup one node as an ansible control host, with passwordless SSH access to all other nodes
- Cluster defined in files: 
  - `cluster_settings.yml`
  - `cluster_secrets.yml`

## Requirements

To deploy on your own host, you need:

- Linux, (tested on Ubuntu/Xenial and Ubuntu/Bionic)
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/docs/)
- Working NFS server installed ([Ubuntu](https://help.ubuntu.com/stable/serverguide/network-file-system.html)/Debian = nfs-kernel-server ; RedHat/CentOS = nfsd) to use an [NFS synced vagrant folder](https://www.vagrantup.com/docs/synced-folders/nfs.html).  Using NFS outperforms standard Vagrant rsync folder share method significantly.  Else comment out the following line in Vagrantfile:
`  config.vm.synced_folder ".", "/vagrant", type: "nfs"`
- Sufficeint (SSD hopefully) disk storage to host the VM images and any persistent container disk images.

**Recommended**

- Install [Vagrant-hostsupdater plugin](https://github.com/cogitatio/vagrant-hostsupdater)
`$ vagrant plugin install vagrant-hostsupdater`
Else, you will need to add contents of `./config/hosts` to your own `/etc/hosts` file to allow your own host to communicate with all nodes by name (and disable hostsupdater parts of Vagrantfile).
- Modify your host's sudoers file (use `visudo`) to allow passwordless operation of Vagrant to setup an NFS share and use the persistent-storage plugin above.  Example for Ubuntu hosts:
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
 Else you will need to type your `sudo` password when you `vagrant up` to allow vagrant-hostsupdater to modify your `/etc/hosts` file. Note: _Ubuntu still asks me for sudo password... what am I missing here? ~EHZ_

### Resources ###

Virtualbox Docs:
> https://www.virtualbox.org/wiki/Documentation

Vagrant Docs:
> https://www.vagrantup.com/docs/

Ansible's Docs:
> http://docs.ansible.com/ansible/latest/

Nice guide to setup/manage docker swarm with ansible:
> https://caylent.com/manage-docker-swarm-using-ansible/

## Instructions

Clone this repo onto your local machine, perform setup described in 'Requirements' section.

**Configure your virtual cluster**

- Edit `cluster_settings.yml` as desired.
- Rename `cluster_secrets.example.yml` to `cluster_secrets.yml` and edit as desired

Note: `cluster_secrets.yml` is covered by `.gitignore`

**Fire up all nodes and provision them**

```
you@yourhost:~/osparc-ops/virtual_cluster$ ./vagrant up
```

This will:

- take ~3-5 minutes per node
- instantiate the VMs
- install minimal packages to get Ansible running on the control node
- create an Ansible hosts file for the cluster
- setup SSH key-based login from the control node to all other nodes

Finally, you can start working...

SSH to the ansible control node (default name `ansible` defined in `cluster_settings.yml`)
```
you@yourhost:~/osparc-ops/virtual_cluster$ vagrant ssh ansible
```

Test that Ansible is setup correctly and can talk to all your nodes:
```
vagrant@ansible:~$ ansible all -m setup -a "filter=ansible_distribution*
```

Clone the osparc-simcore repository onto your control node, so you can start a deployment:
```
vagrant@ansible:~$ ansible-playbook /vagrant/ansible/osparc-fetch.yml
```

Deploy osparc-simcore to your virtual cluster:
```
vagrant@ansible:~$ cd osparc-simcore/ops/ansible
vagrant@ansible:~/osparc-simcore/ops/ansible$ ansible-playbook osparc-simcore-deploy.yml
```

Once that's done, access services at: `http://<IP-address-of-manager-node>:<port>`. See `cluster_settings.yml` to find that IP address.

Manage your cluster from a manger node:
```
you@yourhost:~/osparc-ops/virtual_cluster$ vagrant ssh manager01
...
vagrant@manager01:~$ docker service ls
```

When finished, stop the Vagrant VMs:
```
you@yourhost:~/osparc-ops/virtual_cluster$ vagrant halt -f
```

Destroy the VM environment:
```
you@yourhost:~/osparc-ops/virtual_cluster$ vagrant destroy -f
```
