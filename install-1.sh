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

echo -n "Fetching base system files (please wait)...: "
/usr/bin/fetch http://hbsd.vultureproject.org/13-stable/amd64/amd64/BUILD-LATEST/MANIFEST -o /tmp/MANIFEST > /dev/null 2> /dev/null
if [ -f "/tmp/base.txz" ]; then
	echo -e "${Yellow}Skip (base.txz found in /tmp)${Color_Off}"
else
    /usr/bin/fetch http://hbsd.vultureproject.org/13-stable/amd64/amd64/BUILD-LATEST/base.txz -o /tmp/base.txz > /dev/null 2> /dev/null
    echo -e "${Green}Ok${Color_Off}"
fi
echo -n "Verifying checksums (please wait)...: "
expected_sha256_base=`/usr/bin/grep base.txz /tmp/MANIFEST | /usr/bin/awk '{print $2}'`
sha256_base=`/sbin/sha256sum /tmp/base.txz | /usr/bin/awk '{print $1}'`
if [ "$expected_sha256_base" != "$sha256_base" ]; then
    echo "${Red}Error: invalid checksum for base.txz ! ${Color_Off}"
    exit
fi
echo -e "${Green}Ok${Color_Off}"

echo "Building ZFS filesystem: "

# Vulture needs to have a /zroot mount point, so be sure it exists
if [ "${zpool}" != "zroot" ]; then
    if [ ! -L "/zroot" ] && [ ! -f "/zroot" ]; then 
        /bin/ln -s /${zpool} /zroot
    fi
fi
make_zpool ${zpool} 

echo -n "Creating vulture directory structure... "
# Vulture specific directories
if [ -d /.jail_system ]; then
    chflags -R noschg /.jail_system 
    rm -rf /.jail_system
