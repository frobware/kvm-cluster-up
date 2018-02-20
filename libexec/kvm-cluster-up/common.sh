set -a

: ${DRYRUN:=}

if [[ -n $KUP_ENV ]] && [[ -f $KUP_ENV ]]; then
    while IFS='' read -r line || [[ -n "$line" ]]; do
	#  Cleansing, Sanity, Paranoia. Choose any three.
	if [[ $line =~ "export KUP_" ]]; then
	    eval "$line"
	fi
    done < $KUP_ENV
fi

: ${KUP_PREFIX:?}
: ${KUP_NETWORK:?}
: ${KUP_DOMAINNAME:?}
: ${KUP_CLOUD_IMG:?}
: ${KUP_OS_VARIANT:?}
: ${KUP_CLOUD_USERNAME:?}

: ${KUP_DISK_RESIZE:=10}
: ${KUP_DISK_SIZE:=5}
: ${KUP_NCPUS:=2}
: ${KUP_RAM:=4096}
: ${KUP_POOL:=default}

set +a

die() {
    echo "error:" "$@"
    exit 1
}
