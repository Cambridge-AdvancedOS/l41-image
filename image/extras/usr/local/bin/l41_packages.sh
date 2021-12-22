#!/bin/sh

FILENAME=/etc/l41_packages_installed
DISTFILES="/distfiles"
PKG="/usr/local/sbin/pkg-static"

export PATH="$PATH:/usr/local/bin/"
export ASSUME_ALWAYS_YES=yes

if test -f "$FILENAME"; then
	exit 0
fi

if ! test -d "$DISTFILES"; then
	exit 0
fi

# Untar pkg first
if ! test -f "$PKG"; then
	tar -C / -zxf /distfiles/pkg-*.txz $PKG || exit 1
fi

# Now install packages
for file in $(ls /distfiles/); do
	$PKG install -M /distfiles/$file
done

touch $FILENAME
