export NGINX_VIP=192.168.18.59/24
export INTERFACE=ens160
export W1=192.168.18.167
export W2=192.168.18.168
export W3=192.168.18.169
init:
	tar -zxvf keepalived.tgz && cd tools/shell/ && bash docker.sh && bash docker-compose.sh && bash keepalived_install.sh

install:
	chmod +x ./supos-nginx.sh && ./supos-nginx.sh && cd tools/shell/ && bash nginx_install.sh
master:
	cd tools/shell/ && bash config_keepalived_master.sh ${NGINX_VIP} ${INTERFACE}
backup:
	cd tools/shell/ && bash config_keepalived_backup.sh ${NGINX_VIP} ${INTERFACE}

restart:
	systemctl restart keepalived

