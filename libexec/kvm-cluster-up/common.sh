set -a

: ${DRYRUN:=}

if [[ -n $KUP_ENV ]] && [[ -f $KUP_ENV ]]; then
    source $KUP_ENV		# man rope
fi

: ${KUP_PREFIX:?}
: ${KUP_NETWORK:?}
: ${KUP_DOMAINNAME:?}
: ${KUP_CLOUD_IMG:?}
: ${KUP_OS_VARIANT:?}
: ${KUP_CLOUD_USERNAME:?}

: ${KUP_DISK_RESIZE:=50}
: ${KUP_DISK_SIZE:=50}
: ${KUP_NCPUS:=2}
: ${KUP_RAM:=4096}
: ${KUP_POOL:=default}

set +a

die() {
    echo "error:" "$@"
    exit 1
}
