### httpd安装

#### 下载相关软件

```
wget http://archive.apache.org/dist/apr/apr-1.6.5.tar.gz

wget http://archive.apache.org/dist/apr/apr-util-1.6.1.tar.gz

wget  http://archive.apache.org/dist/httpd/httpd-2.4.37.tar.gz

tar -zxvf httpd-2.4.37.tar.gz 

tar -zxvf apr-1.6.5.tar.gz  

tar -zxvf apr-util-1.6.1.tar.gz


```

#### 安装依赖

```bash
yum -y install gcc expat-devel  openssl-devel pcre pcre-devel pcre-devel zlib-devel
```

#### 移动

```bash
cp -a apr-1.6.5 httpd-2.4.37/srclib/apr
cp -a apr-util-1.6.1 httpd-2.4.37/srclib/apr-util
```

#### 编译安装

```bash
cd  httpd-2.4.37
./configure --prefix=/usr/local/apache2 --with-included-apr --enable-so --enable-deflate=shared --enable-expires=shared --enable-rewrite=shared --enable-ssl  --enable-mpms-shared=all --enable-cgi   --enable-deflate  --enable-module=most --enable-zlib --with-mpm=event
make && make install 
```

#### 编译安装详解

```properties
# 选择安装目录
--prefix=/usr/local/apache

# 选择安装配置目录
--sysconfdir=/etc/httpd

# 定义apr目录
--with-apr=/usr/local/apr

# 定义apr-util目录
--with-apr-util=/usr/local/apr-util

# 打开 so 模块，so 模块是用来提 DSO 支持的，提供动态共享模块与php协作
--enable-so

# https使用 
--enable-ssl

# 为非线程方式工作的mpm使用
--enable-cgi

# 支持 URL 重写
--enable-rewrite

# 通用压缩机制
--enable-zlib

# 支持pcre 
--with-pcre

# 启用大多数常用的模块
--enable-module=most

# 启用MPM支持的模式,启用哪种mpm(prefork，worker，event)，使用worker或event时要另外一种方式编译php(编 
译时使用了–enable-maintainer-zts选项) 
--enable-mpms-shared=all

# 指定默认的mpm 
--with-mpm=prefork

# 传输压缩机制，节约带宽
--enable-deflate

# 以线程工作（worker/event）的mpm使用
--enable-cgid

--enable-module=so //打开 so 模块，so 模块是用来提 DSO 支持的 apache 核心模块
--enable-deflate=shared //支持网页压缩
--enable-expires=shared //支持 HTTP 控制
--enable-rewrite=shared //支持 URL 重写
--enable-cache   //支持缓存
--enable-file-cache   //支持文件缓存
--enable-mem-cache   //支持记忆缓存
--enable-disk-cache   //支持磁盘缓存
--enable-static-support //支持静态连接(默认为动态连接)
--enable-static-htpasswd //使用静态连接编译 htpasswd - 管理用于基本认证的用户文件
--enable-static-htdigest //使用静态连接编译 htdigest - 管理用于摘要认证的用户文件 
--enable-static-rotatelogs //使用静态连接编译 rotatelogs - 滚动 Apache 日志的管道日志程序 
--enable-static-logresolve //使用静态连接编译 logresolve - 解析 Apache 日志中的IP地址为主机名
--enable-static-htdbm //使用静态连接编译 htdbm - 操作 DBM 密码数据库 
--enable-static-ab //使用静态连接编译 ab - Apache HTTP 服务器性能测试工具
--enable-static-checkgid //使用静态连接编译 checkgid 
--disable-cgid //禁止用一个外部 CGI 守护进程执行CGI脚本
--disable-cgi //禁止编译 CGI 版本的 PHP
--disable-userdir //禁止用户从自己的主目录中提供页面
--with-mpm=worker // 让apache以worker方式运行
--enable-authn-dbm=shared // 对动态数据库进行操作。Rewrite时需要。
```

