#!/bin/bash

ROTFS=$PWD/unshare-container
INIT=init.sh

if [ ! -d $ROTFS ]
then

    mkdir $ROTFS
    mkdir $ROTFS/bin
    mkdir $ROTFS/etc
    mkdir $ROTFS/proc
    mkdir $ROTFS/var
    mkdir $ROTFS/var/log
    mkdir $ROTFS/var/www

    cp /etc/mime.types $ROTFS/etc/
    cp mp2files/server.c $ROTFS/bin/
    cp mp2files/www/* $ROTFS/var/www/
    cp mp2files/dtd/* $ROTFS/var/www/
    touch $ROTFS/var/log/debug.log

    cd       $ROTFS/bin/
    gcc server.c -static
    cp       /bin/busybox .
    for P in $(./busybox --list); do ln busybox $P; done;

    cat <<EOF > $INIT
#!/bin/sh
mount -t proc none /proc 
a.out
EOF

    chmod +x init.sh
fi

cd $ROTFS
sudo -b PATH=/bin unshare --fork --pid /usr/sbin/chroot . bin/init.sh
