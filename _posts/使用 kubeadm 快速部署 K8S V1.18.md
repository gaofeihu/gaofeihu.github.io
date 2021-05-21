# 使用 kubeadm 快速部署 K8S V1.18

镜像下载、域名解析、时间同步请点击 [阿里巴巴开源镜像站](https://developer.aliyun.com/mirror)

## 1、基础环境，至少1个Master和1个Worker；

### 2、基本配置

#### 1. 服务器开启硬件虚拟化支持；

#### 2. 操作系统版本大于CentOS7.5，Minimal模式，可update到最新版本；

#### 3.关闭SElinux和Firewalld服务

```bash
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0
systemctl disable firewalld
systemctl stop firewalld

echo "10.10.10.151 master1.lab.com" >> /etc/hosts
echo "10.10.10.152 node1.lab.com" >> /etc/hosts
echo "10.10.10.153 node2.lab.com" >> /etc/hosts

```

#### 4) 设置hostname并在/etc/hosts配置本地解析；

```bash
hostnamectl set-hostname master1.lab.com
ssh-keygen -t rsa
ssh-copy-id -i /root/.ssh/id_rsa.pub node1.lab.com 
```

#### 5) 关闭Swap服务

```bash
swapoff -a
sed -i '/swap/d' /etc/fstab
```

#### 6) 修改sysctl.conf

```shell
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
sysctl -p
#若提示cannot stat /proc/sys/net/bridge/bridge-nf-call-ip6tables: No such file or directory
modprobe br_netfilter
sysctl -p
```

### 3. 所有节点安装Docker服务

```bash
1) 如果已安装过旧版本需要删除：
yum -y remove docker-client docker-client-latest docker-common docker-latest docker-logrotate docker-latest-logrotate \ docker-selinux docker-engine-selinux docker-engine
2) 设置阿里云docker仓库，并安装Docker服务；
yum -y install yum-utils lvm2 device-mapper-persistent-data nfs-utils xfsprogs wget
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
```

### 4. 所有节点安装K8S服务

```shell
#1) 如果已安装过旧版本，需要删除：
yum -y remove kubectl kubelet kubadm 
#2) 设置阿里云的仓库,并安装新版本
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum -y install kubelet kubeadm  kubectl
# Node节点不需要按照kubectl

#3) 修改Docker Cgroup Driver为systemd，如果不修改则在后续添加Worker节点时可能会遇到“detected cgroupfs as ths Docker driver.xx”的报错信息，并配置Docker本地镜像库；
cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "registry-mirrors":[
        "https://kfwkfulq.mirror.aliyuncs.com",
        "https://2lqq34jg.mirror.aliyuncs.com",
        "https://pee6w651.mirror.aliyuncs.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF
# 4) 重启Docker，并启动Kubelet
systemctl daemon-reload
systemctl restart docker
systemctl enable kubelet
systemctl start kubelet
```

### 保存镜像克隆，准备Master和node

### 5、Master节点部署

```shell
#1) 如果需要初始化Master节点，请执行
kubeadm reset;
#2) 配置环境变量：
echo export MASTER_IP=10.10.10.151 > k8s.env.sh
echo export APISERVER_NAME=master1.lab.com >> k8s.env.sh
sh k8s.env.sh
#3) Master节点初始化：
kubeadm init \
        --apiserver-advertise-address 0.0.0.0 \
        --apiserver-bind-port 6443 \
        --cert-dir /etc/kubernetes/pki \
        --control-plane-endpoint master1.lab.com \
        --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
        --kubernetes-version 1.19.4 \
        --pod-network-cidr 10.11.0.0/16 \
        --service-cidr 10.10.0.0/16 \
        --service-dns-domain cluster.local \
        --upload-certs 
kubeadm init --kubernetes-version=1.19.4  \
--apiserver-advertise-address=10.10.10.151   \
--image-repository registry.aliyuncs.com/google_containers  \
--service-cidr=10.10.0.0/16 --pod-network-cidr=192.168.0.0/16

# 初始化 Control-plane/Master 节点，命名参数说明
初始化完成保留token

#echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile && source ~/.bash_profile

4) 配置kubectl：
rm -f .kube && mkdir .kube
cp -i /etc/kubernetes/admin.conf .kube/config
chown $(id -u):$(id -g) $HOME/.kube/config   
# 可用于为普通用户分配kubectl权限

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
source <(kubectl completion bash)
```

kubeadm init \

```properties
--apiserver-advertise-address 0.0.0.0 \
# API 服务器所公布的其正在监听的 IP 地址,指定“0.0.0.0”以使用默认网络接口的地址
# 切记只可以是内网IP，不能是外网IP，如果有多网卡，可以使用此选项指定某个网卡
--apiserver-bind-port 6443 \
# API 服务器绑定的端口,默认 6443
--cert-dir /etc/kubernetes/pki \
# 保存和存储证书的路径，默认值："/etc/kubernetes/pki"
--control-plane-endpoint kuber4s.api \
# 为控制平面指定一个稳定的 IP 地址或 DNS 名称,
# 这里指定的 kuber4s.api 已经在 /etc/hosts 配置解析为本机IP
--image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
# 选择用于拉取Control-plane的镜像的容器仓库，默认值："k8s.gcr.io"
# 因 Google被墙，这里选择国内仓库
--kubernetes-version 1.17.3 \
# 为Control-plane选择一个特定的 Kubernetes 版本， 默认值："stable-1"
--node-name master01 \
#  指定节点的名称,不指定的话为主机hostname，默认可以不指定
--pod-network-cidr 10.10.0.0/16 \
# 指定pod的IP地址范围
--service-cidr 10.20.0.0/16 \
# 指定Service的VIP地址范围
--service-dns-domain cluster.local \
# 为Service另外指定域名，默认"cluster.local"
--upload-certs
# 将 Control-plane 证书上传到 kubeadm-certs Secret

```

#### 6、安装Calico网络插件：

```shell
#集群必须安装网络插件以实现Pod间通信，只需要在Master节点操作，其他Node节点会自动创建相关Pod；
wget https://docs.projectcalico.org/v3.8/manifests/calico.yaml
# 该配置文件默认采用的Pod的IP地址为192.168.0.0/16，需要修改为集群初始化参数中采用的值，本例中为10.10.0.0/16；
sed -i "s#192\.168\.0\.0/16#10\.11\.0\.0/16#" calico.yaml
kubectl apply -f calico.yaml
# 1) 等待所有容器状态处于Running状态：
watch -n 2 kubectl get pods -n kube-system -o wide
kubectl get nodes -o wide 
#查看所有node状态
#2) 获取join命令参数，并保存输出结果：
kubeadm token create --print-join-command > node.join.sh
```

#### 7、Worker节点部署

```bash
#0) 设置主机名否则会报节点已经存在的错误
hostnamectl set-hostname node2.lab.com
#1) 如果需要初始化Worker节点，请执行
kubeadm reset;
#2) 从Master复制环境变量和加入集群脚本：
scp master1.lab.com:/root/k8s.env.sh master1.lab.com:/root/node.join.sh .
sh k8s.env.sh
sh node.join.sh
#或直接执行
kubeadm join master1.lab.com:6443 --token e1xszv.7fa46uw7intwcbwi  \
    --discovery-token-ca-cert-hash sha256:2637022ef0928d0b390bf10b246ccf20e00f73966667bc711d683a8d71492e5a
#3) 在Master节点查看Worker状态：
kubectl get nodes -o wide
#4) 移除Worker节点：
#在Worker节点执行
kubeadm reset -f
#在Master节点执行
kubectl delete node <worker节点主机名>
```

#### 7、增加Master节点

```
1) 在待增加Master节点执行
#kubeadm join master1.lab.com:6443 --token e1xszv.7fa46uw7intwcbwi  \
    --discovery-token-ca-cert-hash sha256:2637022ef0928d0b390bf10b246ccf20e00f73966667bc711d683a8d71492e5a\
--control-plane --certificate-key 5253fc7e9a4e6204d0683ed2d60db336b3ff64ddad30ba59b4c0bf40d8ccadcd
```

#### 8、安装Ingress Controller

```shell
# 1) 在Master节点执行，具体可以参考https://github.com/nginxinc/kubernetes-ingress/blob/v1.5.3/docs/installation.md
kubectl apply -f https://kuboard.cn/install-script/v1.16.0/nginx-ingress.yaml
```

#### 9、安装Kuboard图形化管理界面

```shell
#1) 在Master节点执行
kubectl apply -f https://kuboard.cn/install-script/kuboard.yaml
查看运行状态，可能需要几分钟才能成为Running状态：
kubectl get pods -l k8s.eip.work/name=kuboard -n kube-system
#2) 获取Token权限，用于界面登录
kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep kuboard-user | awk '{print $1}') -o go-template='{{.data.token}}' | base64 -d > admin-token.txt

kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep kuboard-viewer | awk '{print $1}') -o go-template='{{.data.token}}' | base64 -d > read-only-token.txt
#3) 管理节目访问
http://任意一个Worker节点的IP地址:32567
```