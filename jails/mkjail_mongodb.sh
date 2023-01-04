#!/bin/sh

JAIL="mongodb"
TARGET="/zroot/mongodb"

/bin/cp /home/jails.mongodb/config/mongodb.conf ${TARGET}/usr/local/etc/
/bin/cp -rf /home/jails.mongodb/.zfs-source/usr/local/etc/* "${TARGET}/usr/local/etc/"

/bin/mkdir ${TARGET}/var/db/pki
/bin/mkdir -p ${TARGET}/var/sockets/mongodb/
/usr/bin/touch ${TARGET}/var/log/mongodb.log
/usr/sbin/chown mongodb:mongodb ${TARGET}/var/log/mongodb.log
/bin/chmod 640 ${TARGET}/var/log/mongodb.log

/bin/mkdir -p /var/sockets/mongodb/
/usr/sbin/chown root:mongodb /var/sockets/mongodb/
/bin/chmod 770 /var/sockets/mongodb/


