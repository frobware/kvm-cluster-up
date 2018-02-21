EXTRA_DIST =					\
	README.md				\
	bootstrap.sh

# Should really use $(program-prefix) for all the kup- entries but
# that means the the pkglibexec_SCRIPTS also get changed.

dist_bin_SCRIPTS =				\
	bin/kup-delete-config-drive		\
	bin/kup-detach-config-drive		\
	bin/kup-domain-delete			\
	bin/kup-domain-install			\
	bin/kup-domain-reboot			\
	bin/kup-domain-start			\
	bin/kup-domain-stop			\
	bin/kup-domain-wait-for-state		\
	bin/kup-snapshot-create			\
	bin/kup-snapshot-delete			\
	bin/kup-snapshot-list			\
	bin/kup-snapshot-replace		\
	bin/kup-snapshot-select			\
	bin/kup-upload-file-to-pool

pkglibexec_SCRIPTS =					\
	libexec/kvm-cluster-up/common.sh		\
	libexec/kvm-cluster-up/create-config-drive	\
	libexec/kvm-cluster-up/meta-data		\
	libexec/kvm-cluster-up/user-data
