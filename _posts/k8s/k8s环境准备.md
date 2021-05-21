## 基本环境配置

### 1. 设置hostname

```powershell
hostnamectl set-hostname k8s-master01
hostname -f
```

### 2. 设置hosts文件

```properties
cat >> /etc/hosts << eof
10.10.10.130 k8s-master-lb
10.10.10.121 k8s-master01
10.10.10.122 k8s-master02
10.10.10.123 k8s-master03
10.10.10.124 k8s-node1
10.10.10.125 k8s-node2
eof
```

### 3. 关闭防火墙、selinux、dnsmasq、swap

```shell
systemctl disable --now firewalld
systemctl disable --now dnsmasq
systemctl disable --now NetworkManager
swapoff -a && sysctl -w vm.swappiness=0
# 注释swap分区
vim /etc/fstab
setenforce 0
# 关闭selinux
vim /etc/sysconfig/selinux
# 所有节点时间同步
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
echo 'Asia/Shanghai' > /etc/timezone
ntpdate time2.aliyun.com
crontab -e
*/5 * * * * ntpdate time2.aliyun.com
# 所有节点配置limit
ulimit -SHn 65535
# 安装软件
yum -y install wget jq psmisc vim net-tools
yum update -y --exclude=kernel* && reboot
```

### 升级内核（可以跳过）

参照：https://www.cnblogs.com/xzkzzz/p/9627658.html

```bash
wget https://mirror.rc.usf.edu/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-5.9.7-1.el7.elrepo.x86_64.rpm --no-check-certificate
wget https://mirror.rc.usf.edu/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-devel-5.9.7-1.el7.elrepo.x86_64.rpm --no-check-certificate
yum localinstall -y kernel-ml-*
```

### 安装ipvs

```bash
yum -y install ipvsadm ipset sysstat conntrack libseccomp && yum -y update

modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
# 4.18 linux kernel 4.19版本已经将nf_conntrack_ipv4 更新为 nf_conntrack， 而 kube-proxy 1.13 以下版本，强依赖 nf_conntrack_ipv4。
#1、降级内核到 4.18 
#2、升级kube-proxy到 1.13+ （推荐，无需重启机器，影响小）
modprobe -- nf_conntrack_ipv4
# 以上版本
modprobe -- nf_conntrack
modprobe -- ip_tables
modprobe -- ip_set
modprobe -- xt_set
modprobe -- ipt_set
modprobe -- ipt_rpfilter
modprobe -- ipt_REJECT
modprobe -- ipip

lsmod | grep -e ip_vs -e nf_conntrack
```

### 设置K8S参数

```properties
vim /etc/sysctl.d/k8s.conf

net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
fs.may_detach_mounts=1

vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720

net.ipv4.tcp_keepalive_time=600
net.ipv4.rcp_keepalive_probes=3
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_max_tw_buckets=36000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_max_orphans=327680
net.ipv4.tcp_orphan_retries=3
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.ip_conntrack_max=65536
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_timestamps=0
net.core.somaxconn=16384
```

### 基本组件安装

#### 安装doker

```bash
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
sudo yum makecache fast
sudo yum -y install docker-ce
# Step 4: 开启Docker服务
sudo service docker start


yum -y install kubectl kubeadm kubelet
```

#### 安装k8s

https://blog.csdn.net/qsz1281509180/article/details/106302494/

```bash
vim /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0

yum -y install kubectl kubeadm kubelet
```

### 克隆虚拟机ip配置

### Master节点部署

```
#echo export MASTER_IP=10.10.10.121 > k8s.env.sh
#echo export APISERVER_NAME=master1.lab.com >> k8s.env.sh
kubeadm init \
        --apiserver-advertise-address 0.0.0.0 \
        --apiserver-bind-port 6443 \
        --cert-dir /etc/kubernetes/pki \
        --control-plane-endpoint master1.lab.com \
        --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
        --kubernetes-version 1.19.4 \
        --pod-network-cidr 10.11.0.0/16 \
        --service-cidr 10.20.0.0/16 \
        --service-dns-domain cluster.local \
        --upload-certs 
```



