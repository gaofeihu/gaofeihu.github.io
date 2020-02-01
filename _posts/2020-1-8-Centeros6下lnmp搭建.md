---
layout:     post
title:  Centeros6下lnmp搭建
subtitle: Centeros6下lnmp搭建
date:       2020-1-7
author:     silence
header-img: img/post-linux.png
catalog: true
tags:
    - linux
    - lamp
---

### 1.准备工作 

##### **1.**环境要求:

 操作系统:CentOS6.X 64位
 关闭 SELinux 和 iptables 防火墙
 此次试验环境使用网络 yum 源，保证系统能正常连接互联网 

##### **2.**网络 **yum** 源:

 先将系统自带的 yum 配置文件移除或者删除，然后下载以下两个配置文件

 **官方基础:**

​	wget http://mirrors.aliyun.com/repo/Centos-6.repo

 **epel 拓展:**

​	wget http://mirrors.aliyun.com/repo/epel-6.repo 

下载完成后，需要使用命令清除掉原有的 yum 缓存，使用新的配置文件建立缓存 

```bash
#清除掉原有缓存列表
yum clean all
#建立新的缓存列表
yum makecache 
#将所有能更新的软件更新(非必选)
yum update
```

##### **3.**安装编译工具和依赖软件包: 

```bash
yum -y install gcc* pcre-devel openssl openssl-devel zlib-devel ncurses-devel cmake bison libxml2-devel libpng-devel
```

##### **4. Nginx**、**MySQL**、**PHP** 三大软件的源码包下载地址: 

Nginx:http://nginx.org/en/download.html 

MySQL:https://dev.mysql.com/downloads/mysql/ 

PHP:http://www.php.net/

**版本选用:** 

Nginx: 1.12.* \#选用软件的稳定版即可

Mysql: 5.5.*  \#5.5 以上版本需要 1G 以上的内存，否则无法安装

PHP: 5.6.*  \#LAMP 中我们使用的是 php7，此次使用 php5  

`注意:每次安装 **LNMP** 时，软件包的小版本都不一样，官方会对其大版本下的小版本进行覆盖式更 新，本文内部分链接会失效，切记按照下载版本进行安装。 `

### 二、源码软件包安装 

#### 1.Nginx 

Nginx是一款轻量级的Web 服务器/反向代理服务器及电子邮件(IMAP/POP3)代理服务器，在BSD-like 协议下发行。其特点是占有内存少，并发能力强。


##### **1.1** 下载 **Nginx** 源码包 

```bash
wget http://nginx.org/download/nginx-1.12.2.tar.gz
```

##### **1.2** 创建用于运行 **Nginx** 的用户 

```bash
useradd -r -s /sbin/nologin nginx
```

##### **1.3** 解压缩 **Nginx** 并安装 

```bash
./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_stub_status_module --with-http_ssl_module
make && make install
```

##### **1.4** 上传编写好的 **nginx** 启动管理脚本(见文本尾部) 

```bash
#################################Nginx 启动管理脚本##################################
#!/bin/bash
#path /etc/init.d/nginx
#Author:f
#chkconfig: 2345 99 33
#description: nginx server control tools
ngxc="/usr/local/nginx/sbin/nginx"

pidf="/usr/local/nginx/logs/nginx.pid"

ngxc_fpm="/usr/local/php/sbin/php-fpm"

pidf_fpm="/usr/local/php/var/run/php-fpm.pid"

case "$1" in
start)
	$ngxc -t &>/dev/null
	if [ $? -eq 0 ]; then
		$ngxc
		$ngxc_fpm
		echo "nginx service start success!"
	else
		$ngxc -t
	fi
	;;
stop)
	kill -s QUIT $(cat $pidf)
	kill -s QUIT $(cat $pidf_fpm)
	echo "nginx service stop success!"
	;;
restart)
	$0 stop $0 start
	;;
reload)
	$ngxc -t &>/dev/null
	if [ $? -eq 0 ]; then
		kill -s HUP $(cat $pidf)
		kill -s HUP $(cat $pidf_fpm)
		echo "reload nginx config success!"
	else
		$ngxc -t
	fi
	;;
*)
	echo "please input stop|start|restart|reload."
	exit 1
	;;
esac
```

##### **1.5 上传编写好的 **nginx启动管理脚本(见文本尾部) 

```bash
vim /usr/local/nginx/conf/nginx.conf

# 将nginx的执行用户改变为nginx
user  nginx;

```



#### 2.MySQL 

下载:https://dev.mysql.com/downloads/mysql/ 

选择:MySQL Community Server 5.5 » 

