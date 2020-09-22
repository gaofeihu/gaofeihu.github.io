# 

# 1. 安装docker

### 使用官方安装脚本自动安装 （仅适用于公网环境）

```bash
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

### CentOS 7 (使用yum进行安装)

```powershell
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3: 更新并安装 Docker-CE
sudo yum makecache fast
sudo yum -y install docker-ce
# Step 4: 开启Docker服务
sudo service docker start

注意：其他注意事项在下面的注释中
# 官方软件源默认启用了最新的软件，您可以通过编辑软件源的方式获取各个版本的软件包。例如官方并没有将测试版本的软件源置为可用，你可以通过以下方式开启。同理可以开启各种测试版本等。
# vim /etc/yum.repos.d/docker-ce.repo
#   将 [docker-ce-test] 下方的 enabled=0 修改为 enabled=1
#
# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# yum list docker-ce.x86_64 --showduplicates | sort -r
#   Loading mirror speeds from cached hostfile
#   Loaded plugins: branch, fastestmirror, langpacks
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            @docker-ce-stable
#   docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable
#   Available Packages
# Step2 : 安装指定版本的Docker-CE: (VERSION 例如上面的 17.03.0.ce.1-1.el7.centos)
# sudo yum -y install docker-ce-[VERSION]
# 注意：在某些版本之后，docker-ce安装出现了其他依赖包，如果安装失败的话请关注错误信息。例如 docker-ce 17.03 之后，需要先安装 docker-ce-selinux。
# yum list docker-ce-selinux- --showduplicates | sort -r
# sudo yum -y install docker-ce-selinux-[VERSION]

# 通过经典网络、VPC网络内网安装时，用以下命令替换Step 2中的命令
# 经典网络：
# sudo yum-config-manager --add-repo http://mirrors.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
# VPC网络：
# sudo yum-config-manager --add-repo http://mirrors.could.aliyuncs.com/docker-ce/linux
```

### 镜像加速

```powershell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://fmio0u1m.mirror.aliyuncs.com"],
  "graph":"/data/docker"
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

# 2. docker使用

### 镜像管理

```powershell
# 标记本地镜像，将其归入某一仓库
docker tag ubuntu:15.10 runoob/ubuntu:v3
# 镜像导出
docker save nginx > nginx.tar.gz
# 镜像导入
docker load < nginx.tar.gz 
# 守护进程的系统资源设置
docker info 
# Docker 仓库的查询
docker search 
# Docker 仓库的下载
docker pull 
# Docker 镜像的查询
docker images 
# Docker 镜像的删除
docker rmi
# 删除镜像:
docker rmi -f $(docker images -q)
#镜像唯一标示
imageName:version 或者 imagesId


```

**注意容器启动需要有工作在前台的守护进程至少一个**

### 容器操作

```powershell
# 查看容器日志
docker logs -f cId
# 容器的查询
docker ps
# 容器的创建启动
docker run  imageName:version
# 容器启动停止
docker start/stop
# 删除所有容器：
docker rm -f $(docker ps -a -q)
# 查看
docker ps --no-trunc

# 停止 容器
docker stop/start CONTAINERID

# 通过容器别名启动/停止
docker start/stop MywordPress 

# 查看容器所有基本信息
docker inspect MywordPress

# 查看容器日志
docker logs MywordPress

# 查看容器所占用的系统资源
docker stats MywordPress

# 容器执行命令
docker exec 容器名 容器内执行的命令 

# 登入容器的bash
docker exec -it 容器名 /bin/bash

# 可以查看容器当前的映射关系
docker port ContainerName 
```

### run 参数

```powershell
-d  后台执行

-it 交互式

-c  要执行的命令

-rm 容器退出后自动删除

--name 为容器起名

-p 要暴露的端口 8080:80

-P 使用一个随机的端口

--network 制定网络默认是brige

--restart=always 容器的自动启动

-h x.xx.xx 设置容器主机名

--dns xx.xx.xx.xx  设置容器使用的 DNS 服务器

--dns-search DNS 搜索设置

--add-host hostname:IP 注入 hostname <> IP 解析

```

# **3. 镜像、仓库管理** 

### 1、从容器都镜像转换

```bash
docker commit 容器名称 镜像名称:版本号  

docker commit mysql mysql:5.1
```

**注意容器启动需要有工作在前台的守护进程至少一个**

### 2、DockerFile 

Dockfile 是一种被 Docker 程序解释的脚本，Dockerfile 由一条一条的指令组成，每条指令对应 Linux 下面 

的一条命令。Docker 程序将这些 Dockerfile 指令翻译真正的 Linux 命令。Dockerfile 有自己书写格式和支持的命令， 

Docker 程序解决这些命令间的依赖关系，类似于 Makefile。Docker 程序将读取 Dockerfile，根据指令生成定制的 image 生成命令:

`docker build -t wangyang/jdk-tomcat .` 

### 3、 网易云CenterOS基础镜像拉取

