### 一、查询是否已经安装

```bash
rpm -qa | grep Maria*
# 如果有删除自带的数据库
yum -y remove mari*
rm -rf /var/lib/mysql/*
```

### 二、安装依赖包

```bash
yum groupinstall "Development Tools"

yum install libaio libaio-devel bison bison-devel zlib-devel cmake openssl openssl-devel ncurses ncurses-devel libcurl-devel libarchive-devel boost boost-devel lsof wget
```



### 三、下载和编译jemalloc

```bash
cd /usr/local/src

wget https://github.com/jemalloc/jemalloc/releases/download/4.3.1/jemalloc-4.3.1.tar.bz2

tar jxvf jemalloc-4.3.1.tar.bz2

cd jemalloc-4.3.1

./configure && make && make install
```



### 四、准备目录

这里提前预定MariaDB的**安装目录**为/usr/local/mysql并且**数据库目录**为/data/mysql，这里要建立系统用户及组和数据库存放目录，并且将数据库存放目录赋予mysql用户及组权限，操作如下:（请注意特别说明一下：这里说的数据库目录是指的具体数据库存储文件,而不是安装文件!）

```bash
# 创建maria安装目录
mkdir -p /usr/local/mysql
# 创建数据库存放目录 mkdir -pv /data/mysql/{data,logs/{binlog,relaylog}}
mkdir -p /data/mysql 
# 建立用户，目录，设置权限
groupadd mysql 
useradd -s /sbin/nologin -g mysql -M mysql
# 改变数据库存放目录所属用户及组为 mysql:mysql
chown mysql:mysql /data/mysql -R 

# 以下是上面创建系统用户mysql的各个参数说明：

-r: 添加系统用户( 这里指将要被创建的系统用户mysql )

-g: 指定要创建的用户所属组( 这里指添加到新系统用户mysql到mysql系统用户组 )

-s: 新系统帐户的登录shell( /sbin/nologin 这里设置为将要被创建系统用户mysql不能用来登录系统 )

-d: 新帐户的主目录( 这里指定将要被创建的系统用户mysql的家目录为 /usr/local/mysql )

-M: 不要创建用户的主目录( 也就是说将要被创建的系统用户mysql不会在 /home 目录下创建 mysql 家目录 )
```



### 五、下载、解压并编译安装

下载文件https://mariadb.com/
或
https://downloads.mariadb.org/mariadb/10.2.11/

```bash
# 或者
wget https://mirrors.tuna.tsinghua.edu.cn/mariadb/mariadb-10.5.3/source/mariadb-10.5.3.tar.gz
# 解压
tar xvf mariadb-10.5.3.tar.gz

# 修改目录的权限，让mysql 用户具有全部最高权限。 
chown -R root:mysql /usr/local/mysql/ 
```

### 六、安装执行

#### 编译安装：

```bash
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DSYSCONFDIR=/etc  -DWITHOUT_TOKUDB=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STPRAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1  -DWIYH_READLINE=1 -DWIYH_SSL=system -DVITH_ZLIB=system -DWITH_LOBWRAP=0 -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_BOOST=boost -DMYSQL_USER=mysql -DMYSQL_TCP_PORT=12306

make && make install
```

编译参数详解