选择:Select Version: 按照自己要求选择 

Select Operating System: Source Code 

Select OS Version: Generic Linux 

格式:mysql-N.N.NN.tar.gz 

\# wget https://cdn.mysql.com//Downloads/MySQL-5.5/mysql-5.5.62.tar.gz 

##### **2.1** 创建用于运行 **Mysql** 的用户:

```bash
useradd -r -s /sbin/nologin mysql 
```

##### **2.2** 解压缩 **Mysql** 并安装: 

```bash
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_USER=mysql -DMYSQL_TCP_PORT=3306 

make && make install
```

##### **2.3** 修改安装后的目录权限 

```bash
cd /usr/local/mysql
chown -R root .
chown -R mysql data
```

##### **2.4** 生成 **Mysql** 配置文件

```bash
cp -a /lnmp/mysql-5.5.62/support-files/my-medium.cnf /etc/my.cnf 
```

##### **2.5** 初始化，生成授权表 

```bash
cd /usr/local/mysql 
#一定要先切换到此目录下，然后再执行下一步。
./scripts/mysql_install_db --user=mysql
# 初始化成功标志:两个 ok
```

**2.6** 生成 **Mysql** 的启动和自启动管理脚本 

```bash
cd /lnmp/mysql-5.5.62/support-files
# 切换到 mysql 的源码解压缩目录下的 support-files 
cp -a mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
service mysqld start|stop|restart
```

##### **2.7** 给 **mysql** 的 **root** 用户设置密码 

```bash
/usr/local/mysql/bin/mysqladmin -uroot password 123456
```

#### 3.PHP安装

##### 下载:http://www.php.net/

```
wget http://tw2.php.net/distributions/php-5.6.38.tar.gz
```

**3.1** 解压缩 **PHP** 并安装**:** 

```bash
./configure --prefix=/usr/local/php/ --with-config-file-path=/usr/local/php/etc/ --with-mysqli=/usr/local/mysql/bin/mysql_config --enable-soap --enable-mbstring=all --enable-sockets --with-pdo-mysql=/usr/local/mysql --with-gd --without-pear --enable-fpm

make &&  install
```

**报错提示:**

​	若遇到 libpng.so not found .报错(老版本的 PHP 会出现此问题) 

**解决方案:**

```
 ln –s /usr/lib64/libpng.so /usr/lib
```

**3.2** 生成 **php** 配置文件 

```bash
cp -a /lnmp/php-5.6.38/php.ini-production /usr/local/php/etc/php.ini
# 复制源码包内的配置文件到安装目录下，并改名即可
```

##### **3.3** 创建软连接，使用 **php** 相关命令是更方便 

```bash
ln -s /usr/local/php/bin/* /usr/local/bin/ 
ln -s /usr/local/php/sbin/* /usr/local/sbin/
```

#### 4.配置 Nginx 连接 PHP(重难点) 

##### **4.1 nginx** 连接 **php** 需要启动 **php-fpm** 服务 

```bash
cd /usr/local/php/etc/
cp -a php-fpm.conf.default php-fpm.conf
#生成 php-fpm 的配置文件，并修改指定参数
vim php-fpm.conf
#修改指定条目的参数:
pid = run/php-fpm.pid 
user = nginx
group = nginx
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
# 启动时开启的进程数、最少空闲进程数、最多空闲进程数(默认值，未修改) 修改 Nginx 启动管理脚本:将 php-fpm 的注释取消掉即可
```

##### **4.2** 修改 **Nginx** 的配置文件，使其识别**.php** 后缀的文件 

```bash
 vim /usr/local/nginx/conf/nginx.conf
#取消下列行的注释，并修改 include 选项的后缀为 fastcgi.conf，并注意每一行结尾的分号和大括号
location ~ \.php$ {
    root           html;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #修改为 fsatcgi.conf
    include        fastcgi_params;
}

```

##### **4.3** 修改 **Nginx** 配置文件，使其默认自动加载 **php** 文件

```bash
 location / {
 	#Nginx的默认网页路径:PREFIX/html 
 	root html; 
 	#设置默认加载的页面，以及优先级
 	index index.php index.html; 
 } 
```

#### 实验 **2**:目录保护

a、原理和 apache 的目录保护原理一样(利用上一个实验接着完成) 

b、在状态统计的 location 中添加: 

```properties
auth_basic "Welcome to nginx_status!"; 
auth_basic_user_file /usr/local/nginx/html/htpasswd.nginx;
```

c、使用 http 的命令 htpasswd 进行用户密码文件的创建(生成在上面指定的位置) 

