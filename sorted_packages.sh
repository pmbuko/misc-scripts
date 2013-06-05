#!/bin/bash

for log in `/bin/ls -r /var/log/install.log*`; do
    bzgrep 'Writing receipt' $log | awk '{print $1,$2,$3,$10}'
done