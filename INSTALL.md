# Installation

These scripts rely on libvirt, virsh and virt-install, et al to
provision and manage the machines.

## Package prerequisites

### Fedora

	$ sudo dnf install autoconf automake virt-manager libvirt virt-install util-linux genisoimage git wget

## Build and Install

	$ git clone https://github.com/frobware/kvm-cluster-up.git
	$ cd kvm-cluster-up
	$ ./bootstrap.sh
	$ ./configure [--prefix=$HOME/bin ]
	$ make
	$ sudo make install

All the scripts have a `kup-` prefix, yielding easy tab-completion and
identification.

# Compute

	$ sudo systemctl enable libvirtd
	$ sudo systemctl start libvirtd

## Using libvirt without sudo or root access

You really want to use `virsh(1)`, `virt-manager(1)`, et al, without
requiring root or sudo access. To do so add yourself to the `libvirt`
group:

	$ sudo usermod -aG libvirt $USER

	# For that to take effect you need to logout/login.
	# Alternatively log in to the new group:

	$ newgrp libvirt
	$ groups
	libvirt adm wheel systemd-journal ...

I find you also need the following (permanently) set in your
environment:

	$ export LIBVIRT_DEFAULT_URI=qemu:///system

See this [question and answer](https://serverfault.com/questions/803283/how-do-i-list-virsh-networks-without-sudo/803298) as for why.

To verify you are have a working environment you should be able to
list the default libvirt network that gets created without requiring
sudo access:

	$ virsh net-list --all

	 Name                 State      Autostart     Persistent
	----------------------------------------------------------
	 default              active     yes           yes

# Network Configuration

The simplest configuration is to bridge locally on the virtualisation
host:

	$ virsh net-define /dev/stdin <<EOF
	<network>
		<name>k8s</name>
		<domain name='k8s.home' localOnly='yes'/>
		<forward mode='nat'>
			<nat>
				<port start='1024' end='65535'/>
			</nat>
		</forward>
		<ip address='192.168.121.1' netmask='255.255.255.0'>
			<dhcp>
				<range start='192.168.121.128' end='192.168.121.254'/>
			</dhcp>
		</ip>
	</network>

	$ virsh net-start k8s
	Network k8s started

	$ virsh net-autostart k8s
	Network k8s marked as autostarted

## DNS resolution

On my libvirt host I really want DNS resolution to just work for these
virtual machines. Given that we know our network CIDR we can add the
following on the virtualisation host:

	$ cat /etc/NetworkManager/dnsmasq.d/k8s.conf
	server=/k8s.home/192.168.121.1

You need to ensure that NetworkManager runs dnsmasq so that our
intercept will work:

	$ cat /etc/NetworkManager/NetworkManager.conf
	...
	[main]
	dns=dnsmasq
	...

Restart NetworkManager to make this take affect:

	$ systemctl restart NetworkManager
	
On the virtualisation host, and this host alone, we can resolve
machine names:

	$ dig centos7-vm-1.k8s.home

# Storage

The scripts that upload cloud images use the `default` storage pool.
Make sure this is available and currently running because by default
it is not:

	$ virsh pool-list --all

	 Name                 State      Autostart
	-------------------------------------------

## Creating the `default` pool

	$ virsh pool-define /dev/stdin <<EOF
	<pool type='dir'>
	  <name>default</name>
	  <target>
		<path>/var/lib/libvirt/images</path>
	  </target>
	</pool>
	EOF

	$ virsh pool-start default
	Pool default started

	$ virsh pool-autostart default
	Pool default marked as autostarted

# Cloud Images

The cloud images you intend to use need to be uploaded into the
`default` storage pool.

	$ wget https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2
	$ kup-upload-file-to-pool Fedora-Cloud-Base-27-1.6.x86_64.qcow2
	Pool default refreshed
	Vol Fedora-Cloud-Base-27-1.6.x86_64.qcow2 created
