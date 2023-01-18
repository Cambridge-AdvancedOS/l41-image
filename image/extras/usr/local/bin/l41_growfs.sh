#!/bin/sh

FILENAME=/etc/l41_growfs_completed

if test -f "$FILENAME"; then
	exit 0
fi

#
# Resize the second MBR partition, which is BSD labels partition
#
/sbin/gpart resize -i 2 sdda0 || exit 1

#
# Resize the first BSD label, which holds FreeBSD rootfs.
#
/sbin/gpart resize -i 1 sdda0s2 || exit 2

#
# Save changes.
#
/sbin/gpart commit sdda0s2

#
# Now grow rootfs BSD label
#
/sbin/growfs -y /dev/sdda0s2a || exit 3

touch $FILENAME