### Master01配置免密码

```bash
 ssh-keygen -t rsa
 for i in k8s-master01 k8s-master02 k8s-master03 k8s-node1 k8s-node2;do ssh-copy-id -i /root/.ssh/id_rsa.pub $i;done
```

### 所有master安装

```bash
yum -y install keepalived haproxy 

vim /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2
 
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
 
#---------------------------------------------------------------------
# kubernetes apiserver frontend which proxys to the backends
#---------------------------------------------------------------------
frontend kubernetes-apiserver
    mode                 tcp
    bind                 *:16443
    option               tcplog
    default_backend      kubernetes-apiserver
#---------------------------------------------------------------------
# round robin balancing between the various backends
#---------------------------------------------------------------------
backend kubernetes-apiserver
    mode        tcp
    balance     roundrobin
    server      k8s-master01 10.10.10.121:6443 check
    server      k8s-master02 10.10.10.122:6443 check
    server      k8s-master03 10.10.10.123:6443 check
#---------------------------------------------------------------------
# collection haproxy statistics message
#---------------------------------------------------------------------
listen stats
    bind                 *:1080
    stats auth           admin:awesomePassword
    stats refresh        5s
    stats realm          HAProxy\ Statistics
    stats uri            /admin?stats
    
scp -r
```

### 配置keepalived

```
vim check_apiserver.sh
#!/bin/bash

function check_apiserver() {
  for ((i=0;i<5;i++));do
    apiserver_job_id=$(pgrep kube-apiserver)
    if [[ ! -z $apiserver_job_id ]];then
       return
    else
       sleep 2
    fi
    apiserver_job_id=0
  done
}

# 1: running 0: stopped
check_apiserver
if [[ $apiserver_job_id -eq 0 ]]; then
    /usr/bin/systemctl stop keepalived
    exit 1
else
    exit 0
fi
```

#### master01配置

```properties
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -5
    fall 3  
    rise 2
}
vrrp_instance VI_1 {
    state MASTER
    interface ens33
    mcast_src_ip 10.10.10.121
    virtual_router_id 51
    priority 102
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass FMVm6NFFccY8WjhK
    }
    virtual_ipaddress {
        10.10.10.130
    }
#    track_script {
#       chk_apiserver
#    }
}

```

```
# k8s-master02
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -5
    fall 3  
    rise 2
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    mcast_src_ip 10.10.10.122
    virtual_router_id 51
    priority 101
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass FMVm6NFFccY8WjhK
    }
    virtual_ipaddress {
        10.10.10.130
    }
#    track_script {
#       chk_apiserver
#    }
}

```

```properties
# k8s-master03
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -5
    fall 3  
    rise 2
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    mcast_src_ip 10.10.10.122
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass FMVm6NFFccY8WjhK
    }
    virtual_ipaddress {
        10.10.10.130
    }
#    track_script {
#       chk_apiserver
#    }
}

```

### 启动haproxy 和 keepalived

```properties
systemctl enable --now haproxy
systemctl enable --now keepalived
```

Master01配置文件

```properties
# vim /root/kubeadm-config.yml
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
kubernetesVersion: v1.19.4
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
api:
  advertiseAddress: 10.10.10.121
  controlPlaneEndpoint: k8s-master-lb:16443
controllerManagerExtraArgs:
  node-monitor-grace-period: 10s
  pod-eviction-timeout: 10s

apiServerCertSANs:
- 10.10.10.121
- 10.10.10.122
- 10.10.10.123
- k8s-master-lb
- k8s-master01
- k8s-master02
- k8s-master03
- 10.10.10.130
etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://10.10.10.121:2379"
      advertise-client-urls: "https://10.10.10.121:2379"
      listen-peer-urls: "https://10.10.10.121:2380"
      initial-advertise-peer-urls: "https://10.10.10.121:2380"
      initial-cluster: "k8s-master01=https://10.10.10.121:2380"
    serverCertSANs:
      - k8s-master01
      - 192.168.20.20
    peerCertSANs:
      - k8s-master01
      - 192.168.20.20
networking:
  podSubnet: "172.168.0.0/16"
#kubeProxy:
#  config:
#    featureGates:
#      SupportIPVSProxyMode: true
#    mode: ipvs

```

