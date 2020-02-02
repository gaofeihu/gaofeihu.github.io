---
layout:     post
title:  Heartbeat + Nginx
subtitle: Heartbeat + Nginx
date:       2020-1-8
author:     silence
header-img: img/post-linux.png
catalog: true
tags:
    - linux
    - Heartbeat
	- Nginx
---

### 1.Heartbeat + Nginx

#### Heartbeat简介

 Heartbeat 是 Linux-HA 工程的一个组件，自 1999 年开始到现在，发布了众 多版本，是目前开源 Linux-HA项 目最成功的一个例子，在行业内得到了广泛 的应用.

### 环境准备

- [x] 配置时间同步服务

  

- [x] 配置主机名解析(主从都要设置)

  ```properties
  hostname www.feihu1.com
  # vim /etc/sysconfig/network
  NETWORKING=yes
  HOSTNAME=www.feihu1.com
  NTPSERVERARGS=iburst
  
  ```

  

### 2. 安装nginx

##### 安装依赖

```bash
yum install -y pcre pcre-devel zlib zlib-devel openssl-devel gcc gcc-c++
```

##### 添加nginx用户

```bash
useradd -r -s /sbin/nologin -M nginx
```

##### 编译安装

```bash
tar -zxvf nginx-1.2.6.tar.gz
./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_stub_status_module --with-http_ssl_module 
make && make install

#启用 realip 模块（将用户 IP 转发给后端服务器）
--with-http_realip_module
# 添加缓存清除扩展模块
--add-module=../ngx_cache_purge-1.3
# 查看安装了哪些模块
/usr/local/nginx/sbin/nginx -V
```

##### 启动nginx

```bash
echo "this is server 2" >>  /usr/local/nginx/html/index.html
/usr/local/nginx/sbin/nginx
```

### 3.安装Heartbeat

`配置ntp(略过)`

##### 1. 解压安装

```bash
tar -zxvf heartbeat.tar.gz
cd heartbeat
yum -y install *

#配置文件需拷贝到默认目录下
cp -a /usr/share/doc/heartbeat-3.0.4/authkeys  /etc/ha.d/ 
cp -a /usr/share/doc/heartbeat-3.0.4/haresources /etc/ha.d/ 
cp -a /usr/share/doc/heartbeat-3.0.4/ha.cf /etc/ha.d/
```

##### **2）认证服务，节点之间的认证配置，修改** **/etc/ha.d/authkeys** **，在主上修改**

```bash
cd /etc/ha.d/
#生成密钥随机数
dd if=/dev/random bs=512 count=1 | openssl md5 
vim authkeys

auth 1
1 crc
2 sha1 HI!
3 md5 c4e54e54a4d6997602032a41096bb70f

chmod 600 authkeys
```

##### **3）**heartbeat**主配置文件，修改** **/etc/ha.d/ ha.cf** **，** **在主上修改**

```bash
# 修改host文件
vim /etc/hosts
10.10.10.11 www.fehu1.com
10.10.10.12 www.fehu2.com

#vim /etc/ha.d/ha.cf 
bcast eth0
#一主一备节点，需注意能后被两台主机之间解析必须   must match uname -n
node www.fehu1.com
node www.fehu2.com
```

##### **4)** **配置** **haresources** 文件，在主上修改

```bash
vim /etc/ha.d/haresources
www.fehu1.com IPaddr::10.10.10.100/24/eth0:0
```

**5)** **将主三个配置文件拷贝到从上****

```bash
cd /etc/ha.d/
scp ha.cf authkeys haresources root@www.fehu2.com:/etc/ha.d/
```

##### 6)启动服务

```
/etc/init.d/heartbeat start
或者
 service heartbeat start
```



需要注意的是由于nginx工作在用户空间，而Heartbeat检测的只是网络问题，死机或者Heartbeat挂了以后会进行自动切换，而nginx挂掉则不会进行工作切换。

所以我们需要通过一个脚本检测nginx是否还在工作

```bash
#!/bin/bash

PWD=/usr/local/script

URL="http://localhost/"

HTTP_CODE=`curl -o /dev/null -s -w "%{http_code}" "${URL}"` 

if [ $HTTP_CODE != 200 ]
    then
	service heartbeat stop
fi
```

