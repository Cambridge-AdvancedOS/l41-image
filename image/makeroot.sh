#!/bin/sh -e
#-
# Copyright (c) 2012-2014, 2016 SRI International
# Copyright (c) 2012 Robert N. M. Watson
# All rights reserved.
#
# This software was developed by SRI International and the University of
# Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
# ("CTSRD"), as part of the DARPA CRASH research programme.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $FreeBSD$

usage()
{
	cat <<EOF 1>&2
usage: makeroot.sh [-B byte-order] [-d] [-D] [-e <extras manifest>] [-f <filelist>]
                   [-k <keydir> [-K <user>]] [-F <free inodes>]
                   [-p <master.passwd> [-g <groupfile>]] [-s <size>]
		   [-X <exclude pattern>] [-M <extra flags for makefs>]
		   [-t <fstype: ffs or cd9660>]
		   <image> <bsdroot>
EOF
	exit 1
}

warn()
{
	echo `basename $0` "$@" 1>&2
}

err()
{
	ret=$1
	shift
	warn "$@"
	exit $ret
}

atexit()
{
	if [ -z "${DEBUG}" ]; then
		rm -rf ${tmpdir}
	else
		warn "temp directory left at ${tmpdir}"
	fi
}

DEBUG=
DEBUGFLAG_MAKEFS=
# Allow duplice manifest entries when not file list is given because the
# FreeBSD METALOG still includes it.
DUPFLAG=-D
EXTRAS=
FILELIST=
GROUP=
KEYDIR=
KEYUSERS=
PASSWD=
FREEINODESFLAG="-f 256"
FSTYPE=ffs
EXTRA_MAKEFS_FLAGS=

while getopts "B:dD:e:f:g:K:k:p:s:t:M:F:X:" opt; do
	case "$opt" in
	B)	BFLAG="-B ${OPTARG}" ;;
	d)	DEBUG=1 ;;
	D)	DEBUGFLAG_MAKEFS="-d ${OPTARG}" ;;
	e)	EXTRAS="${EXTRAS} ${OPTARG}" ;;
	f)	FILELIST="${FILELIST} ${OPTARG}";
		# Allow dups due to packaging issues.
		#DUPFLAG=
		;;
	g)	GROUP="${OPTARG}" ;;
	K)	KEYUSERS="${KEYUSERS} ${OPTARG}" ;;
	k)	KEYDIR="${OPTARG}" ;;
	p)	PASSWD="${OPTARG}" ;;
	s)	SIZE="${OPTARG}" ;;
	t)	FSTYPE="${OPTARG}" ;;
	F)	FREEINODES="${OPTARG}" ;;
	M)	EXTRA_MAKEFS_FLAGS="${OPTARG}" ;;
	X)
		if [ -n "$EXCLUDE_FILTER" ]; then
			warn "The -X option can be applied only once"
			usage
		fi
		EXCLUDE_FILTER="grep -v -E ${OPTARG}"
		;;
	*)	usage ;;
	esac
done
shift $(($OPTIND - 1))

if [ $# -ne 2 ]; then
	usage;
fi

if [ -z "$EXCLUDE_FILTER" ]; then
	EXCLUDE_FILTER=cat
fi

IMGFILE=$(realpath $(dirname $1))/$(basename $1)
BSDROOT=$2

DBDIR=${BSDROOT}/etc

if [ ! -r ${BSDROOT}/METALOG ]; then
	err 1 "${BSDROOT} does not contain a METALOG"
fi

if [ -n "${GROUP}" -a -z "${PASSWD}" ]; then
	warn "-g requires -p"
	usage
fi

if [ -n "${KEYUSERS}" -a -z "${KEYDIR}" ]; then
	warn "-K requires -k"
	usage
fi
if [ -n "${KEYDIR}" -a -z "${KEYUSERS}" ]; then
	KEYUSERS=root
fi

tmpdir=`mktemp -d /tmp/makeroot.XXXXX`
if [ -z "${tmpdir}" -o ! -d "${tmpdir}" ]; then
	err 1 "failed to create tmpdir"
fi
trap atexit EXIT

manifest=${tmpdir}/manifest

echo "#mtree 2.0" > ${manifest}

if [ -n "${PASSWD}" ]; then
	cp ${PASSWD} ${tmpdir}/master.passwd
	pwd_mkdb -d ${tmpdir} -p ${tmpdir}/master.passwd
	if [ -z "${GROUP}" ]; then
		cp ${DBDIR}/group ${tmpdir}
	else
		cp ${GROUP} ${tmpdir}
	fi

	cat <<EOF >> ${tmpdir}/passwd.mtree
./etc/group type=file uname=root gname=wheel mode=0644 contents=${tmpdir}/group
./etc/master.passwd type=file uname=root gname=wheel mode=0600 contents=${tmpdir}/master.passwd
./etc/passwd type=file mode=0644 uname=root gname=wheel contents=${tmpdir}/passwd
./etc/pwd.db type=file mode=0644 uname=root gname=wheel contents=${tmpdir}/pwd.db
./etc/spwd.db type=file mode=0600 uname=root gname=wheel contents=${tmpdir}/spwd.db
EOF
	EXTRAS="${EXTRAS} ${tmpdir}/passwd.mtree"

	DBDIR=${tmpdir}
fi

if [ -n "${FILELIST}" ]; then
	sed -E -e 's|//+|/|g' -e 's/time=[^ ]*//' ${BSDROOT}/METALOG > ${tmpdir}/METALOG
	# build manifest from root manifest and FILELIST
	(echo .; grep -h -v ^# ${FILELIST} | while read path; do
		# Print each included path and all its sub-paths with a ./
		# prepended.  The "sort -u" will then discard all the
		# duplicate directory entries.  This ensures that we
		# extract the permissions for each unlisted directory
		# from the METALOG.
		path="/${path}"
		while [ -n "${path}" ]; do
			echo ".${path}"
			path="${path%/*}"
		done 
	done) | sort -u ${tmpdir}/METALOG - | ${EXCLUDE_FILTER} | \
	    sed -e 's/tags=[^ ]*//' | \
	    awk '
		!/ type=/ { file = $1 }
		/ type=/ { if ($1 == file) {print} }' >> ${manifest}
else
	# Start with all the files in BSDROOT/METALOG except those in
	# one of the EXTRAS manifests.
	grep -h type=file ${EXTRAS} | cut -d' ' -f1 | \
	    sort -u ${BSDROOT}/METALOG - | ${EXCLUDE_FILTER} | \
	    sed -e 's/tags=[^ ]*//' -e 's/time=[^ ]*//' | \
	    awk '
		!/ type=/ { file = $1 }
		/ type=/ { if ($1 != file) {print} }' >> ${manifest}
fi

# For each extras file, add contents keys relative to the directory the
# manifest lives in for each file line that does not have one.  Adjust
# contents keys relative to ./ to be relative to the same directory.
for eman in ${EXTRAS}; do
	if [ ! -f ${eman} ]; then
		err 1 "${eman} is not a regular file"
	fi
	extradir=`realpath ${eman}`; extradir=`dirname ${extradir}`

	awk '{
		if ($0 !~ /type=file/) {
			print
		} else {
			if ($0 !~ /contents=/) {
				printf ("%s contents=%s\n", $0, $1)
			} else {
				print
			}
		}
	}' ${eman} | \
	    sed -e "s|contents=\./|contents=${extradir}/|" >> ${manifest}
