cat node-names | while read a b; do echo $a; (ssh -n root@$b sed -i \'\' s/raspberry-pi/$a/ rc.conf); done

# cat nodes-names | while read a b; do echo -n "$a "; (ssh -n root@$b hostname); done

# cat nodes-names | while read a b; do echo $a; (ssh -n root@$b truncate -s 8g /usr/swap0); done