fi
rm -rf /etc/hbsd-update*.conf
rm -rf /usr/share/keys/hbsd-update/trusted/*
mkdir -p /home/darwin/conf /home/jails.apache/.zfs-source/home/vlt-os/vulture_os/services/rsyslogd/config \
	/usr/local/etc/haproxy.d /usr/local/etc/redis \
	/usr/local/etc/rsyslog.d /var/db/darwin /var/db/pki \
	/var/db/reputation_ctx /var/log/api_parser /var/log/darwin \
	/var/log/pf /var/sockets/daemon /var/sockets/darwin /var/sockets/gui \
	/var/sockets/redis /var/sockets/rsyslog 
echo -e "${Green}Ok${Color_Off}"

# Install packages on base system
echo -n " [hbsd-update setup] : "
mkdir -p /usr/share/keys/hbsd-update/trusted/
/usr/bin/fetch http://hbsd.vultureproject.org/ca.vultureproject.org -o /usr/share/keys/hbsd-update/trusted/ca.vultureproject.org > /dev/null 2> /dev/null
/usr/bin/fetch http://hbsd.vultureproject.org/hbsd-update-current.conf -o /etc/hbsd-update.conf > /dev/null 2> /dev/null
echo -e "${Green}Ok${Color_Off}"

echo -n " [pkg setup] : "
/usr/bin/fetch http://pkg.vultureproject.org/pkg.vultureproject.org -o /usr/share/keys/pkg/trusted/pkg.vultureproject.org > /dev/null 2> /dev/null
rm -rf /etc/pkg/* && fetch http://pkg.vultureproject.org/Vulture.conf -o /etc/pkg/ > /dev/null 2> /dev/null
env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg bootstrap -y > /dev/null 2> /dev/null
rm -rf /etc/pkg/* && /usr/bin/fetch http://pkg.vultureproject.org/Vulture.conf -o /etc/pkg/ > /dev/null 2> /dev/null
echo -e "${Green}Ok${Color_Off}"

mkdir -p /.jail_system
echo -n "Decompressing base.txz into jail_system... "
tar xf /tmp/base.txz -C /.jail_system/
echo -e "${Green}Ok${Color_Off}"

echo "System configuration: "

echo " [sysrc] : "
/usr/sbin/sysrc sshd_enable="YES"
/usr/sbin/sysrc ntpd_enable="YES"
/usr/sbin/sysrc ntpd_sync_on_start="YES"
/usr/sbin/sysrc local_unbound_enable="NO"
/usr/sbin/sysrc syslogd_enable="NO"
/usr/sbin/sysrc sendmail_enable="NO"
/usr/sbin/sysrc sendmail_submit_enable="NO"
/usr/sbin/sysrc sendmail_outbound_enable="NO"
/usr/sbin/sysrc sendmail_msp_queue_enable="NO"
/usr/sbin/sysrc cloudinit_enable="YES"

cp config/rc.conf.local /etc/rc.conf.local
cp config/rc.conf.network /etc/rc.conf.d/network
cp config/loader.conf /boot/loader.conf
cp config/sshd_config /etc/ssh/sshd_config
cp config/jail.conf /etc/

# Enable services
for _rcvar in ${VM_RC_LIST}; do
    /usr/sbin/sysrc -f /etc/rc.conf.d/${_rcvar} ${_rcvar}_enable="YES"
done
echo -e "${Green}Ok${Color_Off}"

echo -n " [pkg install] : "
env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg install -y ${VM_EXTRA_PACKAGES}
echo -e "${Green}Ok${Color_Off}"

echo -n " [pkg cleanup] : "
env ASSUME_ALWAYS_YES=yes /usr/local/sbin/pkg clean -y -a
echo -e "${Green}Ok${Color_Off}"

# Configure repository for jail base image
# FIXME: arch / current / dev
cp /etc/pkg/Vulture.conf /.jail_system/etc/pkg/
cp /usr/share/keys/pkg/trusted/pkg.vultureproject.org /.jail_system/usr/share/keys/pkg/trusted/

# Installing Vulture packages...
echo "Vulture installation : "
for vltpkg in ${VM_VULTURE_PACKAGES}; do
	echo -n " [${vltpkg}] : "
	env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg install -y ${vltpkg}
	echo -e "${Green}Ok${Color_Off}"
done

/bin/cp -f /etc/motd /etc/motd.template

# Build jails
cur=`pwd`
cp ./jails/configure_jail_hosts.sh /tmp/
cp ./jails/mkjail_*.sh /tmp/
for jail in haproxy mongodb redis apache portal rsyslog; do
    echo " [ ${jail} jail setup ] : "
    echo -n "    - Creating directory stucture... "
    mkdir -p /zroot/${jail} && cd /zroot/${jail}
    mkdir -p .jail_system && mount -t nullfs /.jail_system /zroot/${jail}/.jail_system
    mkdir -p home root etc/rc.conf.d usr/local/etc/rc.d var/tmp var/run tmp

    ln -s .jail_system/rescue rescue
    ln -s .jail_system/lib lib
    ln -s .jail_system/bin bin
    ln -s .jail_system/libexec libexec
    ln -s .jail_system/sbin sbin
    cd usr
    ln -s ../.jail_system/usr/libdata ./libdata
    ln -s ../.jail_system/usr/libexec ./libexec
    ln -s ../.jail_system/usr/share ./share
    ln -s ../.jail_system/usr/lib ./lib
    ln -s ../.jail_system/usr/sbin ./sbin
    ln -s ../.jail_system/usr/include ./include
    ln -s ../.jail_system/usr/bin ./bin
    cd ../etc/
    ln -s ../.jail_system/etc/defaults ./defaults
    ln -s ../.jail_system/etc/newsyslog.conf ./newsyslog.conf
    ln -s ../.jail_system/etc/mail ./mail
    ln -s ../.jail_system/etc/syslog.conf ./syslog.conf
    ln -s ../.jail_system/etc/rc ./rc
    ln -s ../.jail_system/etc/rc.d ./rc.d
    ln -s ../.jail_system/etc/pkg ./pkg
    ln -s ../.jail_system/etc/mtree ./mtree
    ln -s ../.jail_system/etc/rc.subr ./rc.subr
    ln -s ../.jail_system/etc/network.subr ./network.subr
    ln -s ../.jail_system/etc/rc.shutdown ./rc.shutdown

    mkdir -p /zroot/${jail}/dev
    echo -e "${Green}Ok${Color_Off}"

    echo -n "    - Configuring system... "
    # Synchronize groups and users between host and jail
    for i in /etc/passwd /etc/group /etc/master.passwd /etc/login.conf /etc/pam.d; do
        /bin/cp -rf ${i} /zroot/${jail}/etc/
    done
    chroot /zroot/${jail} /usr/sbin/pwd_mkdb -p /etc/master.passwd

    # Set startup config - ALL JAILS
    chroot /zroot/${jail} /usr/sbin/sysrc -f /etc/rc.conf.d/syslogd syslogd_enable="NO"  > /dev/null 2> /dev/null
    chroot /zroot/${jail} /usr/sbin/sysrc -f /etc/rc.conf.d/sendmail sendmail_enable="NO" > /dev/null 2> /dev/null
    chroot /zroot/${jail} /usr/sbin/sysrc -f /etc/rc.conf.d/sendmail sendmail_submit_enable="NO" > /dev/null 2> /dev/null
    chroot /zroot/${jail} /usr/sbin/sysrc -f /etc/rc.conf.d/sendmail sendmail_outbound_enable="NO" > /dev/null 2> /dev/null
    chroot /zroot/${jail} /usr/sbin/sysrc -f /etc/rc.conf.d/sendmail sendmail_msp_queue_enable="NO" > /dev/null 2> /dev/null
    chroot /zroot/${jail} /usr/sbin/sysrc -f /etc/rc.conf.d/secadm secadm_enable="YES" > /dev/null 2> /dev/null
    
    # Set startup config - JAILS SPECIFIC
    sysrc_list="VM_RC_LIST_"${jail}
    for _rcvar in `eval echo \\$$sysrc_list`; do
        /usr/sbin/sysrc -f /zroot/${jail}/etc/rc.conf.d/${_rcvar} ${_rcvar}_enable="YES" > /dev/null 2> /dev/null
    done

    sysrc_options="VM_RC_LIST_"${jail}_options
    for _option in `eval echo \\$$sysrc_options`; do
	file=`echo ${_option} | sed -e 's/_.*//'`
        /usr/sbin/sysrc -f /zroot/${jail}/etc/rc.conf.d/${file} ${_option} > /dev/null 2> /dev/null
    done

    echo "nameserver ${jail}" > /zroot/${jail}/etc/resolv.conf
    echo -e "${Green}Ok${Color_Off}"

    # This needs to be done when jail is stopped
    /bin/sh /tmp/configure_jail_hosts.sh ${jail}
    umount /zroot/${jail}/.jail_system
    echo -e "${Green}Ok${Color_Off}"

done

echo -n "Jails post-configuration... "
# Create directories for nullfs mountpoints
cd ${cur}
for rep in `/bin/cat config/fstab | grep nullfs | sed -E 's/^.* (.*) nullfs.*/\1/'`; do
    mkdir -p ${rep}
done
echo -e "${Green}Ok${Color_Off}"

# Routing config
cat << EOF > /etc/rc.conf.d/routing
gateway_enable="YES"
ipv6_gateway_enable="YES"
#static_routes="net1 net2"
#route_net1="-net 192.168.0.0/24 192.168.0.1"
#route_net2="-net 192.168.1.0/24 192.168.1.1"
EOF

# Add jails mountpoints to fstab
cat config/fstab >> /etc/fstab

echo -e "${Green}PLEASE REBOOT THE SYSTEM NOW, then launch install-2.sh.${Color_Off}"

