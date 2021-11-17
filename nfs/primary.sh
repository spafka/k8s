drbdsetup /dev/drbd0 primary --force

sleep 10

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
    interface ens33
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
       192.168.32.10
    }
    nopreempt
    notify_stop "/etc/keepalived/notify_stop.sh"
    notify_master "/etc/keepalived/notify_master.sh"
}
EOF

cat >/etc/keepalived/check_nfs.sh <<EOF
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