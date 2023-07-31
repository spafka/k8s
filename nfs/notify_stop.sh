#!/bin/bash
set -o errexit
   
time=`date "+%F  %H:%M:%S"`
echo -e "$time  ------notify_stop------\n" >> /etc/keepalived/logs/notify_stop.log
systemctl stop nfs-server &>> /etc/keepalived/logs/notify_stop.log
exportfs -au &>> /etc/keepalived/logs/notify_stop.log
umount /dev/drbd0 &>> /etc/keepalived/logs/notify_stop.log
drbdsetup /dev/drbd0 secondary &>> /etc/keepalived/logs/notify_stop.log
echo -e "\n" >> /etc/keepalived/logs/notify_stop.log
