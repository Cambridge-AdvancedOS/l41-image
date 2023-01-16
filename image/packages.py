#!/usr/local/bin/python2.7
from commands import getstatusoutput
import os
import sys

FILES = []

PATH = 'http://pkg.freebsd.org/FreeBSD:13:aarch64/release_1/All/'

packages_file = sys.argv[1]
mtree_file = sys.argv[2]
DISTFILES = sys.argv[3]

PACKAGES = []
f = open(packages_file, "r")
for line in f:
	l = line.strip().split(": ")
	p = "%s-%s.txz" % (l[0], l[1])
	print(p)
	PACKAGES.append(p)

for dir in [DISTFILES]:
	if not os.path.exists(dir):
		os.mkdir(dir)

for pkg in PACKAGES:
	if os.path.exists(os.path.join(DISTFILES, pkg)):
		continue
	print 'Fetching %s' % pkg
	p = os.path.join(PATH, pkg)
	status, output = getstatusoutput('fetch -o %s/%s %s' % \
			(DISTFILES, pkg, p))
	if status != 0:
		print("Failed to download %s" % p)
		sys.exit(1)

f = open(os.path.join(mtree_file), "w")
f.write("#mtree 2.0\n")
f.write('./%s type=dir uname=root gname=wheel mode=0755\n' % \
	os.path.basename(DISTFILES))

for pkg in PACKAGES:
	p = os.path.join(os.path.join(os.path.basename(DISTFILES), pkg))
	f.write('./%s type=file uname=root gname=wheel mode=0644\n' % p)

f.close()
