---
layout:     post
title:  hac高可用
subtitle: hac高可用
date:       2020-1-16
author:     silence
header-img: img/post-linux.png
catalog: true
tags:
    - linux
    - hac
---

### 1.hac简介

#### 一、什么是高可用集群

高可用集群就是当某一个节点或服务器发生故障时，另一个节点能够自动且立即向外提供服务，即将有故障节点上的资源转移到另一个节点上去，这样另一个节点有了资源既可以向外提供服务。高可用集群是用于单个节点发生故障时，能够自动将资源、服务进行切换，这样可以保证服务一直在线。在这个过程中，对于客户端来说是透明的。

`原理是心跳检测`

#### 二、高可用集群的衡量标准

高可用集群一般是通过系统的可靠性(reliability)和系统的可维护性(maintainability)来衡量的。通常用平均无故障时间（MTTF）来衡量系统的可靠性，用平均维护 时间（MTTR）来衡量系统的可维护性。因此，一个高可用集群服务可以这样来定义：HA=MTTF/(MTTF+MTTR)*100%。

一般高可用集群的标准有如下几种：

99%：表示 一年宕机时间不超过4天

99.9% ：表示一年宕机时间不超过10小时

99.99%： 表示一年宕机时间不超过1小时

99.999% ：表示一年宕机时间不超过6分钟



####  Keepalived 的热备方式

VRRP(Virtual Router Redundancy Protocol，虚拟路由冗余协议)

 一主 + 多备，共用同一个IP地址，但优先级不同



### 三、LVS-DR + Keepalived 构建

#### 3.1  负载调度器 

##### 关闭网卡守护进程

```
service NetworkManager status
service NetworkManager stop
```

##### 拷贝 eth0 网卡子接口充当集群入口接口 

```bash
cd /etc/sysconfig/network-scripts/ && cp ifcfg-eth0 ifcfg-eth0:0

vim !$

DEVICE=eth0:0 
ONBOOT=yes
BOOTPROTO=static
# 设置浮动IP这跟以后的的高可用有关
IPADDR=10.10.10.100
NETMASK=255.255.255.0


ifup eth0:0
```

#####   关闭网卡重定向功能

也就是说代理IP只能是eth0:0所设置的IP，可以不设置，我们后期可以看访问eth0的地址来看一下效果。

```bash
vim /etc/sysctl.conf                            

# lvs 关闭网卡重定向功能
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0

# 刷新内核参数
sysctl -p
```

##### 重载 ipvs 模块

```bash
modprobe ip_vs           
```

##### 安装 ipvsadm 命令行工具

```
rpm -ivh ipvsadm-1.26l......... 
或者 yum -y install ipvsadm
```

#####  集群设置

```bash
# 添加一个集群
ipvsadm -A -t 10.10.10.100:80 -s rr
# 添加 ipvsadm 集群子节点
ipvsadm -a -t 10.10.10.100:80 -r 10.10.10.13:80 -g
ipvsadm -a -t 10.10.10.100:80 -r 10.10.10.14:80 -g
service ipvsadm save
chkconfig ipvsadm on
# 查看路由状态
ipvsadm -Ln --stats

ipvsadm -v   # 查看当前 ipvs 集群内容
```



#### 3.2 真实服务器 

关闭网卡守护进程

```bash
service NetworkManager stop
```

##### 拷贝回环网卡子接口

```bash
cd /etc/sysconfig/network-scripts/  && cp ifcfg-lo ifcfg-lo:0
# 拷贝回环网卡子接口
vim !$     

DEVICE=lo:0
IPADDR=10.10.10.100
# 设置32位子网掩码，让这块网卡自己玩，不进行广播
NETMASK=255.255.255.255
NETWORK=127.0.0.0
# If you're having problems with gated making 127.0.0.0/8 a martian,
# you can change this to something else (255.255.255.255, for example)
BROADCAST=127.255.255.255
ONBOOT=yes
NAME=loopback

```

##### 关闭对应 ARP 响应及公告功能

```bash
vim /etc/sysctl.conf 

# lvs 关闭对应 ARP 响应及公告功能
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_ignore = 1
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.eth0.arp_ignore = 1
net.ipv4.conf.eth0.arp_announce = 2
net.ipv4.conf.eth1.arp_ignore = 1
net.ipv4.conf.eth1.arp_announce = 2
# 刷新内核参数
sysctl -p
# 启动网卡
ifup lo:0  
```

##### 添加路由记录，当访问 VIP 交给 lo:0 网卡接受

```bash
route add -host 10.10.10.100 dev lo:0
echo "route add -host 10.10.10.100 dev lo:0" >> /etc/rc.local
service httpd start
echo "this is .14 server " >> /var/www/html/index.html
```



#### 3.3lvs后台健康检测脚本