```bash
-DCMAKE_INSTALL_PREFIX 是指定安装的位置，这里是/usr/local/mysql //安装根目录

-DMYSQL_DATADIR 是指定MySQL的数据目录，这里是/data/mysql //数据存储目录

-DSYSCONFDIR 是指定配置文件所在的目录，一般都是/etc，具体的配置文件是/etc/my.cnf, //配置文件(my.cnf)目录

-DWITHOUT_TOKUDB=1 这个参数一般都要设置上，表示不安装tokudb引擎，tokudb是MySQL中一款开源的存储引擎，可以管理大量数据并且有一些新的特性，这些是Innodb所不具备的，这里之所以不安装，是因为一般计算机默认是没有PerconaServer的，并且加载tokudb还要依赖jemalloc内存优化，一般开发中也是不用tokudb的，所以暂时屏蔽掉，否则在系统中找不到依赖会出现：CMake

Error at

storage/tokudb/PerconaFT/cmake_modules/TokuSetupCompiler.cmake:179

(message)这样的错误

-DDEFAULT_CHARSET 字符集,这里是utf-8 //默认字符集 

-DDEFAULT_COLLATION排序规则,这里是utf8_general_ci //默认字符校对

-DMYSQL_UNIX_ADDR=/tmp/mysql.sock //UNIX socket文件 

-DMYSQL_TCP_PORT=3306 //TCP/IP端口

-DWITH_ARCHIVE_STORAGE_ENGINE=1 // ARCHIVE 引擎支持

-DWITH_ARIA_STORAGE_ENGINE=1 //ARIA 引擎支持

-DWITH_BLACKHOLE_STORAGE_ENGINE=1 // BLACKHOLE 引擎支持 

-DWITH_FEDERATEDX_STORAGE_ENGINE=1 //FEDERATEDX 引擎支持

-DWITH_PARTITION_STORAGE_ENGINE=1 //PARTITION 引擎支持 

-DWITH_PERFSCHEMA_STORAGE_ENGINE=1 // PERFSCHEMA 引擎支持

-DWITH_SPHINX_STORAGE_ENGINE=1  // SPHINX 引擎支持 

-DWITH_XTRADB_STORAGE_ENGINE=1 // XTRADB支持

-DWITH_INNOBASE_STORAGE_ENGINE=1 // innoDB 引擎支持

-DWITH_MYISAM_STORAGE_ENGINE=1 // Myisam 引擎支持

-DWITH_READLINE=1 //readline库 

-DENABLED_LOCAL_INFILE=1 //启用加载本地数据

-DWITH_EXTRA_CHARSETS=all //扩展支持编码 ( all | utf8,gbk,gb2312 | none ) 

-DEXTRA_CHARSETS=all //扩展字符支持

-DWITH_SSL=system //系统传输使用SSL加密 

-DWITH_ZLIB=system //系统传输使用zlib压缩，节约带宽

-DWITH_LIBWRAP=0	//libwrap库 

-DMYSQL_USER=mysql //运行用户

-DWITH_DEBUG=0 //调试模式 编译引擎选项说明

默认编译的存储引擎包括：csv、myisam、myisammrg和heap。若要安装其它存储引擎，可以使用类似如下编译选项：

-DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1

-DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1

若要明确指定不编译某存储引擎，可以使用类似如下的选项：

-DWITHOUT_<ENGINE>_STORAGE_ENGINE=1

比如：

-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 -DWITHOUT_FEDERATED_STORAGE_ENGINE=1

-DWITHOUT_PARTITION_STORAGE_ENGINE=1

注意：

1）如果上面make需要修改参数，重新编译, 可以删除原来本目录下的CMakeCache.txt

mv CMakeCache.txt CMakeCache.txt.bak

# rm -f CMakeCache.txt

```

cd /usr/local/mysql

#### 查看文件内容:

bin: 可执行的二进制程序的存放目录，客户端程序mysql就位于这个目录下。

data:默认的数据库存放目录，如果我们一开始没有指定数据库存放目录的话，那就会被存储到这个位置。

include：MariaDB 所需要的一些程序文件

INSTALL-BINARY： 安装帮助文档，可以详细阅读，对安装数据库有很大的帮助

lib： 软件运行所需要的库文件

man：软件的帮助文档mysql-test： 数据库的测试组件scipts：mysql初始化初始化时要用到的脚本文件，通读一下脚本，可以了解Mysql 的安装过程

share： 共享的文件内容

support-files： mysql 正常运行所需要的配置文件或者文档，这一点很重要，如果我们要自定义配置文件的话，就需要参考这里面的配置文件来进行定义。

这里有一点需要注意：data目录是数据库的存放路径，我们在之前已经手动指定。在实际生产中，企业数据增长很快，数据库文件有可能会很大，因此最好将该目录指定到一个单独的磁盘上，或者大分区，或者使用逻辑卷都可以，避免因物理空间不足，导致出现故障。



### 七、准备配置文件

MariaDB 的配置文件可以存放在多个路径下面。但是配置文件的查找次序是固定的。这样也就导致了，配置文件具有了优先级，后面的配置会覆盖掉前面的配置(配置参数相同的情况下)。

