

## 安装

#### 1. 安装依赖包

```
yum install -y  gcc gcc-c++ cmake ncurses ncurses-devel bison
```

#### 2. 下载安装包

```
wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.25.tar.gz
```

#### 3. 添加用户

```
useradd  -r -s /sbin/nologin -M  mysql
```

#### 4. 建立所需目录并更改所有者为mysql

```
mkdir -p /data/mysql/data
chown -R mysql:mysql /data/mysql
```

#### 5.将下载好的mysql 解压到/usr/local/mysql 目录下

```
tar -zxvf mysql-boost-5.7.25.tar.gz 
```

#### 6. 切换到mysql目录下，编译安装

```
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DWITH_BOOST=boost 
make && make install
```

修改安装后的目录权限 

```
chown -R mysql:mysql /usr/local/mysql
```



##### 编辑 **Mysql** 配置文件

```
cp -a my.cnf my.cnf.back
```

```properties
[client]
port        = 3306
socket      = /tmp/mysql.sock
default-character-set = utf8mb4

[mysqld]
port        = 12306
socket      = /tmp/mysql.sock
user = mysql

basedir = /usr/local/mysql
datadir = /data/mysql/data
pid-file = /data/mysql/mysql.pid
log_error = /data/mysql/mysql-error.log

slow_query_log = 1
long_query_time = 1
slow_query_log_file = /data/mysql/mysql-slow.log


skip-external-locking
key_buffer_size = 32M
max_allowed_packet = 1024M
table_open_cache = 128
sort_buffer_size = 768K
net_buffer_length = 8K
read_buffer_size = 768K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 16
query_cache_size = 16M
tmp_table_size = 32M
performance_schema_max_table_instances = 1000

explicit_defaults_for_timestamp = true

max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log_bin=mysql-bin
log_bin_trust_function_creators=1
binlog_format=mixed
server_id = 232
expire_logs_days = 10
early-plugin-load = ""

default_storage_engine = InnoDB
innodb_file_per_table = ON
innodb_file_per_table = 1
innodb_buffer_pool_size = 128M
innodb_log_file_size = 32M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect=’SET NAMES utf8mb4’

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
default-character-set=utf8mb4

[myisamchk]
key_buffer_size = 32M
sort_buffer_size = 768K
read_buffer = 2M
write_buffer = 2M
```

##### 2.5** 初始化，生成授权表 

```bash
cd /usr/local/mysql/bin/
#一定要先切换到此目录下，然后再执行下一步。
./mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/data

# 初始化成功标志:两个 ok注:到这一步很容易出问题，在初始化的时候一定要加上面的参数，而且在执行这一步操作前/data/mysql/data 这个目录必须是空的；在这里指定的basedir 和 datadir 目录必须要和/etc/my.cnf 配置的目录一致才行。
```

**2.6** 生成 **Mysql** 的启动和自启动管理脚本 

```bash
cd /usr/local/mysql/support-files
# 切换到 mysql 的源码解压缩目录下的 support-files 
cp -a mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
service mysqld start|stop|restart
```

##### **2.7** 给 **mysql** 的 **root** 用户设置密码 

```bash
# 设定root账号及密码,由于原密码为空,因此-p可以不用
/usr/local/mysql/bin/mysqladmin  -u root password '123qwe!@#' 
```

##### 编辑profile,将mysql的可执行路径加入系统PATH
```bash
vim /etc/profile 

export PATH=/usr/local/mysql/bin:$PATH

source /etc/profile //重读环境变量,使PATH生效。
```



#### root用户远程登录

```
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123qwe!@#'; 
flush privileges; 
```



## 配置

编辑/etc/my.cnf 



#### 选项详解:

```
 #安装位置
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql 
#指定 socket(套接字)文件位置 扩展字符支持
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock 
#默认字符集
-DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 
#默认字符校对
-DDEFAULT_COLLATION=utf8_general_ci 
#安装 myisam 存储引擎
-DWITH_MYISAM_STORAGE_ENGINE=1 
#安装 innodb 存储引擎
-DWITH_INNOBASE_STORAGE_ENGINE=1 
#安装 memory 存储引擎
-DWITH_MEMORY_STORAGE_ENGINE=1
#支持 readline 库
-DWITH_READLINE=1 
#启用加载本地数据
-DENABLED_LOCAL_INFILE=1 
#指定 mysql运行用户
-DMYSQL_USER=mysql 
#指定 mysql 端口
-DMYSQL_TCP_PORT=3306
```

