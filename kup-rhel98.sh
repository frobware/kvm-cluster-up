# RHEL 9.8 KVM guest image (qcow2), e.g. built with Red Hat Image
# Builder or downloaded from access.redhat.com; upload it into the
# default pool with kup-upload-file-to-pool first.
export KUP_PREFIX=rhel98
export KUP_NETWORK=default
export KUP_DOMAINNAME=int.frobware.com
export KUP_CLOUD_IMG=rhel-9.8-x86_64-kvm.qcow2
export KUP_OS_VARIANT=rhel9.7
export KUP_CLOUD_USERNAME=cloud-user
export KUP_NCPUS=4
export KUP_RAM=8192

# SSH into instance 1 (VM must be running):
#   ssh cloud-user@$(KUP_ENV=kup-rhel98.sh kup-domain-ipaddr 1)
