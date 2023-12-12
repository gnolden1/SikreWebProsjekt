#!/bin/bash

for id in $(ps aux | grep init.sh | tr -s " " | cut -d " " -f 2); do kill -9 $id; done
umount unshare-container/proc
rm -r unshare-container/
