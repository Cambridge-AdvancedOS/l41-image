#!/bin/sh

rm -f sdcard.img.gz sdcard.img
truncate -s 4G sdcard.img
mdconfig -u0 sdcard.img || exit 1

gpart create -s MBR md0
gpart add -s 128m -t fat32lba md0	# msdos (firmware)
gpart add -s 3200m -t freebsd md0	# /
gpart set -a active -i 1 md0

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
