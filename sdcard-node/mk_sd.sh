#!/bin/sh

rm -f sdcard.img.gz sdcard.img
truncate -s 4G sdcard.img
mdconfig -u0 sdcard.img || exit 1

gpart create -s MBR md0
gpart add -b 2079 -s 128m -t fat32lba md0		# msdos (firmware)
gpart add -s 3800M -t freebsd md0			# BSD labels
gpart set -a active -i 1 md0

gpart create -s BSD md0s2
gpart add -b 57 -t freebsd-ufs md0s2		# /

# Provide boot command for u-boot
newfs_msdos /dev/md0s1
mount_msdosfs /dev/md0s1 /mnt
cp -R ../firmware-rpi4-8g/* /mnt/
cp uboot.env /mnt/ || echo cant copy uboot.env
umount /mnt

mdconfig -d -u0

# Use this command in jenkins
#dd if=rootfs.img of=sdcard.img bs=512 seek=264280 conv=notrunc
