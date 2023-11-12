#!/bin/bash

ROTFS=$PWD/unshare-container
INIT=init.sh

if [ ! -d $ROTFS ];then

    mkdir -p $ROTFS/{bin,proc}

    cd       $ROTFS/bin/
    cp       /bin/busybox .
    for P in $(./busybox --list); do ln busybox $P; done;

    cat <<EOF > $INIT
#!bin/sh
mount -t proc none /proc 
a.out
EOF

    chmod +x init.sh
fi

cd $ROTFS
sudo -b PATH=/bin unshare --fork --pid /usr/sbin/chroot . bin/init.sh
