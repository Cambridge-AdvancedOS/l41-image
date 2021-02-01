On the node we are rescuing:
 nc -l 19000 | dd bs=4M of=/dev/mmcsd0s2a

On the server (typically mgmt1)
 dd bs=4m if=rootfs-node.img | nc 128.232.25.151 19000