在mariadb安装目录下的support-files有好几种配置模板，已经配置好的部分参数，分别用于不同的环境，这里简要说明一下：

- **my-small.cnf** 这个是为小型数据库或者个人测试使用的，不能用于生产环境

- **my-medium.cnf** 这个适用于中等规模的数据库，比如个人项目或者小型企业项目中

- **my-large.cnf** 一般用于专门提供SQL服务的服务器中，即专门运行数据库服务的主机，配置要求要更高一些，适用于生产环境

- **my-huge.cnf** 用于企业级服务器中的数据库服务，一般更多用于生产环境使用

>  所以根据以上几个文件，如果个人使用或者测试，那么可以使用前两个模板；企业服务器或者64G以上的高配置服务器可以使用后面两个模板，另外也可以根据自己的需求来加大参数和扩充配置获得更好的性能。
>
> 但是，这些选项文件对于现代服务器而言已经过时，因此在MariaDB 10.3.1中已将其删除。



```bash
# 拷贝配置文件
cp -a /usr/local/mysql/support-files/my-huge.cnf /etc/my.cnf

# 然后在这个配置文件中，加入我们刚刚的指定的一些目录和信息
vim /etc/my.cnf

### 增加如下

datadir = /data/mysq/ 		  # 指定数据库存储的路径

innodb_flush_log_at_trx_commit = 2

innodb_file_per_table = ON  # 将每个表都单独的存储到一个文件中

skip_name_resolve = ON 			# 禁止主机名解析
```

10.3.1以上

```
[Service]
Type=simple
User=mysql 
Group=mysq

[client-server]
socket=/tmp/mysql-dbug.sock
port=12306


[client]
password=123qwe!@#


[mysqld]

default_storage_engine = InnoDB

temp-pool

key_buffer_size=16M
datadir=/data/mysq/
loose-innodb_file_per_table

innodb_flush_log_at_trx_commit = 2

innodb_file_per_table = ON 

skip_name_resolve = ON	

symbolic-links=0


[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

```





`注意：查看配置文件当前有效配置如下`

```bash
sed -e "s/#.*//g" /etc/my.cnf | awk '{if (length !=0) print $0}'

..........

port = 3306 socket = /tmp/mysql.sock

skip-external-locking 

innodb_file_per_table = ON

skip_name_resolve = ON
```



### 八、创建数据库文件，初始化mariadb，初始安全设置

默认情况下,MariaDB安装有一个匿名用户,允许任何人登录MariaDB而他们无需创建用户帐户。这个目的是只用于测试，安装时更平缓一些。你应该在进入生产环境前删除它们。

```bash
 # 安全初始化
 mysql_secure_installation
```

>  已经能够顺利的访问到数据了，甚至匿名访问也是的。可是此时的数据库还是不足够安全的，并不能投入到实际的生产中使用，所以我们需要对数据库进行安全初始化，在创建数据库的同时指定数据库存放目录以及默认用户。

```
cd /usr/local/mysql

./scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/data/mysql --defaults-file=/etc/my.cnf
```

`出现下列信息`

```properties
To start mysqld at boot time you have to copy support-files/mysql.server to the right place for your system

PLEASE REMEMBER TO SET A PASSWORD FOR THE MariaDB root USER !

To do so, start the server, then issue the following commands:

 '/usr/local/mysql//bin/mysqladmin' -u root password 'new-password'

'/usr/local/mysql//bin/mysqladmin' -u root -h Anwar01 password 'new-password'

 Alternatively you can run: '/usr/local/mysql//bin/mysql_secure_installation'

 which will also give you the option of removing the test databases and

anonymous user created by default. This is strongly recommended for

production servers. You can start the MariaDB daemon with: cd

'/usr/local/mysql/' ; /usr/local/mysql//bin/mysqld_safe

--datadir='/data/mysql'

 You can test the MariaDB daemon with mysql-test-run.pl

cd '/usr/local/mysql//mysql-test' ; perl mysql-test-run.pl
```

查看初始化结果：

```
ll /data/mysql
```

切换到我们指定的数据库存放路径下面，可以看到一些相关文件。这里面的每一个路径就是一个数据库。

### 九、准备日志文件

