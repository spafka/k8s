#!/bin/bash
 
set -o errexit
   
time=`date "+%F  %H:%M:%S"`
echo -e "$time    ------notify_backup------\n" >> /etc/keepalived/logs/notify_backup.log
systemctl stop nfs-server &>> /etc/keepalived/logs/notify_backup.log
exportfs -au &>> /etc/keepalived/logs/notify_backup.log
umount /dev/drbd0 &>> /etc/keepalived/logs/notify_backup.log
drbdsetup /dev/drbd0 secondary &>> /etc/keepalived/logs/notify_backup.log
echo -e "\n" >> /etc/keepalived/logs/notify_backup.log
