# Introduction

Scripts to conveniently install and manage multiple KVM machines.

During development or, in particular, when I'm trying to reproduce
bugs I often find I need a group of machines that need to be quickly
provisioned and isolated from whatever I was currently doing. These
machines typically need identical configuration (i.e., ram & disk &
network). I also require a naming pattern so that when I run `virsh
list` I can _actually_ recall why I spun them up in the first place.

The scripts in this repository allow you to:

- provision KVM-based machines, based on a profile
- manage those machines (reboot, shutdown, start)
- take snapshots
- delete snapshots
- revert to a particular snapshot
- upload images to the KVM storage pool

# Profiles

To manage disparate configurations we have the notion of a *profile*.
A profile is a just a file with per-profile properties.

## Example

	$ cat kup-centos7
	export KUP_PREFIX=centos7
	export KUP_NETWORK=br-enp1s0f3
	export KUP_DOMAINNAME=k8s.frobware.com
	export KUP_CLOUD_IMG=CentOS-7-x86_64-GenericCloud.qcow2
	export KUP_OS_VARIANT=rhel7.4
	export KUP_CLOUD_USERNAME=centos

Taking these environment variables in turn we have:

- `KUP_PREFIX` - the prefix for machine names; machines will be
  provisioned as `$KUP_PREFIX-vm-$N`.
- `KUP_NETWORK` - the libvirt network; this needs to be provisioned
  ahead of time and it also needs to be started/running
- `KUP_DOMAINNAME` the domain the KVM machine resides in. This is
  passed as meta-data to cloud-init.
- `KUP_CLOUD_IMG` - the image to clone for the new machine
- `KUP_CLOUD_USERNAME` - the cloud-image user name
- `KUP_OS_VARIANT` - optional; helper for libvirt

### RHEL 7.4 Example

	$ cat kup-rhel74
	export KUP_PREFIX=rhel74-dev
	export KUP_NETWORK=br-enp1s0f3
	export KUP_DOMAINNAME=k8s.frobware.com
	export KUP_CLOUD_IMG=rhel-server-7.4-x86_64-kvm.qcow2
	export KUP_OS_VARIANT=rhel7.4
	export KUP_CLOUD_USERNAME=cloud-user

### Fedora 27 Example

	$ cat kup-fedora27
	export KUP_PREFIX=fedora27-dev
	export KUP_NETWORK=br-enp1s0f3
	export KUP_DOMAINNAME=k8s.frobware.com
	export KUP_CLOUD_IMG=Fedora-Cloud-Base-27-1.6.x86_64.qcow2
	export KUP_OS_VARIANT=fedora26	# no variant in libvirt (ATM) for fedora27
	export KUP_CLOUD_USERNAME=fedora

### Debian Example

	$ cat kup-debian9
	export KUP_PREFIX=debian9
	export KUP_NETWORK=br-enp1s0f3
	export KUP_DOMAINNAME=k8s.frobware.com
	export KUP_CLOUD_IMG=debian-9.3.5-20180213-openstack-amd64.qcow2
	export KUP_OS_VARIANT=linux	# no variant in libvirt (ATM)
	export KUP_CLOUD_USERNAME=debian

# Building a Cluster

To build a cluster based on a profile run:

	$ KUP_ENV=$HOME/kup-centos7 kup-domain-install 1
	adding pubkey from /home/aim/.ssh/id_rsa.pub
	adding user data from /usr/local/bin/../libexec/kvm-cluster-up/user-data
	generating configuration image at /tmp/tmp.6xVhuYVKeN/centos7-vm-1-ds.iso
	Pool default refreshed
	Vol centos7-vm-1-ds.iso created
	Vol centos7-vm-1.qcow2 cloned from CentOS-7-x86_64-GenericCloud.qcow2
	Size of volume 'centos7-vm-1.qcow2' successfully changed to +50G
	Pool default refreshed
	Starting install...
	Domain creation completed.

