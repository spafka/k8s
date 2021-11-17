startup:
	sh ./install-redis-cluster-node-ubuntu.sh -p 6379 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6380 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6381 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6382 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6383 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6384 -a supOS
cluster:
	HOST=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
	redis-cli -a supOS --cluster create ${HOST}:6379 ${HOST}:6380 ${HOST}:6381 ${HOST}:6383 ${HOST}:6384 ${HOST}:6382 --cluster-replicas 1
checK:
	export HOST=$(ifconfig -a|grep inet|grep -v ${HOST}|grep -v inet6|awk '{print $2}'|tr -d "addr:")
	redis-cli -a supOS --cluster  check ${HOST}:6379