```bash
htpasswd -c /usr/local/nginx/htpasswd.nginx user
```

#### 实验 **3**:基于 **IP** 的身份验证(访问控制)

 a、接着上一个实验完成操作 

b、在状态统计的 location 中添加: 

```properties
#仅允许 192.168.43.32 访问服务器
allow 192.168.43.32;
deny all;
#deny 192.168.43.0/24;
```

#### 实验 **4**:**nginx** 的虚拟主机(基于域名) 

a、提前准备好两个网站的域名，并且规划好两个网站网页存放目录 

b、在 Nginx 主配置文件中并列编写两个 server 标签，并分别写好各自信息 

```properties
server { 
 listen 80;
 server_name www.sina.com;
 index index.html index.htm index.php; 
 root html/sina;
 access_log logs/sina-access.log main; 
} 
server { 
 listen 80;
 server_name www.sohu.com;
 index index.html index.htm index.php; 
 root html/sohu;
 access_log logs/sohu-access.log main; 
} 
```



#### 实验 **5**:**nginx** 的反向代理

##### 代理和反向代理? 

**代理:**找别人代替你去完成一件你完不成的事(代购)，代理的对象是客户端 .

**反向代理:**替厂家卖东西的人就叫反向代理(烟酒代理) ，代理的对象是服务器端 .

a、在另外一台机器上安装 apache，启动并填写测试页面
b、在 nginx 服务器的配置文件中添加(写在某一个网站的 server 标签内) 

```properties
#此处填写 apache 服务器的 IP 地址
location / {
	proxy_pass http://192.168.88.100:80; 
}
```

c、重启 nginx，并使用客户端访问测试 

#### 实验 **6**:负载调度(负载均衡)

负载均衡(Load Balance)其意思就是将任务分摊到多个操作单元上进行执行，例如 Web 服务器、FTP 服务器、企业关键应用服务器和其它关键任务服务器等，从而共同完成工作任务。

a、使用默认的 rr 轮训算法，修改 nginx 配置文件 

```properties
upstream host_list { 
#此标签在 server 标签前添加 
  server 192.168.43.100:80;
  server 192.168.43.200:80;
}
server {
  ........;
  #修改自带的 location / 的标签，将原内容删除，添加下列两项 
  location / {
  	#添加反向代理，代理地址填写 upstream 声明的名字
    proxy_pass http://host_list; 
    #重写请求头部，保证网站所有页面都可访问成功
    proxy_set_header Host $host; 
 }
}
```

c、重启 nginx，并使用客户端访问测试

拓展补充:rr 算法实现加权轮询(后期集群再讲更多算法类型和功能) 

```
upstream bbs {
  server 192.168.88.100:80 weight=1; 
  server 192.168.88.200:80 weight=2;
}
```

#### 实验 **7**:**nginx** 实现 **https {**证书**+rewrite}

 a、安装 nginx 时，需要将--with-http_ssl_module 模块开启

 b、在对应要进行加密的 server 标签中添加以下内容开启 SSL 

```properties
server { .......;
  ssl on;
  ssl_certificate /usr/local/nginx/conf/ssl/atguigu.crt;
  ssl_certificate_key /usr/local/nginx/conf/ssl/atguigu.key;
  ssl_session_timeout 5m;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ciphers "EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5";
}
```

c、生成证书和秘钥文件 

注意:在实验环境中可以用命令生成测试，在生产环境中必须要在 https 证书厂商注册 

```bash
openssl genrsa -out fehu.key 2048
#建立服务器私钥，生成 RSA 密钥
openssl req -new -key fehu.key -out fehu.csr 
# 需要依次输入国家，地区，组织，email。最重要的是有一个 common name，可以写你的名字或者域 名。如果为了 https 申请，这个必须和域名吻合，否则会引发浏览器警报。生成的 csr 文件交给 CA 签 名后形成服务端自己的证书
openssl x509 -req -days 36500 -sha256 -in fehu.csr -signkey fehu.key -out fehu.crt
# 生成签字证书
# cp atguigu.crt /usr/local/nginx/conf/ssl/fehu.crt
# cp atguigu.key /usr/local/nginx/conf/ssl/fehu.key 将私钥和证书复制到指定位置
```

d、设置 http 自动跳转 https 功能 原有的 server 标签修改监听端口 

```properties
server {
  ..........;
  listen 443;
}
```



新增以下 server 标签(利用虚拟主机+rewrite 的功能) 

```properties
 #https跳转
 server{
   listen 80;
   server_name localhost;
   rewrite ^(.*)$ https://$host permanent;
 }
```



重启测试