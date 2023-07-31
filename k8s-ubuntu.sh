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

apt-get remove docker docker-engine docker.io containerd runc
green_echo "installing  docker "
apt install docker.io -y
yellow_echo "docker "

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

#yellow_echo $(apt-cache madison kubeadm)
apt  install kubelet=1.20.0-00 kubeadm=1.20.0-00 kubectl=1.20.0-00 -y

# kubeadm config images list --kubernetes-version=v1.20.0


cat > download_image.sh << ERIC
#!/bin/bash
images=(
    kube-apiserver:v1.20.0
    kube-controller-manager:v1.20.0
    kube-scheduler:v1.20.0
    kube-proxy:v1.20.0
    pause:3.2
    etcd:3.4.13-0
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
kubernetesVersion: v1.20.0

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




######
docker pull  quay.mirrors.ustc.edu.cn/coreos/flannel:v0.15.1
docker tag quay.mirrors.ustc.edu.cn/coreos/flannel:v0.15.1 quay.io/coreos/flannel:v0.15.1
cat > kube-flannel.yaml <<EOF
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp.flannel.unprivileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default
    seccomp.security.alpha.kubernetes.io/defaultProfileName: docker/default
    apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
    apparmor.security.beta.kubernetes.io/defaultProfileName: runtime/default
spec:
  privileged: false
  volumes:
  - configMap
  - secret
  - emptyDir
  - hostPath
  allowedHostPaths:
  - pathPrefix: "/etc/cni/net.d"
  - pathPrefix: "/etc/kube-flannel"
  - pathPrefix: "/run/flannel"
  readOnlyRootFilesystem: false
  # Users and groups
  runAsUser:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  # Privilege Escalation
  allowPrivilegeEscalation: false
  defaultAllowPrivilegeEscalation: false
  # Capabilities
  allowedCapabilities: ['NET_ADMIN', 'NET_RAW']
  defaultAddCapabilities: []
  requiredDropCapabilities: []
  # Host namespaces
  hostPID: false
  hostIPC: false
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  # SELinux
  seLinux:
    # SELinux is unused in CaaSP
    rule: 'RunAsAny'
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs: ['use']
  resourceNames: ['psp.flannel.unprivileged']
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
      - operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni-plugin
        image: rancher/mirrored-flannelcni-flannel-cni-plugin:v1.0.0
        command:
        - cp
        args:
        - -f
        - /flannel
        - /opt/cni/bin/flannel
        volumeMounts:
        - name: cni-plugin
          mountPath: /opt/cni/bin
      - name: install-cni
        image: quay.io/coreos/flannel:v0.15.1
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.15.1
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
      - name: run
        hostPath:
          path: /run/flannel
      - name: cni-plugin
        hostPath:
          path: /opt/cni/bin
      - name: cni
        hostPath:
          path: /etc/cni/net.d
      - name: flannel-cfg
        configMap:
          name: kube-flannel-cfg
EOF
kubectl apply -f kube-flannel.yaml
kubectl get nodes
kubectl taint node k8s-master node-role.kubernetes.io/master-

### 自动补全命令
apt install -y bash-completion
locate bash_completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
