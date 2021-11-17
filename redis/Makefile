port=6379
startup:
	rm -rf data
	sh ./install-redis-cluster-node-ubuntu.sh -p 6379 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6380 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6381 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6382 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6383 -a supOS
	sh ./install-redis-cluster-node-ubuntu.sh -p 6384 -a supOS
cluster:
	redis-cli -a supOS --cluster create 192.168.32.141:6379 192.168.32.141:6380 192.168.32.141:6381 192.168.32.141:6383 192.168.32.141:6384 192.168.32.141:6382 --cluster-replicas 1
check:
	redis-cli -a supOS --cluster  check 192.168.32.141:6379
all:
	make startup && make cluster && make check
test:
	redis-cli -c -a supOS -h 192.168.32.141 -p $(port)
shutdown:
	redis-cli -a supOS -c -h 192.168.32.141 -p $(port) shutdown
up:
	redis-server data/$(port)/nodes-$(port).conf