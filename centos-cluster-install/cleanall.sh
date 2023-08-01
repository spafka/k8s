kubectl delete deployments.apps --all
kubeadm reset
rm -rf ~/.kube/*
yum remove kubelet kubectl -y
iptables -F && iptables -F -t nat
rm -rf /etc/kubernetes/
rm -rf /etc/cni/
rm -rf /var/lib/etcd/
docker stop  $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

