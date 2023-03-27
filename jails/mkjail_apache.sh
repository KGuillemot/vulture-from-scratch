#!/bin/sh

JAIL="apache"
TARGET="/zroot/apache"

# Copy needed files from vulture-haproxy package to apache jail
mkdir -p /zroot/apache/usr/local/sbin
mkdir -p /zroot/apache/usr/local/lib
/bin/cp -Rpf /home/jails.haproxy/.zfs-source/usr/local/sbin/haproxy /zroot/apache/usr/local/sbin/haproxy
/bin/cp -Rpf /home/jails.haproxy/.zfs-source/usr/local/lib/libslz.* /zroot/apache/usr/local/lib/
/bin/cp -Rpf /home/jails.haproxy/.zfs-source/usr/local/share/haproxy /zroot/apache/usr/local/share/

cp -rf /home/jails.apache/.zfs-source/usr/local/etc/* "${TARGET}/usr/local/etc/"
if [ ! -f ${TARGET}/usr/local/etc/apache24/extra/timeouts.conf ] ; then
    /bin/cp /home/jails.apache/.zfs-source/usr/local/etc/apache24/extra/timeouts.conf.sample ${TARGET}/usr/local/etc/apache24/extra/timeouts.conf
fi

/bin/mkdir ${TARGET}/var/db/pki

#Map Vulture-GUI to the HOST
rm -rf /home/vlt-os/env
ln -s /home/jails.apache/.zfs-source/home/vlt-os/env/ /home/vlt-os/env
ln -s /home/jails.apache/.zfs-source/home/vlt-os/vulture_os/ /home/vlt-os/vulture_os
ln -s /home/jails.apache/.zfs-source/home/vlt-os/scripts/ /home/vlt-os/scripts

touch /home/vlt-os/vulture_os/vulture_os/secret_key.py

# Map Vulture-GUI to the Apache JAIL (done via fstab below)
mkdir -p "${TARGET}/home/vlt-os"

chmod 750 /home/vlt-os/scripts/*
chmod 755 /home/vlt-os/env
chmod 755 /home/vlt-os/vulture_os
chown vlt-os:wheel /home/vlt-os/vulture_os/vulture_os/secret_key.py
chmod 600 /home/vlt-os/vulture_os/vulture_os/secret_key.py

/bin/mkdir -p /var/log/vulture/os/
/usr/sbin/chown vlt-os:wheel /var/log/vulture/os/
chmod 755 /var/log/vulture/os/

/usr/sbin/chroot ${TARGET} /bin/mkdir -p /var/log/vulture/os/
/usr/sbin/chroot ${TARGET} /bin/mkdir -p /var/log/vulture/portal/
/usr/sbin/chroot ${TARGET} chown -R vlt-os:vlt-web /var/log/vulture/
/usr/sbin/chroot ${TARGET} chmod -R 664 /var/log/vulture/*
/usr/sbin/chroot ${TARGET} find /var/log/vulture -type d -exec chmod 775 {} \;

# HAProxy conf files
/bin/mkdir -p ${TARGET}/usr/local/etc/haproxy.d
/usr/sbin/chown -R vlt-os:vlt-web ${TARGET}/usr/local/etc/haproxy.d

# Test conf HAProxy
/usr/sbin/chroot ${TARGET} /bin/mkdir -p /var/tmp/haproxy
/usr/sbin/chroot ${TARGET} chown vlt-os:vlt-web /var/tmp/haproxy
/usr/sbin/chroot ${TARGET} chmod 755 /var/tmp/haproxy

# Darwin conf files
/bin/mkdir -p ${TARGET}/home/darwin/conf
/usr/sbin/chown -R vlt-os:vlt-web ${TARGET}/home/darwin/conf

# Sockets
/bin/mkdir -p ${TARGET}/var/sockets/redis/
/bin/mkdir -p ${TARGET}/var/sockets/daemon/
/bin/mkdir -p ${TARGET}/var/sockets/gui/

/usr/sbin/chown root:vlt-web /var/sockets/gui/
chmod 770 /var/sockets/gui/

# PIDFILES
/bin/mkdir -p ${TARGET}/var/run/gui/
chown vlt-os:vlt-web ${TARGET}/var/run/gui/
chmod 755 ${TARGET}/var/run/gui/


