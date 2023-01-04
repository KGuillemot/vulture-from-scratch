#!/bin/sh

JAIL="portal"
TARGET="/zroot/portal"

chown -R vlt-os:wheel /home/jails.apache/.zfs-source/home/vlt-os/
chmod 750 /home/jails.apache/.zfs-source/home/vlt-os/env
chmod 750 /home/jails.apache/.zfs-source/home/vlt-os/bootstrap
chmod 550 /home/jails.apache/.zfs-source/home/vlt-os/bootstrap/*
chmod 750 /home/jails.apache/.zfs-source/home/vlt-os/scripts
chmod 550 /home/jails.apache/.zfs-source/home/vlt-os/scripts/*
chmod 750 /home/jails.apache/.zfs-source/home/vlt-os/vulture_os

cp -rf /home/jails.portal/.zfs-source/usr/local/etc/* "${TARGET}/usr/local/etc/"

/bin/mkdir ${TARGET}/var/db/pki

#Map Portal to the HOST
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
chown vlt-os:wheel /var/log/vulture/os/
chmod 755 /var/log/vulture/os/

/usr/sbin/chroot ${TARGET} /bin/mkdir -p /var/log/vulture/os/
/usr/sbin/chroot ${TARGET} /bin/mkdir -p /var/log/vulture/portal/
/usr/sbin/chroot ${TARGET} chown -R vlt-os:vlt-web /var/log/vulture/
/usr/sbin/chroot ${TARGET} chmod -R 664 /var/log/vulture/*
/usr/sbin/chroot ${TARGET} find /var/log/vulture -type d -exec chmod 775 {} \;

# Test conf HAProxy
/usr/sbin/chroot ${TARGET} /bin/mkdir -p /var/tmp/haproxy
/usr/sbin/chroot ${TARGET} chown vlt-os:vlt-web /var/tmp/haproxy
/usr/sbin/chroot ${TARGET} chmod 755 /var/tmp/haproxy

# Redis socket
/bin/mkdir -p ${TARGET}/var/sockets/redis/

# PIDFILES
/bin/mkdir -p ${TARGET}/var/run/gui/
chown vlt-os:vlt-web ${TARGET}/var/run/gui/
chmod 755 ${TARGET}/var/run/gui/
