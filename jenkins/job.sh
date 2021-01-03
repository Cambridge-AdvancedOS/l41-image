uname -a

export TARGET=arm64
export MAKEOBJDIRPREFIX=$WORKSPACE/obj/
export HEAD=$WORKSPACE/freebsd
export KERNCONF=GENERIC-MMCCAM
export NCPU=`sysctl -n hw.ncpu`

rm -rf tmp sdcard.img sdcard.img.gz
rm -rf rootfs
mkdir -p obj rootfs

#
# Create packages manifest
#
python2.7 $WORKSPACE/l41-image/image/packages.py || exit $?

#
# Create kernel source manifest
#
python2.7 $WORKSPACE/l41-image/image/source.py $HEAD/sys || exit $?

#
# Write the commit hash ID
#
git --git-dir $WORKSPACE/freebsd/.git rev-parse HEAD > $WORKSPACE/l41-image/image/extras/etc/freebsd_git_hash

#
# Build FreeBSD
#
cd $HEAD && \
cat $WORKSPACE/l41-image/image/patches/* | patch -p1 && \
make -j${NCPU} kernel-toolchain && \
make -j${NCPU} buildkernel && \
make -j${NCPU} buildworld || exit $?

#
# Build kernel only
#
# cd $HEAD && make -j${NCPU} buildkernel || exit $?

#
# Install FreeBSD
#
cd $HEAD && \
make -DNO_ROOT -DWITHOUT_TESTS DESTDIR=$WORKSPACE/rootfs installworld && \
make -DNO_ROOT -DWITHOUT_TESTS DESTDIR=$WORKSPACE/rootfs distribution && \
make -DNO_ROOT -DWITHOUT_TESTS DESTDIR=$WORKSPACE/rootfs installkernel || exit $?

#
# Rootfs image. 3200M
#
cd $WORKSPACE && sh $WORKSPACE/l41-image/image/makeroot.sh \
  -p $WORKSPACE/l41-image/image/extras/etc/master.passwd \
  -g $WORKSPACE/l41-image/image/extras/etc/group \
  -s 3355443200 -F 10000 \
  -e $WORKSPACE/l41-image/image/extras/extras.mtree \
  -e $WORKSPACE/tmp/pkg.mtree \
  -e $HEAD/sys/files.mtree \
  -d $WORKSPACE/rootfs.img $WORKSPACE/rootfs/ || exit $?

#
# SD card image
#
cd $WORKSPACE && \
cp $WORKSPACE/l41-image/sdcard/sdcard.img.gz $WORKSPACE/ && \
gunzip sdcard.img.gz && \
dd if=rootfs.img of=sdcard.img bs=512 seek=264280 conv=notrunc && \
gzip sdcard.img || exit $?
