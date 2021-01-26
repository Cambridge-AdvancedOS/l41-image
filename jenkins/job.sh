set -xe
uname -a

export TARGET=arm64
export MAKEOBJDIRPREFIX=$WORKSPACE/obj/
export HEAD=$WORKSPACE/freebsd
export KERNCONF=GENERIC-MMCCAM
export NCPU=`sysctl -n hw.ncpu`

rm -rf tmp *.img *img.gz
rm -rf rootfs
#rm -rf obj
mkdir -p obj rootfs

#
# Local distfiles
#
mkdir -p $WORKSPACE/distfiles
cp $WORKSPACE/l41-image/image/distfiles/* $WORKSPACE/distfiles/

#
# Create packages manifests
#
python2.7 $WORKSPACE/l41-image/image/packages.py $WORKSPACE/l41-image/image/packages-node node.mtree || exit $?
python2.7 $WORKSPACE/l41-image/image/packages.py $WORKSPACE/l41-image/image/packages-mgmt mgmt.mtree || exit $?

#
# Create kernel source manifest
#
python2.7 $WORKSPACE/l41-image/image/source.py $HEAD/sys || exit $?

#
# Write the commit hash ID
#
git --git-dir $WORKSPACE/freebsd/.git rev-parse HEAD > $WORKSPACE/l41-image/image/extras/etc/freebsd_git_hash

#
# Patch FreeBSD
#
#cd $HEAD && \
#cat $WORKSPACE/l41-image/image/patches/* | patch -p1 || exit $?

#
# Build FreeBSD
#
#cd $HEAD && \
#make -j${NCPU} kernel-toolchain && \
#make -j${NCPU} buildkernel && \
#make -j${NCPU} buildworld || exit $?

#
# Build kernel only
#
#cd $HEAD && make -j${NCPU} buildkernel || exit $?

#
# Install FreeBSD
#
cd $HEAD && \
make -DNO_ROOT -DWITHOUT_TESTS DESTDIR=$WORKSPACE/rootfs installworld && \
make -DNO_ROOT -DWITHOUT_TESTS DESTDIR=$WORKSPACE/rootfs distribution && \
make -DNO_ROOT -DWITHOUT_TESTS DESTDIR=$WORKSPACE/rootfs installkernel || exit $?

#
# Create swap file
#
truncate -s 8G $WORKSPACE/l41-image/image/extras/usr/swap0

#
# Rootfs node image. 14GB, including 8GB swap
#
cd $WORKSPACE && sh $WORKSPACE/l41-image/image/makeroot.sh \
  -p $WORKSPACE/l41-image/image/extras/etc/master.passwd \
  -g $WORKSPACE/l41-image/image/extras/etc/group \
  -s 15032385536 -F 10000 \
  -e $WORKSPACE/l41-image/image/extras/extras.mtree \
  -e $WORKSPACE/l41-image/image/extras-node/extras.mtree \
  -e $WORKSPACE/tmp/node.mtree \
  -e $HEAD/sys/files.mtree \
  -d $WORKSPACE/rootfs-node.img $WORKSPACE/rootfs/ || exit $?

#
# Rootfs mgmt1 image. 14GB, including 8GB swap
#
cd $WORKSPACE && sh $WORKSPACE/l41-image/image/makeroot.sh \
  -p $WORKSPACE/l41-image/image/extras/etc/master.passwd \
  -g $WORKSPACE/l41-image/image/extras/etc/group \
  -s 15032385536 -F 10000 \
  -e $WORKSPACE/l41-image/image/extras/extras.mtree \
  -e $WORKSPACE/l41-image/image/extras-mgmt/extras.mtree \
  -e $WORKSPACE/l41-image/image/extras-mgmt1/extras.mtree \
  -e $WORKSPACE/tmp/mgmt.mtree \
  -e $HEAD/sys/files.mtree \
  -d $WORKSPACE/rootfs-mgmt1.img $WORKSPACE/rootfs/ || exit $?

#
# Rootfs mgmt2 image. 14GB, including 8GB swap
#
cd $WORKSPACE && sh $WORKSPACE/l41-image/image/makeroot.sh \
  -p $WORKSPACE/l41-image/image/extras/etc/master.passwd \
  -g $WORKSPACE/l41-image/image/extras/etc/group \
  -s 15032385536 -F 10000 \
  -e $WORKSPACE/l41-image/image/extras/extras.mtree \
  -e $WORKSPACE/l41-image/image/extras-mgmt/extras.mtree \
  -e $WORKSPACE/l41-image/image/extras-mgmt2/extras.mtree \
  -e $WORKSPACE/tmp/mgmt.mtree \
  -e $HEAD/sys/files.mtree \
  -d $WORKSPACE/rootfs-mgmt2.img $WORKSPACE/rootfs/ || exit $?

#
# SD card node image
#
cd $WORKSPACE && \
cp $WORKSPACE/l41-image/sdcard-node/sdcard.img.gz $WORKSPACE/sdcard-node.img.gz && \
gunzip sdcard-node.img.gz && \
dd if=rootfs-node.img of=sdcard-node.img bs=512 seek=264280 conv=notrunc && \
gzip sdcard-node.img || exit $?

#
# SD card mgmt1 image
#
cd $WORKSPACE && \
cp $WORKSPACE/l41-image/sdcard-mgmt/sdcard.img.gz $WORKSPACE/sdcard-mgmt1.img.gz && \
gunzip sdcard-mgmt1.img.gz && \
dd if=rootfs-mgmt1.img of=sdcard-mgmt1.img bs=512 seek=264280 conv=notrunc && \
gzip sdcard-mgmt1.img || exit $?

#
# SD card mgmt2 image
#
cd $WORKSPACE && \
cp $WORKSPACE/l41-image/sdcard-mgmt/sdcard.img.gz $WORKSPACE/sdcard-mgmt2.img.gz && \
gunzip sdcard-mgmt2.img.gz && \
dd if=rootfs-mgmt2.img of=sdcard-mgmt2.img bs=512 seek=264280 conv=notrunc && \
gzip sdcard-mgmt2.img || exit $?

#
# Optional artifact
#
#gzip $WORKSPACE/rootfs-node.img
#gzip $WORKSPACE/rootfs-mgmt1.img
#gzip $WORKSPACE/rootfs-mgmt2.img
