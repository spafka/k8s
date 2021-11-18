NGINX_VIP=192.168.18.77/24
INTERFACE=ens160
init:
	cd /root && tar -zxvf keepalived.tgz && cd tools/shell/ && bash docker.sh && bash docker.sh && bash keepalived_install.sh

install:
	chmod +x ./supos-nginx.sh && ./supos-nginx.sh cd tools/shell/ && bash nginx_install.sh
master:
	cd tools/shell/ && bash config_keepalived_master.sh $(NGINX_VIP) $(INTERFACE)
backup:
	cd tools/shell/ && bash config_keepalived_backup.sh $(NGINX_VIP) $(INTERFACE)