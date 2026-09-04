#!/bin/sh

cat nodes-names | while read a b; do echo -n "$a "; (ssh -n root@$b 'echo -n "`hostname` "; uname -r'); done

# 1. Copy /etc/rc.conf to the /root/ first
# 2. Update /root/rc.conf
# 3. Copy it back to /etc/

# cat nodes-names | while read a b; do echo $a; (ssh -n root@$b sed -i \'\' s/raspberry-pi/$a.advopsys.cl.cam.ac.uk/ /root/rc.conf); done
