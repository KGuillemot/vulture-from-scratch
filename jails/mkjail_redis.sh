#!/bin/sh

JAIL="redis"
TARGET="/zroot/redis"

# Retrieve management IP address
management_ip="$(/usr/sbin/sysrc -f /etc/rc.conf.d/network -n management_ip 2> /dev/null)"

# Ip no management IP - exit
if [ -z "$management_ip" ] ; then
    /bin/echo "Management IP address is null - please select 'Management' and retry."
    exit 1
fi

/bin/mkdir -p ${TARGET}/usr/local/etc/redis
/bin/mkdir -p ${TARGET}/var/sockets/redis/

/bin/mkdir -p ${TARGET}/var/db/vulture-redis/
chown redis:redis ${TARGET}/var/db/vulture-redis/
chmod 750 ${TARGET}/var/db/vulture-redis/

/bin/mkdir -p ${TARGET}/var/run/redis/
chown redis:redis ${TARGET}/var/run/redis/
chmod 750 ${TARGET}/var/run/redis/

/bin/cat /usr/local/etc/redis/templates/redis.tpl | /usr/bin/sed "s/{{ management_ip }}/${management_ip}/" > /usr/local/etc/redis/redis.conf
/bin/cat /usr/local/etc/redis/templates/sentinel.tpl | /usr/bin/sed "s/{{ management_ip }}/${management_ip}/" > /usr/local/etc/redis/sentinel.conf
/usr/sbin/chown -R redis:vlt-conf /usr/local/etc/redis/

/usr/bin/touch ${TARGET}/var/log/redis.log
/usr/sbin/chown root:redis ${TARGET}/var/log/redis.log
/bin/chmod 660 ${TARGET}/var/log/redis.log

/usr/bin/touch ${TARGET}/var/log/sentinel.log
/usr/sbin/chown root:redis ${TARGET}/var/log/sentinel.log
/bin/chmod 660 ${TARGET}/var/log/sentinel.log