This provisions and boots asynchronously. The default action is to
boot the machine, let cloud-init run, then power off. I chose to
power-off as the default to facilitate snapshots. The provisioning
step dynamically creates a cloud-init data-store as an ISO and
attaches that disk as `/dev/vdb`. That disk needs to be detached if
you want to use snapshots.

But one machine does not make a cluster! In general all the `kup-*`
scripts take *instance-id* arguments, where an *instance-id* is just a
unique symbol.

To provision multiple machines:

	$ KUP_ENV=$HOME/kup-centos7 kup-domain-install 1 2 3 4

	$ virsh list --all | grep centos7-vm
	13 centos7-vm-2 running
	14 centos7-vm-3 running
	15 centos7-vm-4 running
	16 centos7-vm-1 running

To provision more machines:

	$ KUP_ENV=$HOME/kup-centos7 kup-domain-install 80 90 100

The numbers do not need to be consecutive; they are just used to
provide unique names. In fact, they don't even need to be numbers.

	$ KUP_ENV=$HOME/kup-centos7 kup-domain-install master etcd node1 node2 node3

	$ virsh list --all
	Id    Name                           State
	----------------------------------------------------
	-     centos7-vm-1                   shut off
	-     centos7-vm-2                   shut off
	-     centos7-vm-3                   shut off
	-     centos7-vm-4                   shut off
	-     centos7-vm-master              shut off
	-     centos7-vm-etcd                shut off
	-     centos7-vm-node1               shut off
	-     centos7-vm-node2               shut off
	-     centos7-vm-node3               shut off

## Memorable Profiles

Sometimes I find I have a number of centos7 machines already running
that should not be perturbed but I need **moar** to investigate a
different bug so let's just create new instances...

	$ KUP_ENV=$HOME/kup-centos7 10 20 30

But relying on different sets of numbers can get confusing; it's
easier to create another profile with a prefix that has more context:

	$ cat kup-centos7-bz18020
	export KUP_PREFIX=centos7-bz18020
	export KUP_NETWORK=br-enp1s0f3
	export KUP_DOMAINNAME=k8s.frobware.com
	export KUP_CLOUD_IMG=CentOS-7-x86_64-GenericCloud.qcow2
	export KUP_OS_VARIANT=rhel7.4
	export KUP_CLOUD_USERNAME=centos

## Exporting KUP_ENV

**Here be dragons**

You can export KUP_ENV which means you don't have to prefix any of the
`kup-*<program>*` usage:

	$ export KUB_ENV=$HOME/kup-centos7
	# Boot a machine
	# kup-domain-install 1
	# Do lots of work in another shell, lunch, ...

	# Come back from lunch...
	# kup-domain-delete 1
	# **OOPS!** This wasn't the profile I thought I was using... Dang! IRL, way too often. :/

# Accessing the machines

As I only use cloud-based images you need to use the correct
*username* when accessing the machines. This is also why you need to
specify `KUP_CLOUD_USERNAME` in the profile. I wrap up access in my
`$HOME/.ssh/config`:


	Host *
		GSSAPIAuthentication no
		CanonicalizeHostname yes

	Host centos7-vm-1 centos7-vm-2 centos7-vm-3 centos7-vm-4 centos7-vm-5 centos7-vm-6 centos7-vm-7 centos7-vm-8
		HostName %h.k8s.frobware.com
		User centos

	Host rhel74-vm-1 rhel74-vm-2 rhel74-vm-3 rhel74-vm-4 rhel74-vm-5 rhel74-vm-6 rhel74-vm-7 rhel74-vm-8
		HostName %h.k8s.frobware.com
		User cloud-user

	Host fedora27-vm-1 fedora27-vm-2 fedora27-vm-3 fedora27-vm-4 fedora27-vm-5 fedora27-vm-6 fedora27-vm-7 fedora27-vm-8
		HostName %h.k8s.frobware.com
		User cloud-user

	Host *.k8s.frobware.com
		GSSAPIAuthentication no
		ControlPersist 10m
		ControlMaster auto
		ControlPath /tmp/%r@%h:%p
		ForwardAgent yes
		StrictHostKeyChecking no
		UserKnownHostsFile /dev/null
		HashKnownHosts no
		LogLevel QUIET
		CheckHostIP no

