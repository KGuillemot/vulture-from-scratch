#!/bin/sh

JAIL="haproxy"
TARGET="/zroot/haproxy"

/bin/cp -r /home/jails.haproxy/.zfs-source/* ${TARGET}/

/bin/mkdir ${TARGET}/var/db/pki

/bin/mkdir -p /usr/local/etc/haproxy.d/templates
/usr/sbin/chown -R vlt-os:vlt-web /usr/local/etc/haproxy.d

/bin/mkdir -p /var/tmp/haproxy/
/usr/sbin/chown -R vlt-os:vlt-web /var/tmp/haproxy/
/usr/sbin/chown -R vlt-os:vlt-web ${TARGET}/var/tmp/haproxy/

/usr/sbin/chown root:wheel ${TARGET}/usr/local/etc/rc.d/haproxy
/bin/chmod 500 ${TARGET}/usr/local/etc/rc.d/haproxy
/usr/sbin/chown -R vlt-os:vlt-web ${TARGET}/usr/local/etc/haproxy.d

/bin/mkdir -p ${TARGET}/var/sockets/rsyslog
/bin/mkdir -p ${TARGET}/var/sockets/haproxy
/bin/mkdir -p ${TARGET}/home/darwin/spoa

/bin/mkdir -p ${TARGET}/var/sockets/darwin
/usr/sbin/chown -R darwin:vlt-web ${TARGET}/var/sockets/darwin
/bin/chmod 750 ${TARGET}/var/sockets/darwin

