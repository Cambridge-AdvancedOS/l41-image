#!/usr/local/bin/python2.7
from commands import getstatusoutput
import os
import sys

packages_file = sys.argv[1]
ROOTFS = sys.argv[2]

PACKAGES = []
f = open(packages_file, "r")
for line in f:
	l = line.strip().split(": ")
	p = l[0]
	print(p)
	PACKAGES.append(p)

for pkg in PACKAGES:
	print 'Adding package %s' % pkg
	l = 'pkg -o INSTALL_AS_USER=1 -o METALOG=plop -r %s install -yM %s' % \
		(ROOTFS, pkg)
	status, output = getstatusoutput(l)
	if status != 0:
		print(output)
		sys.exit(3)
