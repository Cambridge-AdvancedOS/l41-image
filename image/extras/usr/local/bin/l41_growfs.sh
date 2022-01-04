#!/bin/sh

FILENAME=/etc/l41_growfs_completed

if test -f "$FILENAME"; then
	exit 0
fi

#
# Resize the second MBR partition, which is BSD labels partition
#
/sbin/gpart resize -i 2 sdda0 || exit 1

/sbin/sysctl kern.geom.debugflags=16

#
# Resize the first BSD label, which holds FreeBSD rootfs
#
/sbin/gpart resize -i 1 -s 48G sdda0s2 || exit 2

#
# Add the swap BSD label
#
/sbin/gpart add -t freebsd-swap sdda0s2 || exit 3

/sbin/sysctl kern.geom.debugflags=0

#
# Now grow rootfs BSD label
#
/sbin/growfs -y /dev/sdda0s2a || exit 4

#
# Activate swap BSD label
#
/sbin/swapon -a

touch $FILENAME
