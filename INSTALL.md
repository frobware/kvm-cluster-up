# Installation & virsh preparation

These scripts rely on libvirt, virsh and virt-install, et al to
provision and manage the machines. You need to be a member of the
libvirt group to use these scripts without requiring root or sudo
access.

	$ sudo dnf install autoconf virt-manager libvirt virt-install util-linux genisoimage

	$ git clone https://github.com/frobware/kvm-cluster-up.git
	$ cd kvm-cluster-up
	$ ./bootstrap.sh
	$ ./configure
	$ make
	$ sudo make install

All the scripts have a `kup-` prefix, yielding easy tab-completion.

## Storage

The scripts that upload cloud images use the `default` storage pool.
Make sure this this is available and currently running.

## Cloud Images

The cloud images you intend to use need to be uploaded into the
`default` storage pool.

	$ wget https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2
	$ kup-upload-file-to-pool Fedora-Cloud-Base-27-1.6.x86_64.qcow2

## Network Configuration

The simplest configuration is to bridge locally on the virtualisation
host:

	$ cat network.xml
	<network>
		<name>kvm-cluster-up</name>
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

	$ virsh net-define network.xml
	$ virsh net-autostart kvm-cluster-up