> 因为CentOS 6 和CentOS 7 的日志路径有所不同，所以创建的日志文件的路径也是不一样的。CentOS6 中是/var/log/mysqld.log,而CentOS 7 中则是 /var/log/mariadb/mariadb.log

```powershell
# 创建文件路径
mkdir /var/log/mariadb 

# 创建日志文件
/var/log/mariadb/mariadb.log 

# 修改文件权限
chown mysql /var/log/mariadb/mariadb.log 
```



### 十、配置客户端环境变量

完成了前面的几步操作，我们就已经完成了大部分的工作，此时服务已经启动，我们可以使用ss工具来查看12306端口是否已经开启。但是此时，我们使用mysql 命令通过客户端去访问mysql数据库的话，会提示找不到mysql命令，所以我们要指定一下，mysql 命令的环境变量。

 mysql解压之后一些二进制的可执行文件位于 解压后目录的/bin文件夹下，所以我们将这个路径添加到环境变量中。



```properties
# 编辑profile,将mysql的可执行路径加入系统PATH
vim /etc/profile 

export PATH=/usr/local/mysql/bin:$PATH

source /etc/profile //重读环境变量,使PATH生效。
```



###  十一、设置自动启动脚本并启动服务

 将mysql的服务脚本复制到服务目录下。因为CentOS7 与低版本的服务兼容，所以我们就直接将脚本复制到/etc/init.d/目录下就好。

复制mysql的脚本到服务目录下

```powershell
# 复制mysql服务程序 到系统目录
cp support-files/mysql.server /etc/rc.d/init.d/mysqld 
# 将mysql的服务添加到开机启动中并设置为开机启动
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
service mysqld start|stop|restart
```

> 如果我们没有指定日志文件或者指定了日志文件，但是忘记修改权限的话，这一步都会出错的，不过出错了也不要着急，根据提示信息一点一点来修改就可以了。我们在这一步中将mysql的服务脚本复制到了/etc/rc.d/init.d/路径下，这是因为CentOS 7兼容了CentOS 6 的服务模式。当然也可以按照CentOS7的服务管理方式来进行，配置文件位于**/usr/lib/systemd/system** 路径下。

```powershell
systemctl start mysqld
# 启动
systemctl start mariadb
# 设置开机自启动
systemctl enable mariadb
# 查看进程，mysqld_safe为启动mysql的脚本文件，内部调用mysqld命令
ps aux |grep mysqld |grep -v grep
```

### 十二、检查默认配置和运行情况

```powershell
mysqld --print-defaults
```

信息显示如下：

mysqld would have been started with the following arguments:

--port=3306

 --socket=/tmp/mysql.sock --skip-external-locking --key_buffer_size=256M

 --max_allowed_packet=1M --table_open_cache=256 --sort_buffer_size=1M

--read_buffer_size=1M --read_rnd_buffer_size=4M

--myisam_sort_buffer_size=64M --thread_cache_size=8

--query_cache_size=16M --thread_concurrency=8 --log-bin=mysql-bin

--binlog_format=mixed --server-id=1 --innodb_data_home_dir=/data/mysql

--innodb_data_file_path=ibdata1:10M:autoextend

--innodb_log_group_home_dir=/data/mysql --innodb_buffer_pool_size=256M

--innodb_log_file_size=64M --innodb_log_buffer_size=8M

--innodb_flush_log_at_trx_commit=2 --innodb_lock_wait_timeout=50

--innodb_file_per_table=ON  --skip_name_resolve=ON

\#ss -tlnp|grep :3306

\#lsof |grep jemalloc

### 十三、初始化数据库用户表，连接mariadb使用

原始状态下，管理员root，密码为空，默认只允许从本机登录localhost

```powershell
# 设定root账号及密码,由于原密码为空,因此-p可以不用
mysqladmin -u root password '123qwe!@#' 

# 使用root用户登录
mysql -u root -p

# 切换至mysql数据库。
mysql use mysql

# 查看系统权限
select user,host,password from user;
select * from user;
# 删除不安全的账户
drop user ''@'localhost';
drop user root@'::1'; 
drop user root@127.0.0.1; 
# 再次查看系统权限，确保不安全的账户均被删除。
select user,host,password from user;
# 刷新权限
flush privileges;
show engines;
show VARIABLES like "character_set%";
```



