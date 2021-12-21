#!/bin/sh

FILENAME=/etc/l41_packages_installed
DISTFILES="/distfiles"
PKG="/usr/local/sbin/pkg-static"

export ASSUME_ALWAYS_YES=yes

if ! test -f "$PKG"; then
	PKG="/usr/local/sbin/pkg-static.pkgsave"
fi

if ! test -f "$PKG"; then
	exit 3
fi

if test -f "$FILENAME"; then
	exit 0
fi

if ! test -d "$DISTFILES"; then
	exit 0
fi

/usr/local/sbin/pkg-static install -y $(ls /distfiles/*txz) || exit 1

touch $FILENAME
