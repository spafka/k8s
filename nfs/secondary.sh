
if [ -z $VIP ]; then
    red_echo "VIP"
fi

if [ -z $INTERFACE ]; then
    red_echo "$INTERFACE"
fi

cat > /etc/keepalived/keepalived.conf <<EOF
global_defs {
   router_id DRBD_HA_BACKUP
}

vrrp_instance VI_1 {
    state BACKUP
    interface ${INTERFACE}
    virtual_router_id 51
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }

   nopreempt
   notify_master "/etc/keepalived/notify_master.sh"
   notify_backup "/etc/keepalived/notify_backup.sh"
    virtual_ipaddress {
        ${VIP}
    }
}
EOF

cat >/etc/keepalived/notify_backup.sh  <<EOF
#!/bin/bash

set -o errexit

time=`date "+%F  %H:%M:%S"`
echo -e "$time    ------notify_backup------\n" >> /etc/keepalived/logs/notify_backup.log
systemctl stop nfs-server &>> /etc/keepalived/logs/notify_backup.log
exportfs -au &>> /etc/keepalived/logs/notify_backup.log
umount /dev/drbd0 &>> /etc/keepalived/logs/notify_backup.log
drbdsetup /dev/drbd0 secondary &>> /etc/keepalived/logs/notify_backup.log
echo -e "\n" >> /etc/keepalived/logs/notify_backup.log
EOF


cat > /etc/keepalived/notify_master.sh <<EOF
#!/bin/bash

set -o errexit

time=`date "+%F  %H:%M:%S"`
echo -e "$time    ------notify_master------\n" >> /etc/keepalived/logs/notify_master.log
drbdsetup /dev/drbd0 primary &>> /etc/keepalived/logs/notify_master.log
mount /dev/drbd0 /nfs &>> /etc/keepalived/logs/notify_master.log
systemctl restart nfs-server &>> /etc/keepalived/logs/notify_master.log
exportfs -a &>> /etc/keepalived/logs/notify_master.log
echo -e "\n" >> /etc/keepalived/logs/notify_master.log
EOF


mkdir -p  /etc/keepalived/logs
chmod a+x /etc/keepalived/*.sh