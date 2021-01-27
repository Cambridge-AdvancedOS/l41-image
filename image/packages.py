#!/usr/local/bin/python2.7
from commands import getstatusoutput
import os
import sys

TMP = './tmp'
DISTFILES = './distfiles'
FILES = []
DIRS = []

PATH = 'http://pkg.freebsd.org/FreeBSD:13:aarch64/latest/All/'

packages_file = sys.argv[1]
mtree_file = sys.argv[2]
ROOTFS = sys.argv[3]

PACKAGES = []
f = open(packages_file, "r")
for line in f:
	l = line.strip().split(": ")
	p = "%s-%s.txz" % (l[0], l[1])
	print(p)
	PACKAGES.append(p)

for dir in [TMP, DISTFILES]:
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

for pkg in PACKAGES:
	print 'Extracting package %s' % pkg
	status, output = getstatusoutput('tar -C %s -zxf %s/%s' % \
				(TMP, DISTFILES, pkg))
	if status != 0:
		sys.exit(2)

	print 'Installing package %s' % pkg
	l = 'pkg -o INSTALL_AS_USER=1 -o METALOG=plop -r %s install %s/%s' % \
		(ROOTFS, DISTFILES, pkg)
	status, output = getstatusoutput(l)
	if status != 0:
		print(output)
		sys.exit(3)

	f = open(os.path.join(TMP,"+MANIFEST"),"r")
	m = f.read()
	f.close()

	d = eval(m)
	files = d['files']

	for file in files:
		file = file.lstrip('/')
		link = False
		p = os.path.join(TMP, file)
		if os.path.islink(p):
			link = os.readlink(p)
		mode = os.lstat(p).st_mode
		FILES.append((file,link, mode))

for w in os.walk(os.path.join(TMP, "usr")):
	DIRS.append(w[0].replace(TMP, ""))

f = open(os.path.join(TMP, mtree_file),"w")
f.write("#mtree 2.0\n")

for dir in DIRS:
	f.write('.%s type=dir uname=root gname=wheel mode=0755\n' % \
			dir.replace(" ","\ "))

for file, link, mode in FILES:
	mode = oct(mode & 0xfff)
	if file == 'usr/local/bin/sudo':
		mode = '04555'
	# not sure how to use mtree with space in the filename
	if ' ' in file:
		continue
	if link:
		f.write('./%s type=link uname=root'
			' gname=wheel mode=%s link=%s\n' % \
			(file.replace(" ","\s"), mode, link))
	else:
		f.write('./%s type=file uname=root gname=wheel mode=%s\n' % \
			(file.replace(" ","\s"), mode))

f.close()
