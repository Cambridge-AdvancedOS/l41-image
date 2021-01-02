#!/usr/local/bin/python2.7
from commands import getstatusoutput
import os
import sys

TMP = './tmp'
DISTFILES = './distfiles'
FILES = []
DIRS = []

PATH = 'http://pkg.freebsd.org/FreeBSD:13:aarch64/latest/All/'

PACKAGES = [
	'python27-2.7.18_1.txz',
	'sudo-1.9.4p2.txz',
	'bash-5.1.4.txz',
	'indexinfo-0.3.1.txz',
	'readline-8.0.4.txz',
	'gettext-runtime-0.21.txz',
	'libffi-3.3_1.txz',
	]

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

f = open(os.path.join(TMP, "pkg.mtree"),"w")
f.write("#mtree 2.0\n")

for dir in DIRS:
	f.write('.%s type=dir uname=root gname=wheel mode=0755\n' % \
			dir.replace(" ","\ "))

for file, link, mode in FILES:
	mode = oct(mode & 0xfff)
	if file == 'usr/local/bin/sudo':
		mode = '04555'
	if link:
		f.write('./%s type=link uname=root'
			' gname=wheel mode=%s link=%s\n' % \
			(file.replace(" ","\ "), mode, link))
	else:
		f.write('./%s type=file uname=root gname=wheel mode=%s\n' % \
			(file.replace(" ","\ "), mode))

f.close()
