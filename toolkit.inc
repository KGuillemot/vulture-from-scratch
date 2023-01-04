#!/bin/sh

set -e

Color_Off='\033[0m'
Green='\033[0;32m'
Red='\033[31m'
Yellow='\033[;33m'
White='\033[0;37m'

make_zpool() {
    zpool=$1

    # This will return 1 in case of non-existing zpool
    zpool status ${zpool} > /dev/null 2> /dev/null || echo -e "${Red}Error: zpool \"${zpool}\" does not exist !${Color_Off}"

    for jail in haproxy mongodb redis apache portal rsyslog; do
        echo -n " - ${jail} 	: "
        # Skip if mountpoint is already present
	if [ -d /zroot/${jail} ]; then
	    echo -e "${Yellow}Skip - mountpoint exists${Color_Off}"
	    continue
	fi
        zfs create -o atime=off -o mountpoint=/zroot/${jail} ${zpool}/${jail}
        zfs create -o atime=off -o compress=on -o mountpoint=/zroot/${jail}/usr ${zpool}/${jail}/usr
        zfs create -o atime=off -o compress=on -o mountpoint=/zroot/${jail}/var ${zpool}/${jail}/var
        zfs create -o atime=off -o compress=off -o mountpoint=/zroot/${jail}/var/db ${zpool}/${jail}/var/db
        zfs create -o atime=off -o compress=off -o mountpoint=/zroot/${jail}/var/log ${zpool}/${jail}/var/log
	echo -e "${Green}Ok${Color_Off}"
    done
    
    return 0
}

