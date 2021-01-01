#!/usr/local/bin/python2.7
from commands import getstatusoutput
import sys
import os

if len(sys.argv) <= 1:
	print 'Usage: %s dir' % sys.argv[0]
	sys.exit(1)

DIR = sys.argv[1]
DIR = DIR.rstrip('/')
FILENAME = 'files.mtree'

f = open(os.path.join(DIR, FILENAME), "w")
f.write("#mtree 2.0\n")

for w in os.walk(DIR):
	p = w[0]
	rp = p.replace(DIR, './usr/src/sys')
	# print p, rp
	dirs = w[1]
	files = w[2]
	f.write('%s type=dir uname=root gname=wheel mode=0755\n' % \
			(rp))
	for file in files:
		if file == FILENAME:
			continue
		f.write('%s type=file uname=root gname=wheel mode=0644'
			' contents=%s\n' % (os.path.join(rp, file), \
			os.path.join(p, file)))
f.close()
