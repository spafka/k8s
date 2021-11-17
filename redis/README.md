redis-cluster部署手册
## 1.前提
本手册为安装部署redis的cluster模式集群的指导文档。  
若supOS选择集群部署模式，则要求先redis的cluster模式集群，在安装完成后，修改supOS的环境配置文件bin/env.sh

### 1.1.环境要求
要求服务器安装gcc、tcl、make。
所有服务器执行以下步骤：
```
apt install gcc tcl make -y
```

## 2.Redis Cluster安装部署
### 2.1.Redis Cluster部署说明
Redis Cluster最小部署方案为：三主三从，六个节点。  
supOS V3.5要求集群模式环境至少有三台物理机。  
假设以三台物理机A，B，C为例：  

|服务器|ip|要求|
|:---|:---|:---|
|A|192.168.12.11|/data-redis目录，目录大小需要(20GB+redis最大内存*2)|
|B|192.168.12.12|/data-redis目录，目录大小需要(20GB+redis最大内存*2)|
|C|192.168.12.13|/data-redis目录，目录大小需要(20GB+redis最大内存*2)|

Redis的六个节点分为：  
三主节点为M1，M2，M3；  
三从节点为S1，S2，S3；  
M1/S1为主从；  
M2/S2为主从；  
M3/S3为主从；  

Redis Cluster的slot分布为：  

|slots|nodes|
|:---|:---|
|[0-5460]|M1、S1|
|[5461-10922]|M2、S2|
|[10923-16383]|M3、S3|

同个slot区间的节点需要在服务器上错开，节点的分布应为：  

|服务器|节点|说明|
|:---|:---|:---|
|A|M1、S2|同一个主从错开|
|B|M2、S3||
|C|M3、S1||

|redis节点|服务器|端口|集群角色|说明|
|:---|:---|:---|:---|:---|
|M1|A|6379|Master|从节点为S1|
|M2|B|6379|Master|从节点为S2|
|M3|C|6379|Master|从节点为S3|
|S1|C|6380|Slave|主节点为M1|
|S2|A|6380|Slave|主节点为M2|
|S3|B|6380|Slave|主节点为M3|

注意点：
* 集群节点的密码需要保持一致
* 集群节点的内存需要保持一致

### 2.2.Redis Cluster部署
假设使用redis的默认版本(5.0.12)  
redis集群密码为：supOS  
redis节点的最大内存为：4GB  

### 2.2.1. 安装Redis Cluster节点
获取部署包supOS-redis-v0.4.8.zip，将部署包放到/data-redis目录中。

```shell
# 进入/data-redis目录
cd /data-redis
# 解压部署包
unzip supOS-redis-v0.4.8.zip
# 进入部署包内部
cd supOS-redis-v0.4.8
```
#### 2.2.1.1 服务器A安装M1和S2节点
服务器A，解压安装包后，进入安装包根目录，执行以下命令：
```shell
# 安装M1节点
sh install-redis-cluster-node-ubuntu.sh -p 6379 -a supOS -m 4GB
# 安装S2节点
sh install-redis-cluster-node-ubuntu.sh -p 6380 -a supOS -m 4GB 
```
#### 2.2.1.1 服务器B安装M2和S3节点
服务器B，解压安装包后，进入安装包根目录，执行以下命令：
```shell
# 安装M2节点
sh install-redis-cluster-node-ubuntu.sh -p 6379 -a supOS -m 4GB
# 安装S3节点
sh install-redis-cluster-node-ubuntu.sh -p 6380 -a supOS -m 4GB 
```
#### 2.2.1.1 服务器C安装M3和S1节点
服务器C，解压安装包后，进入安装包根目录，执行以下命令：
```shell
# 安装M3节点
sh install-redis-cluster-node-ubuntu.sh -p 6379 -a supOS -m 4GB
# 安装S1节点
sh install-redis-cluster-node-ubuntu.sh -p 6380 -a supOS -m 4GB 
```

### 2.2.2. 建立Redis Cluster集群
随便在一台服务器上，进入到对应版本的redis解压包下，如使用Redis5.0.12版本。
```shell
cd /data-redis/supOS-redis-v0.4.7/redis-5.0.12/src
```
在redis的src目录下执行以下命令，建立集群：
```shell
./redis-cli -a {password} --cluster create {node1}:{port1} {node2}:{port2} {node3}:{port3} {node4}:{port4} {node5}:{port5} {node6}:{port6} --cluster-replicas 1
```
按照例子场景的命令如下，在提示集群信息后并输入yes且回车：
```shell
./redis-cli -a supOS --cluster create 192.168.12.11:6379 192.168.12.12:6379 192.168.12.13:6379 192.168.12.12:6380 192.168.12.13:6380 192.168.12.11:6380 --cluster-replicas 1
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 192.168.12.13:6380 to 192.168.12.11:6379
Adding replica 192.168.12.11:6380 to 192.168.12.12:6379
Adding replica 192.168.12.12:6380 to 192.168.12.13:6379
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: 255d306a2b9ece300b4df11eb4f386332a1da83e 192.168.12.11:6379
   slots:[0-5460] (5461 slots) master
M: b02c17e37f825b155a3acf996ffb7d552e17a0db 192.168.12.12:6379
   slots:[5461-10922] (5462 slots) master
M: 59620e0259a6c503febbab9b455d1ef0918abe4c 192.168.12.13:6379
   slots:[10923-16383] (5461 slots) master
S: 6028d8e983f31e2e18a3cd8290c9f4f0c9ee95c3 192.168.12.12:6380
   replicates 255d306a2b9ece300b4df11eb4f386332a1da83e
S: 9988f806191f8719bed1699e4537331d03f9e80b 192.168.12.13:6380
   replicates b02c17e37f825b155a3acf996ffb7d552e17a0db
S: fbd17c82490fd77d885b92f85c9f799efe572aba 192.168.12.11:6380
   replicates 59620e0259a6c503febbab9b455d1ef0918abe4c
Can I set the above configuration? (type 'yes' to accept): yes #确认集群信息无误，在这里输入yes并回车
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node 192.168.12.11:6379)
M: 255d306a2b9ece300b4df11eb4f386332a1da83e 192.168.12.11:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
M: 59620e0259a6c503febbab9b455d1ef0918abe4c 192.168.12.13:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
S: 6028d8e983f31e2e18a3cd8290c9f4f0c9ee95c3 192.168.12.12:6380
   slots: (0 slots) slave
   replicates 255d306a2b9ece300b4df11eb4f386332a1da83e
S: fbd17c82490fd77d885b92f85c9f799efe572aba 192.168.12.11:6380
   slots: (0 slots) slave
   replicates 59620e0259a6c503febbab9b455d1ef0918abe4c
S: 9988f806191f8719bed1699e4537331d03f9e80b 192.168.12.13:6380
   slots: (0 slots) slave
   replicates b02c17e37f825b155a3acf996ffb7d552e17a0db
M: b02c17e37f825b155a3acf996ffb7d552e17a0db 192.168.12.12:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```
[OK] All 16384 slots covered. 表示为Redis Cluster集群部署完成。

