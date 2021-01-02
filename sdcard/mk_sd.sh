#!/bin/sh

rm -f sdcard.img.gz sdcard.img
truncate -s 6000M sdcard.img
mdconfig -u0 sdcard.img || exit 1

gpart create -s MBR md0
gpart add -s 128m -t '!4' md0		# msdos (firmware)
gpart add -s 4G -t freebsd md0		# /
gpart add -t freebsd md0		# BSD labels
gpart set -a active -i 1 md0

gpart create -s BSD md0s3
gpart add -s 200m -t freebsd-ufs md0s3	# /data
gpart add -t freebsd-ufs md0s3		# /benchmarks

newfs -j /dev/md0s3a			# /data
newfs -j /dev/md0s3b			# /benchmarks

# guest home directory
mount /dev/md0s3a /mnt
mkdir /mnt/.ssh
chmod 0755 /mnt
chmod 0700 /mnt/.ssh
chown -R 1001:31 /mnt			# guest:guest
umount /mnt

# Provide boot command for u-boot
newfs_msdos /dev/md0s1
mount_msdosfs /dev/md0s1 /mnt
cp -R ../firmware-rpi4-8g/* /mnt/
cp uboot.env /mnt/ || echo cant copy uboot.env
umount /mnt

mdconfig -d -u0
gzip sdcard.img

# Use this command in jenkins
#dd if=rootfs.img of=sdcard.img bs=512 seek=262207 conv=notrunc
