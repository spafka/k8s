#!/usr/bin/env bash

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

apt install drbd-utils nfs-kernel-server keepalived   lvm2 -y
pvcreate /dev/sdb
vgcreate  ubuntu-vg /dev/sdb
vgextend ubuntu-vg /dev/sdb
lvcreate -L 19G -n lv00 ubuntu-vg

export HOST1=ubuntu-nfs1
export HOST2=ubuntu-nfs2
export IP1=192.168.18.130
export IP2=192.168.18.131

if [ -z $HOST1 ]; then
    red_echo "HOST1 unset"
fi

if [ -z $HOST2 ]; then
    red_echo "HOST2 unset"
fi

if [ -z $IP1 ]; then
    red_echo "IP1 unset"
fi


if [ -z $IP2 ]; then
    red_echo "IP21unset"
fi



cat <<EOF >/etc/exports
/nfs *(rw,sync,no_subtree_check,no_root_squash)
EOF

cat << EOF >/etc/drbd.conf
global { usage-count no; }
common { syncer { rate 1000M; } }
resource r0 {
        protocol C;
        startup {
                wfc-timeout  15;
                degr-wfc-timeout 60;
        }
        net {
                cram-hmac-alg sha1;
                shared-secret "secret";
                after-sb-0pri discard-younger-primary;
                after-sb-1pri discard-secondary;
                after-sb-2pri call-pri-lost-after-sb;
        }
        on $HOST1 {
                device /dev/drbd0;
                disk /dev/ubuntu-vg/lv00;
                address $IP1:7788;
                meta-disk internal;
        }
        on $HOST2 {
                device /dev/drbd0;
                disk /dev/ubuntu-vg/lv00;
                address $IP2:7788;
                meta-disk internal;
        }
}
EOF


drbdadm create-md r0
systemctl start drbd
systemctl enable drbd



cat /proc/drbd


cat <<EOF > /etc/keepalived/notify_master.sh
#!/bin/bash
set -o errexit

time=`date "+%F  %H:%M:%S"`
echo -e "$time    ------notify_master------\n" >> /etc/keepalived/logs/notify_master.log
drbdsetup /dev/drbd0 primary &>> /etc/keepalived/logs/notify_master.log
mount /dev/drbd0 /nfs &>> /etc/keepalived/logs/notify_master.log
systemctl restart nfs-server &>> /etc/keepalived/logs/notify_master.log
exportfs -a &>> /etc/keepalived/logs/notify_master.log
echo -e "\n" >> /etc/keepalived/logs/notify_master.log
EOF

mkdir -p  /nfs


