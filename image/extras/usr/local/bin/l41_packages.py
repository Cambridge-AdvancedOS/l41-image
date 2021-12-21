#!/usr/local/bin/python
import subprocess
import os, sys
import time

print("hello world")

filename = '/etc/l41_pkgs_installed'

def daemonize():
	# Fork once
	if os.fork() != 0:
		os._exit(0)
	# Create new session
	os.setsid()
	if os.fork() != 0:
		os._exit(0)
	os.chdir("/tmp")
	fd = os.open('/dev/null', os.O_RDONLY)
	os.dup2(fd, sys.__stdin__.fileno())
	os.close(fd)
	fd = os.open("/var/log/l41_packages.log",
		os.O_WRONLY | os.O_CREAT | os.O_APPEND)
	os.dup2(fd, sys.__stdout__.fileno())
	os.dup2(fd, sys.__stderr__.fileno())
	os.close(fd)
	f = open("/var/run/l41_packages.pid", 'w')
	f.write(str(os.getpid()) + '\n')
	f.close()

	main()

def main():
	print("Starting. Checking files...")
	files = os.listdir("/distfiles")
	for file in files:
		print("Checking if %s installed" % file)
		cmd = "pkg info %s" % file.rstrip(".txz")
		error, output = subprocess.getstatusoutput(cmd)
		if (error != 0):
			print("Installing %s" % file)
			cmd = "pkg install -y /distfiles/%s" % file
			error, output = subprocess.getstatusoutput(cmd)
			print(output)
			if (error != 0):
				print("Can't install %s, error %d" % \
				    (file, error))
				sys.exit(1)

	f = open(filename, "w")
	f.write("error %d" % error)
	f.close()

if __name__ == '__main__':
	if os.path.exists(filename):
		sys.exit(0)
	daemonize()