## 3.Redis Cluster维护
### 3.1. 集群状态检测
来查看集群状态:
```shell
./redis-cli -a {password} --cluster  check {node-ip}:{node-port}
```
### 3.2.迁移slot
slot迁移只允许master与master之间进行。
```shell
./redis-cli -a {password} --cluster reshard {existing-node-id}:{existing-node-port} --cluster-from {from-node-id} --cluster-to {to-node-id} --cluster-slots {number of slots} --cluster-yes
```
### 3.3.增加master节点
```shell
./redis-cli -a {password} --cluster add-node {new-node-ip}:{new-node-port} {existing-node-ip}:{existing-node-port}
```
### 3.4.增加slave节点
```shell
./redis-cli -a {password} --cluster add-node {new-node-ip}:{new-node-port} {existing-node-ip}:{existing-node-port} --cluster-slave --cluster-master-id {master-id}
```
### 3.5.删除节点
```shell
./redis-cli -a {password} --cluster del-node {existing-node-id}:{existing-node-port} {need-delete-node-id}
```

## 4.supOS的redis配置参数说明
配置好Redis Cluster集群后，需要将集群信息配置到supOS的环境文件文件中。  
bin/env.sh
```yaml
REDIS_HOSTS={IP-A}:6379,{IP-B}:6379,{IP-C}:6379,{IP-B}:6380,{IP-C}:6380,{IP-A}:6380
REDIS_PASSWD=supOS
```

## 5.Redis Cluster部署包说明
Redis Cluster集群使用部署包supOS-redis-v0.4.8.zip进行安装。  
包格式如下：
```
/
|-install-redis-cluster-node-ubuntu.sh
|-redis-cluster-param.conf
|-redis-5.0.12.tar.gz
```

### 5.1.Redis Cluster部署包文件作用说明
#### 5.1.1.文件install-redis-cluster-node-ubuntu.sh
该脚本为Redis Cluster节点的安装脚本。  
脚本执行格式为： 
```
sh install-redis-cluster-node-ubuntu.sh [Options] 

Options:
-v Redis's version.(default 5.0.12)
-p Redis node's port.(default 6379)
-a Redis node's password.(default supOS)
-m Redis node's maxmemory.(default 1GB),support KB/MB/GB unit,example 256MB or 2GB.
```

默认支持redis5.0.12版本，若需要安装其他redis版本，可以指定其它存在的redis版本。  
脚本支持离线安装包安装和在线包安装两种方式。 
* 离线安装：
``` 
离线包格式为redis-{version}.tar.gz 
将离线安装包放在安装脚本同目录，
执行安装脚本sh install-redis-cluster-node-ubuntu.sh -v {version}

如，离线安装redis5.0.12.tar.gz，将安装包放到脚本同目录。
/
|-install-redis-cluster-node-ubuntu.sh
|-redis-cluster-param.conf
|-redis-5.0.12.tar.gz

sh install-redis-cluster-node-ubuntu.sh -v 5.0.12
```
* 在线安装：
```
在线安装会从官网进行下载需要的安装资源，需要部署环境能够访问https://download.redis.io/releases/redis-{version}.tar.gz

如，在线安装redis-6.2.4.tar.gz，脚本会将安装包下载到脚本同目录。
/
|-install-redis-cluster-node-ubuntu.sh
|-redis-cluster-param.conf
|-redis-5.0.12.tar.gz

执行安装脚本 sh install-redis-cluster-node-ubuntu.sh -v 6.2.4
安装完后：
/
|-install-redis-cluster-node-ubuntu.sh
|-redis-cluster-param.conf
|-redis-5.0.12.tar.gz
|-redis-6.2.4.tar.gz
```
##### 5.1.1.1.脚本安装例子
在本机安装，5.0.12版本，端口为6380，密码为123456，最大内存4GB的Redis Cluster节点。  
命令如下：
```shell
sh install-redis-cluster-node-ubuntu.sh -v 5.0.12 -p 6380 -a 123456 -m 4GB
```
#### 5.1.2.文件redis-cluster-param.conf
Redis Cluster节点的配置的模板文件。
#### 5.1.3.文件redis-{version}.tar.gz
Redis Cluster的安装包。   