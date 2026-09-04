#!/bin/sh

cat nodes-names | while read a b; do echo $a; (ssh -n root@$b truncate -s 8g /usr/swap0); done
