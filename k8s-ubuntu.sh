set -x
#passwd root
systemctl disable ufw && systemctl stop ufw
apt install openssh-server -y
systemctl start sshd
systemctl enable  ssh

function green_echo () {
        local what=$*
        echo -e "\e[1;32m[success] ${what} \e[0m"
}
function yellow_echo () {
        local what=$*
        echo -e "\e[1;33m[warnning] ${what} \e[0m"
}
function red_echo () {
        local what=$*
        echo -e "\e[1;31m[error] ${what} \e[0m"
        exit 1
}
if [ -z $MASTER ]; then red_echo "设置 localIp"
fi

green_echo "set hostname"
hostnamectl set-hostname k8s-master



green_echo "install maven"
apt install -y wget
wget https://archive.apache.org/dist/maven/maven-3/3.8.2/binaries/apache-maven-3.8.2-bin.tar.gz
tar -zxvf apache-maven-3.8.2-bin.tar.gz -C /usr/local
ln -s /usr/local/apache-maven* /usr/local/maven
echo "export PATH=\$PATH:/usr/local/maven/bin" >> /etc/profile
source /etc/profile

# shellcheck disable=SC1072
if [ ! type mvn > /dev/null 2 >&1]; then
   red_echo "mvn not intalled"
fi

sudo apt install openjdk-8-jdk -y
if [ ! type javac >> /dev/null 2>&1]; then
   red_echo "java not intalled"
fi
apt install wget curl vim git ipvsadm  dnsutils net-tools -y
green_echo "close firewall"
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -L -n
apt-get remove docker docker-engine docker.io containerd runc
green_echo "installing  docker "
wget -P /home/deploy/deb/docker/ https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce_19.03.13~3-0~ubuntu-bionic_amd64.deb
wget -P /home/deploy/deb/docker/ https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/containerd.io_1.3.7-1_amd64.deb
wget -P /home/deploy/deb/docker/ https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce-cli_19.03.13~3-0~ubuntu-bionic_amd64.deb

yellow_echo "docker "

dpkg -i /home/deploy/deb/docker/*.deb

#apt-get purge -y docker-ce docker-ce-cli containerd.io
#rm -rf /var/lib/docker

cat > /etc/docker/daemon.json << ERIC
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "registry-mirrors": ["https://7uuu3esz.mirror.aliyuncs.com"],
  "data-root": "/data/docker"
}
ERIC

systemctl daemon-reload
systemctl enable docker.service
systemctl restart docker


yellow_echo "dokcer 状态:"
yellow_echo $(docker ps -a)

sudo apt-get update && sudo apt-get install -y ca-certificates curl software-properties-common apt-transport-https curl
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-mark hold kubelet kubeadm kubectl

yellow_echo $(apt-cache madison kubeadm)
apt  install kubelet=1.19.0-00 kubeadm=1.19.0-00 kubectl=1.19.0-00

# kubeadm config images list --kubernetes-version=v1.19.0


cat > download_image.sh << ERIC
#!/bin/bash
images=(
    kube-apiserver:v1.19.0
    kube-controller-manager:v1.19.0
    kube-scheduler:v1.19.0
    kube-proxy:v1.19.0
    pause:3.2
    etcd:3.4.9-1
    coredns:1.7.0
)

proxy=registry.cn-hangzhou.aliyuncs.com/google_containers/

echo '+----------------------------------------------------------------+'
for img in \${images[@]};
do
    docker pull \$proxy\$img
    docker tag  \$proxy\$img k8s.gcr.io/\$img
    docker rmi  \$proxy\$img
    echo '+----------------------------------------------------------------+'
    echo ''
done

ERIC

chmod -R 755 download_image.sh
./download_image.sh

## iP replase
cat > kubeadm-init.yaml << ERIC
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.19.0

localAPIEndpoint:
  advertiseAddress: ${MASTER}
  bindPort: 6443

networking:
  dnsDomain: apiserver.cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
scheduler: {}
ERIC
swapoff -a && sed -ri 's/.*swap.*/#&/' /etc/fstab
kubeadm init --config kubeadm-init.yaml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