```bash
# 6版本使用6.7 7版本使用7.6 否则又systemd 有问题，
docker pull hub.c.163.com/public/centos:6.7-tools

仓库地址/仓库名/镜像名:版本号

```

### 4、镜像的导出以及导入

```
导出：docker save -o  xx.xx.xx  xx.xx.xx.tar

导入：docker load -i xx.xx.xx.tar
```

# 4.Docker网络

### Bridge 模式

> 当 Docker 进程启动时，会在主机上创建一个名为`docker0`的虚拟网桥，此主机上启动的 Docker 容器会连接到这个虚拟网桥上。虚拟网桥的工作方式和物理交换机类似，这样主机上的所有容器就通过交换机连在了一个二层网络中。从 docker0 子网中分配一个 IP 给容器使用，并设置 docker0 的 IP 地址为容器的默认网关。在主机上创建一对虚拟网卡`veth pair`设备，Docker 将 veth pair 设备的一端放在新创建的容器中，并命名为 eth0（容器的网卡），另一端放在主机中，以`vethxxx`这样类似的名字命名，并将这个网络设备加入到 docker0 网桥中。



> bridge 模式是 docker 的默认网络模式，使用`docker run -p`时，实际上是通过 iptables 做了`DNAT`规则，实现端口转发功能。可以使用iptables -t nat -vnL查看。

运行一个 busybox 容器

```powershell
docker run -tid --net=bridge --name docker_bri busybox top
```



### 自定义网络

> 我们可以看到在新创建的容器上可以访问到我们连接的容器，但是反过来却不行了，因为`--link`是单方面的

```
docker run -tid --link docker_bri --name docker_bri1 busybox top
docker exec -it docker_bri1 /bin/sh
```

我们可以通过自定义网络的方式来实现互联互通，首先创建一个自定义的网络

```bash
docker network create -d bridge my-net
docker run -it --rm --name busybox1 --network my-net busybox sh
docker run -it --rm --name busybox2 --network my-net busybox sh
ping busybox2
ping busybox1
```

busybox1 容器和 busybox2 容器建立了互联关系，如果你有多个容器之间需要互相连接，推荐使用后面的 Docker Compose。

### Host 模式

> 如果启动容器的时候使用 host 模式，那么这个容器将不会获得一个独立的`Network Namespace`，而是和宿主机共用一个 Network Namespace。容器将不会虚拟出自己的网卡，配置自己的 IP 等，而是使用宿主机的 IP 和端口。但是，容器的其他方面，如文件系统、进程列表等还是和宿主机隔离的。

使用 host 模式也很简单，只需要在运行容器的时候指定 `--net=host` 即可。

### Container 模式

> 这个模式指定新创建的容器和已经存在的一个容器共享一个 Network Namespace，而不是和宿主机共享。新创建的容器不会创建自己的网卡，配置自己的 IP，而是和一个指定的容器共享 IP、端口范围等。同样，两个容器除了网络方面，其他的如文件系统、进程列表等还是隔离的。两个容器的进程可以通过 lo 网卡设备通信。 

在运行容器的时候指定 `--net=container:目标容器名` 即可。实际上我们后面要学习的 Kubernetes 里面的 Pod 中容器之间就是通过 Container 模式链接到 pause 容器上面的，所以容器直接可以通过 localhost 来进行访问。

### None 模式

使用 none模式，Docker 容器拥有自己的 Network Namespace，但是并不为Docker 容器进行任何网络配置。也就是说这个 Docker 容器没有网卡、IP、路由等信息。需要我们自己为 Docker 容器添加网卡、配置 IP 等。选择这种模式，一般是用户对网络有自己特殊的需求，不希望 docker 预设置太多的东西。

### 其他

##### (1) 容器访问外部网络

 ```bash
iptables -t nat -A POSTROUTING -s 172.17.0.0/16 -o docker0 -j MASQUERADE 
 ```

##### (2) 外部网络访问容器 

```bash
docker run -d -p 80:80 apache
iptables -t nat -A  PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
iptables -t nat -A DOCKER ! -i docker0 -p tcp -m tcp --dport 80 -j  DNAT --to-destination 172.17.0.2:80
```

#### 自定义 Docker0 网桥的网络地址 

```json
{
  "bip": "192.168.1.5/24",
  "fixed-cidr": "10.20.0.0/16", "fixed-cidr-v6": "2001:db8::/64",
  "mtu": "1500",
  "default-gateway": "10.20.1.1", "default-gateway-v6": "2001:db8:abcd::89", 	   "dns": ["10.20.1.2","10.20.1.3"]
}
```

### 不同网络之间进行隔离

```powershell
docker network create -d bridge --subnet "172.26.0.0/16" --gateway "172.26.0.1" my-bridge-network
docker run -d --network=my-bridge-network --name test1  hub.c.163.com/public/centos:6.7-tools
docker run -d --name test2  hub.c.163.com/public/centos:6.7-tools
```



```ruby
sudo curl -L https://github.com/docker/compose/releases/download/1.25.0-rc1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

