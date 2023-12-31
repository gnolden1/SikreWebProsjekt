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

    cat <<EOF > rootinit.sh
#!/bin/sh
mount -t proc none /proc 
a.out 0
EOF

cat <<EOF > nonrootinit.sh
#!/bin/sh
mount -t proc none /proc 
a.out 1
EOF

    chmod +x rootinit.sh
    chmod +x nonrootinit.sh
fi

cd $ROTFS
USER=$(whoami)
if [ $USER = root ]
then
	echo Running as root
	PATH=/bin unshare --fork --pid /usr/sbin/chroot $ROTFS bin/rootinit.sh &
else
	echo Not running as root
	PATH=/bin		\
		unshare         \
		--user          \
		--map-root-user \
		--fork          \
		--pid           \
		--mount         \
		--cgroup        \
		--ipc		\
		--uts           \
		/usr/sbin/chroot $ROTFS /bin/nonrootinit.sh &
fi
