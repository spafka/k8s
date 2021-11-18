drbdsetup /dev/drbd0 primary --force

sleep 10

export VIP=192.168.18.174
export INTERFACE=ens160

if [ -z $VIP ]; then
    red_echo "VIP"
fi
if [ -z $INTERFACE ]; then
    red_echo "$INTERFACE"
fi
cat /proc/drbd

cat <<EOF >  /etc/keepalived/keepalived.conf
global_defs {
   router_id DRBD_HA_MASTER
}

vrrp_script chk_nfs {
        script "/etc/keepalived/check_nfs.sh"
        interval 5
    }

vrrp_instance VI_1 {
    state MASTER
    interface ${INTERFACE}
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    track_script {
       chk_nfs
    }
    virtual_ipaddress {
       ${VIP}
    }
    nopreempt
    notify_stop "/etc/keepalived/notify_stop.sh"
    notify_master "/etc/keepalived/notify_master.sh"
}
EOF

cat >/etc/keepalived/check_nfs.sh <<EOF
#!/bin/bash
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
EOF

cat > /etc/keepalived/notify_stop.sh <<EOF
#!/bin/bash
set -o errexit

time=`date "+%F  %H:%M:%S"`
echo -e "$time  ------notify_stop------\n" >> /etc/keepalived/logs/notify_stop.log
systemctl stop nfs-server &>> /etc/keepalived/logs/notify_stop.log
exportfs -au &>> /etc/keepalived/logs/notify_stop.log
umount /dev/drbd0 &>> /etc/keepalived/logs/notify_stop.log
drbdsetup /dev/drbd0 secondary &>> /etc/keepalived/logs/notify_stop.log
echo -e "\n" >> /etc/keepalived/logs/notify_stop.log
EOF



mkfs.ext4 /dev/drbd0
mkdir -p  /etc/keepalived/logs
chmod a+x /etc/keepalived/*.sh