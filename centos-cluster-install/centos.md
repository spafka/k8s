```bash
cat /etc/sysconfig/network-scripts/ifcfg-ens33 
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=ens33
UUID=6aba29e1-0ada-4efe-b3a3-3c6828b62ea2
DEVICE=ens33
ONBOOT=yes
IPADDR=192.168.32.100
NETMASK=255.255.255.0
GATEWAY=192.168.32.2
DNS1=114.114.114.114
```

```bash
hostnamectl set-hostname k8s-master
hostnamectl set-hostname k8s-node1
```

```bash
systemctl stop firewalld 
systemctl systemctl disable firewalld
systemctl stop iptables
systemctl disable iptables
setenforce 0 
ntpdate ntp1.aliyun.com 
swapoff -a 

# 编辑 /etc/selinux/config 文件，修改SELINUX的值为disabled
# 注意修改完毕之后需要重启linux服务
SELINUX=disabled
```

ALL
```bash
cat >> /etc/hosts << EOF 
192.168.32.100 k8s-master
192.168.32.100 etcd
192.168.32.100 registry
192.168.32.101 k8s-node1
EOF
```

MASTER
```bash
cat >> /etc/etcd/etcd.conf <<EOF
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"

ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"

ETCD_NAME="master"

ETCD_ADVERTISE_CLIENT_URLS="http://etcd:2379"
EOF

systemctl start etcd

etcdctl -C http://etcd:2379 cluster-health
```
MASTER
```bash
cat > /etc/yum.repos.d/kubernetes.repo <<EOF

[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

EOF
yum install -y kubelet-1.19.4 kubeadm-1.19.4 kubectl-1.19.4

```

NODE
```bash
cat  > /etc/kubernetes/config <<EOF

KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=http://k8s-master:8080"
EOF


cat > /etc/kubernetes/apiserver <<EOF

KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"
KUBE_ETCD_SERVERS="--etcd-servers=http://etcd:2379"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"
KUBE_API_ARGS=""
EOF

cat > /etc/kubernetes/config <<EOF
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=http://k8s-master:8080"
EOF

```