done

# /etc/rcorder.start allows the startup order to be stable even if
# not all startup scripts are installed.  In theory it should be
# unnecessicary, but dependencies in rc.d appear to be under recorded.
# This is a hack local to beri/cheribsd.
#
echo /etc/rc.d/FIRST > ${tmpdir}/rcorder.start
rcorder -s nostart ${BSDROOT}/etc/rc.d/* | sed -e "s:^${BSDROOT}::" | \
     grep -v LAST | grep -v FIRST >> \
    ${tmpdir}/rcorder.start
echo /etc/rc.d/LAST >> ${tmpdir}/rcorder.start
echo "./etc/rcorder.start type=file mode=644 uname=root gname=wheel" \
   "contents=${tmpdir}/rcorder.start" >> ${manifest}

# Add all public keys in KEYDIR to roots' authorized_keys file.
if [ -n "${KEYDIR}" ]; then
	cat ${KEYDIR}/*.pub > ${tmpdir}/authorized_keys
	if [ ! -s ${tmpdir}/authorized_keys ]; then
		err 1 "no keys found in ${KEYDIR}"
	fi
	for user in ${KEYUSERS}; do
		userdir=`awk -F: "{if (\\\$1 == \"${user}\") {print \\\$9; exit} }" ${DBDIR}/master.passwd`
		gid=`awk -F: "{if (\\\$1 == \"${user}\") {print \\\$4; exit} }" ${DBDIR}/master.passwd`
		group=`awk -F: "{if (\\\$3 == \"${gid}\") {print \\\$1; exit} }" ${DBDIR}/group`
		if [ -z "${userdir}" ]; then
			err 1 "${user}: not found in ${DBDIR}/master.passwd"
		fi
		echo ".${userdir}/.ssh type=dir mode=700 uname=${user} gname=${group}" >> ${manifest}
		echo ".${userdir}/.ssh/authorized_keys type=file mode=600 uname=${user} gname=${group} contents=${tmpdir}/authorized_keys" >> ${manifest}
	done
fi

if [ -n "${SIZE}" ]; then
SIZEFLAG="-s ${SIZE}"
fi

if [ -n "${FREEINODES}" ]; then
FREEINODESFLAG="-f ${FREEINODES}"
fi

makefs_command="makefs -o version=2,label=rootfs,softupdates=1 ${DUPFLAG} \
    -N ${DBDIR} ${SIZEFLAG} ${BFLAG} ${DEBUGFLAG_MAKEFS} -t ${FSTYPE} \
    ${FREEINODESFLAG} ${EXTRA_MAKEFS_FLAGS} ${IMGFILE} ${manifest}"
# Allow building .tar archives in addition to ffs/ISO images
if [ "$FSTYPE" == "tar" ]; then
	makefs_command="tar -cvf ${IMGFILE} @${manifest}"
fi

if [ -n "${DUMP_MANIFEST}" ]; then
	echo "GENERATED MTREE MANIFEST:"
	cat "${manifest}"
fi

if [ -n "${DEBUG}" ]; then
	echo "cd ${BSDROOT}; ${makefs_command}"
fi
cd ${BSDROOT}; ${makefs_command}