### master02

```properties
# vim /root/kubeadm-config.yml
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
kubernetesVersion: v1.19.4

imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
api:
  advertiseAddress: 192.168.20.21
  controlPlaneEndpoint: 192.168.20.10:16443
controllerManagerExtraArgs:
  node-monitor-grace-period: 10s
  pod-eviction-timeout: 10s
apiServerCertSANs:
- k8s-master02
- k8s-master02
- k8s-master03
- k8s-master-lb
- 10.10.10.121
- 10.10.10.122
- 10.10.10.123
- 10.10.10.130
etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://10.10.10.122:2379"
      advertise-client-urls: "https://10.10.10.122:2379"
      listen-peer-urls: "https://10.10.10.122:2380"
      initial-advertise-peer-urls: "https://10.10.10.122:2380"
      initial-cluster: "k8s-master01=https://10.10.10.121:2380,k8s-master02=https://10.10.10.122:2380"
      initial-cluster-state: existing
    serverCertSANs:
      - k8s-master02
      - 10.10.10.122
    peerCertSANs:
      - k8s-master02
      - 10.10.10.122
networking:
  podSubnet: "172.168.0.0/16"

#kubeProxy:
#  config:
#    featureGates:
#      SupportIPVSProxyMode: true
#    mode: ipvs

```

#### k8s-03

```properties
# vim /root/kubeadm-config.yml
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
kubernetesVersion: v1.19.4

imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
api:
  advertiseAddress: 192.168.20.22
  controlPlaneEndpoint: 192.168.20.10:16443
controllerManagerExtraArgs:
  node-monitor-grace-period: 10s
  pod-eviction-timeout: 10s
apiServerCertSANs:
- k8s-master02
- k8s-master02
- k8s-master03
- k8s-master-lb
- 10.10.10.121
- 10.10.10.122
- 10.10.10.123
- 10.10.10.130
etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://10.10.10.123:2379"
      advertise-client-urls: "https://10.10.10.123:2379"
      listen-peer-urls: "https://10.10.10.123:2380"
      initial-advertise-peer-urls: "https://10.10.10.123:2380"
      initial-cluster: "k8s-master01=https://10.10.10.121:2380,k8s-master02=https://10.10.10.122:2380,k8s-master03=https://10.10.10.123:2380"
      initial-cluster-state: existing
    serverCertSANs:
      - k8s-master03
      - 10.10.10.123
    peerCertSANs:
      - k8s-master03
      - 10.10.10.123
networking:
  # This CIDR is a calico default. Substitute or remove for your CNI provider.
  podSubnet: "172.168.0.0/16"
#kubeProxy:
#  config:
#    featureGates:
#      SupportIPVSProxyMode: true
#    mode: ipvs

```

#### 所有master安装镜像

```
kubeadm config migrate --old-config /root/kubeadm-config.yml
```

#### master01初始化

```
kubeadm init --config /root/kubeadm-config.yml
```

```
kubeadm init \
        --apiserver-advertise-address 0.0.0.0 \
        --apiserver-bind-port 6443 \
        --cert-dir /etc/kubernetes/pki \
        --control-plane-endpoint master1.lab.com \
        --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
        --kubernetes-version 1.19.4 \
        --pod-network-cidr 10.11.0.0/16 \
        --service-cidr 10.20.0.0/16 \
        --service-dns-domain cluster.local \
        --upload-certs 
```