```bash
 #!/bin/bash
        #
        VIP=10.10.10.100        #集群虚拟IP
        CPORT=80        #定义集群端口
        FAIL_BACK=127.0.0.1     #本机回环地址
        RS=("10.10.10.13" "10.10.10.14")        #编写集群地址
        declare -a RSSTATUS  #变量RSSTATUS定义为数组态
        RW=("2" "1")
        RPORT=80        #定义集群端口
        TYPE=g  #制定LVS工作模式：g=DR m=NAT
        CHKLOOP=3
        LOG=/var/log/ipvsmonitor.log
        addrs() {
          ipvsadm -a -t $VIP:$CPORT -r $1:$RPORT -$TYPE -w $2
          [ $? -eq 0 ] && return 0 || return 1
        }
        delrs() {
          ipvsadm -d -t $VIP:$CPORT -r $1:$RPORT
          [ $? -eq 0 ] && return 0 || return 1
        }
        checkrs() {
          local I=1
          while [ $I -le $CHKLOOP ]; do
            if curl --connect-timeout 1 http://$1 &> /dev/null; then
              return 0
            fi
            let I++
          done
          return 1
        }
        initstatus() {
          local I
          local COUNT=0;
          for I in ${RS[*]}; do
            if ipvsadm -L -n | grep "$I:$RPORT" && > /dev/null ; then
              RSSTATUS[$COUNT]=1
            else
              RSSTATUS[$COUNT]=0
            fi
          let COUNT++
          done
        }
        initstatus
        while :; do
          let COUNT=0
          for I in ${RS[*]}; do
            if checkrs $I; then
              if [ ${RSSTATUS[$COUNT]} -eq 0 ]; then
                 addrs $I ${RW[$COUNT]}
                 [ $? -eq 0 ] && RSSTATUS[$COUNT]=1 && echo "`date +'%F %H:%M:%S'`, $I is back." >> $LOG
              fi
            else
              if [ ${RSSTATUS[$COUNT]} -eq 1 ]; then
                 delrs $I
                 [ $? -eq 0 ] && RSSTATUS[$COUNT]=0 && echo "`date +'%F %H:%M:%S'`, $I is gone." >> $LOG
              fi
            fi
            let COUNT++
          done
          sleep 5
        done
```



#### 3.4 搭建keepalived

##### 安装相关 keepalived 依赖

```
yum -y install kernel-devel openssl-devel popt-devel gcc*
```

##### 源码安装 Keepalived 软件

```bash
mkdir /mnt/keepalived && mount -o loop Keepalived.iso /mnt/keepalived/

cp -a /mnt/keepalived/* ./
tar -zxf keepalived.....    

cd keep.....

./configure --prefix=/ --with-kernel-dir=/usr/src/kernels/2.6.32........./

make

make install

# 设置 Keepalived 开机自启
chkconfig --add keepalived     

chkconfig keepalived on
```

##### 修改 Keepalived 软件配置

```
# vim /etc/keepalived/keepalived.conf 
global_defs {

    router_id R1#命名主机名

}

vrrp_instance VI--1 {

    state MASTER#设置服务类型主 / 从（MASTER / SLAVE）

    interface eth0#指定那块网卡用来监听

    virtual_router_id 66#设置组号，如果是一组就是相同的ID号，一个主里面只能有一个主服务器和多个从服务器

    priority 100#服务器优先级，主服务器优先级高 官方建议主从相差50

    advert_int 1#心跳时间，检测对方存活

    authenticetion {#存活验证密码

        auth_type PASS

        auth_pass 1111

    }

    virtual_ipaddress {

        192.168.1.100#设置集群地址

    }

}

virtual_server 192.168.1.100 80 {#设置集群地址以及端口号

    delay_loop 6#健康检查间隔

    lb_algorr#使用轮询调度算法

    lb_kind DR#DR模式的群集

    protocol TCP#使用的协议

    real_server 192.168.1.2 80 {#管理的网站节点以及使用端口

        weight 1#权重，优先级在原文件基础上删除修改

        TCP_CHECK {#状态检查方式

            connect_port 80#检查的目标端口

            connect_timeout 3#连接超时（秒）

            nb_get_retry 3#重试次数

            delay_before_retry 4#重试间隔（秒）

        }

    }

    real_server 192.168.1.3 80 {#管理的第二个网站节点以及使用端口

        weight 1#权重，优先级在原文件基础上删除修改

        TCP_CHECK {#状态检查方式

            connect_port 80#检查的目标端口

            connect_timeout 3#连接超时（秒）

            nb_get_retry 3#重试次数

            delay_before_retry 4#重试间隔（秒）

        }

    }

}
```

#### 从lvs搭建

注释网卡启动脚本

```properties
vim /etc/sysconfig/network-scripts/ifup-eth

 #  if ! ARPING=$(/sbin/arping -c 2 -w ${ARPING_WAIT:-3} -D -I ${REALDEVICE} ${ipaddr[$idx]}) ; then
 #         ARPINGMAC=$(echo $ARPING |  sed -ne 's/.*\[\(.*\)\].*/\1/p')
 #         net_log $"Error, some other host ($ARPINGMAC) already uses address ${ipaddr[$idx]}."
 #       exit 1
 #  fi
ifup eth0:0
```

##### 修改从服务器的keepalived配置文件

```
router_id R1#命名主机名
priority 100#服务器优先级，主服务器优先级高 官方建议主从相差50
```

##### 启动主服务器keepalived

##### 启动从服务器ipvsadm

##### 启动从服务器keepalived

测试

`注意ipvsadm工作在内核级别，ipvsadm挂掉相当于机器挂了网络断掉，情况是类似的。`