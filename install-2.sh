#!/bin/sh

set -e
. toolkit.inc

conf=${1}
if [ ! -f "${conf}" ]; then
   echo "Missing configuration file."
   exit
fi

. ${conf}

Color_Off='\033[0m'
Green='\033[0;32m'
Red='\033[31m'
Yellow='\033[;33m'
White='\033[0;37m'

zpool="${2:-vulture}"

echo "WARNING: You are about to turn this *BSD system into a VultureOS system !"
echo "Installation will be done with the following configuration:"
echo -e "${Yellow}- CONFIG = ${conf} ${Color_Off}"
echo -e "${Yellow}- zpool  = ${zpool} ${Color_Off}"
echo ""
echo "Press CTRL+C to abort or ENTER if you want to continue..."
read a

# Build jails
cur=`pwd`
cp ./jails/configure_jail_hosts.sh /tmp/
cp ./jails/mkjail_*.sh /tmp/
for jail in haproxy mongodb redis apache portal rsyslog; do

    # Install packages into jails
    pkg_list="VM_EXTRA_PACKAGES_"${jail}
    echo "Installing packages in jail ${jail}" 
    /usr/bin/env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg -j ${jail} install -y `eval echo \\$$pkg_list`
    /usr/bin/env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg -j ${jail} clean -y -a
    echo -e "${Green}Ok${Color_Off}"

    # This need to be done when jail is stopped
    service jail stop ${jail}
    /bin/sh /tmp/configure_jail_hosts.sh ${jail}
    service jail start ${jail}
    echo -e "${Green}Ok${Color_Off}"

done

echo "Syncing disk..."
sync

echo -e "${Green}Installation complete ! PLEASE REBOOT THE SYSTEM NOW.${Color_Off}"

