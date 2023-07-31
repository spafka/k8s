
#!/bin/bash
set -o errexit
   
time=`date "+%F  %H:%M:%S"`
echo -e "$time    ------notify_master------\n" >> /etc/keepalived/logs/notify_master.log
drbdsetup /dev/drbd0 primary &>> /etc/keepalived/logs/notify_master.log
mount /dev/drbd0 /nfs &>> /etc/keepalived/logs/notify_master.log
systemctl restart nfs-server &>> /etc/keepalived/logs/notify_master.log
exportfs -a &>> /etc/keepalived/logs/notify_master.log
echo -e "\n" >> /etc/keepalived/logs/notify_master.log
