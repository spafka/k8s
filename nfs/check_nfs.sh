systemctl status nfs-server > /dev/null 2>&1
if [ $? -ne 0 ];then
    systemctl restart nfs-server > /dev/null 2>&1
    systemctl status nfs-server > /dev/null 2>&1
    if [ $? -ne 0 ];then
        umount /dev/drbd0
        drbdadm secondary r0
        systemctl stop keepalived
    fi
fi
