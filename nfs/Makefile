primary:
	drbdsetup /dev/drbd0 primary --force && time 3 && cat /proc/drbd
cp:
	cp nfs/conf/master-keepalived.conf /etc/keepalived/keepalived.conf && cp nfs/conf/check_nfs.sh /etc/keepalived/check_nfs.sh && cp nfs/conf/notify_stop.sh /etc/keepalived/notify_stop.sh
mk:
	mkfs.ext4 /dev/drbd0 &&  mkdir -p  /etc/keepalived/logs &&  chmod a+x /etc/keepalived/*.sh
secord:
	cp nfs/conf/slave-keepalived.conf /etc/keepalived/keepalived.conf && cp nfs/conf/notify_backup.sh /etc/keepalived/notify_backup.sh && make s2
s2:

	mkdir -p  /etc/keepalived/logs && chmod a+x /etc/keepalived/*.sh
done:
	systemctl restart keepalived

