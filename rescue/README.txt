How to rescue a node.

On the node we are rescuing:
 nc -l 19000 | dd bs=4M of=/dev/mmcsd0s2a

On the server (typically mgmt1)
 dd bs=4m if=rootfs-node.img | nc 128.232.25.151 19000

-----

How to update basic.files.

Do the Jenkins build, then download full build log consoleText.

Check which files in basic.files are outdated:

# for file in $(cat basic.files); do if ! grep $(basename $file) ~/consoleText > /dev/null; then echo $file; fi; done
