#!/bin/sh

FILENAME=/etc/l41_packages_installed
DISTFILES="/distfiles"

export ASSUME_ALWAYS_YES=yes

if test -f "$FILENAME"; then
	exit 0
fi

if ! test -d "$DISTFILES"; then
	exit 0
fi

# Install pkg first
pkg info pkg || pkg

# Now install all the files
for file in $(ls $DISTFILES); do
	pkg info -q $file || pkg install -y /distfiles/$file || exit 1
done

touch $FILENAME
