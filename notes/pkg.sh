#!/bin/sh

cat nodes-names | while read a b; do echo -n "$a "; (ssh -n root@$b 'setenv ASSUME_ALWAYS_YES yes && pkg'); done
