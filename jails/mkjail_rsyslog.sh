#!/bin/sh

JAIL="rsyslog"
TARGET="/zroot/rsyslog"

/bin/cp -rf /home/jails.rsyslog/.zfs-source/* ${TARGET}

/bin/mkdir -p ${TARGET}/usr/local/etc/rsyslog.d
/bin/mkdir -p ${TARGET}/var/sockets/rsyslog/
/bin/mkdir -p ${TARGET}/var/sockets/darwin/
/bin/mkdir -p ${TARGET}/home/vlt-os/vulture_os/services/rsyslogd/config
/bin/mkdir -p ${TARGET}/var/db/pki
/bin/mkdir -p ${TARGET}/var/log/pf
/bin/mkdir -p ${TARGET}/var/db/darwin
/bin/mkdir -p ${TARGET}/var/log/darwin
/bin/mkdir -p ${TARGET}/var/log/api_parser
/bin/mkdir -p ${TARGET}/var/db/reputation_ctx
/bin/mkdir -p /usr/local/etc/rsyslog.d/
/bin/mkdir -p /var/sockets/rsyslog/

/bin/chmod 500 ${TARGET}/usr/local/etc/rc.d/rsyslogd
/usr/sbin/chown root:wheel ${TARGET}/usr/local/etc/rc.d/rsyslogd
/usr/sbin/chown vlt-os:wheel /usr/local/etc/rsyslog.d
/usr/sbin/chown -R vlt-os:vlt-web ${TARGET}/home/vlt-os/vulture_os/services/rsyslogd/config
/usr/sbin/chown -R root:wheel ${TARGET}/var/db/darwin
/bin/chmod -R 440 ${TARGET}/var/db/darwin
/usr/sbin/chown -R root:wheel ${TARGET}/var/log/darwin
/bin/chmod 550 ${TARGET}/var/log/darwin
/usr/sbin/chown -R root:wheel ${TARGET}/var/db/reputation_ctx
/bin/chmod -R 440 ${TARGET}/var/db/reputation_ctx