Note: as these machines are on my LAN and tend to have a short-life,
the security setup is, well, super-lax!

## Logging into the instance

Based on the previous `.ssh/config` we can login straight in without
having to worry about what the user name should be.

	$ ssh centos7-vm-1
	$ ssh rhel74-vm-2
	$ ssh fedora27-vm-3

You can also login via the console:

	$ virsh dominfo centos7-vm-1 | grep Id: | awk '{ print $2 }'
	# 19
	$ virsh console 19
	Connected to domain centos7-vm-1
	Escape character is ^]

	CentOS Linux 7 (Core)
	Kernel 3.10.0-693.el7.x86_64 on an x86_64
	centos7-vm-1 login: centos
	Password: password

	Last login: Wed Feb 21 11:19:23 from 192.168.30.64

I told you the security was super-lax!

# Machine management

There are a number of scripts to aid in provisioning, starting up,
shutting down and rebooting the machines in the cluster.

- `kup-domain-delete`
- `kup-domain-install`
- `kup-domain-reboot`
- `kup-domain-start`
- `kup-domain-stop`

Each script takes `*<instance-id>...*` as [the only] arguments.
Hopefully these are all very obvious and orthogonal.

	$ kup-domain-delete 1 2 3 4
	$ kup-domain-delete node1 etcd
	$ kup-domain-install 1 2 3 4
	$ kup-domain-reboot 82 90 91
	$ kup-domain-reboot master
	$ kup-domain-start 1 2 3 4
	$ kup-domain-start master etcd node1 node2
	$ kup-domain-stop  master etcd node1 node2

# Snapshots

Reinstalling is not for fun or profit! Well, not normally. To speed up
my dev-cycle I tend to make liberal use of snapshots.

## Install base image and detach config-drive

	$ kup-domain-install 1 2 3 4
	# wait for machine(s) to provision and power off
	$ kup-detach-config-drive 1 2 3 4
	Disk detached successfully
	Disk detached successfully
	Disk detached successfully
	Disk detached successfully

## Take a snapshot

Prep the machine(s) in some way, then take a snaphost so we can eaily
revert:

	$ SNAPSHOT=baseinstall kup-snapshot-create 1
	Domain snapshot baseinstall created

	$ kup-domain-start 1
	Domain centos7-vm-1 started

	$ ansible-playbook -i centos7-vm-1, /path/to/playbook.yaml

	$ kup-domain-stop 1
	Domain centos7-vm-1 destroyed

	$ SNAPSHOT=pkg-refresh kup-snapshot-create 1
	Domain snapshot pkg-refresh created

## List snapshots

	$ kup-snapshot-list 1 2 3 4

	Name                 Creation Time             State
	------------------------------------------------------------
	baseinstall          2018-02-21 11:43:01 +0000 shutoff
	pkg-refresh          2018-02-21 11:43:40 +0000 shutoff

	Name                 Creation Time             State
	------------------------------------------------------------

	Name                 Creation Time             State
	------------------------------------------------------------

	Name                 Creation Time             State
	------------------------------------------------------------

Here you can see I've only created snapshots for the machine
identified as `*1*`.

## Reverting/Selecting a snapshot by name

	$ kup-domain-stop 1
	$ SNAPSHOT=baseinstall kup-snapshot-select 1
	$ kup-domain-start 1

## Replacing a snapshot

If a snapshot name already exists the existing snapshot must be deleted first:

	$ kup-domain-stop 1
	$ SNAPSHOT=baseinstall kup-snapshot-select 1

	$ kup-domain-start 1
	# login, do some stuff

	$ kup-domain-stop 1
	$ SNAPSHOT=pkg-refresh kup-snapshot-delete 1
	$ SNAPSHOT=pkg-refresh kup-snapshot-create 1

# Installation

Please read the [INSTALL](INSTALL.md) companion.
