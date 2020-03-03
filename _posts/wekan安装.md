#### 1. 安装node's

```
useradd -m -d /opt/wekan wekan
passwd wekan
su wekan
wget https://npm.taobao.org/mirrors/node/v10.16.1/node-v10.16.1-linux-x64.tar.xz
```

##### 1.1 解压

```
xz -d node-v10.16.1-linux-x64.tar.xz
tar xvf node-v10.16.1-linux-x64.tar
mv node-v10.16.1-linux-x64 /usr/local/node
```

##### 1.2 环境变量

```
vim ~/.bashrc

export PATH=/usr/local/node/bin:$PATH

node -v
```



### 2. 安装MongoDB



##### 源码安装

```
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-4.0.11.tgz
```

```
tar zxvf mongodb-linux-x86_64-4.0.11.tgz

vim ~/.bashrc

export PATH=/path_to_mongodb/bin:$PATH
source ~/.bashrc

cd /usr/local
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.2.7.tgz
tar -xvf mongodb-linux-x86_64-rhel62-3.2.7.tgz
mv mongodb-linux-x86_64-rhel62-3.2.7 mongodb
```

##### yum安装

```
cd /etc/yum.repos.d
vi /etc/yum.repos.d/mongodb-org-3.2.repo

[mongodb-org-3.2]  
name=MongoDB Repository  
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64/  
gpgcheck=0  
enabled=1  


yum install -y mongodb-org

wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
service mongod start
chkconfig mongod on

```



##### 修改配置文件

```properties
systemLog:
   # verbosity: 0  #日志等级，0-5，默认0
   # quiet: false  #限制日志输出，
   # traceAllExceptions: true  #详细错误日志
   # syslogFacility: user #记录到操作系统的日志级别，指定的值必须是操作系统支持的，并且要以--syslog启动
   path: /data/mongodb/logs/log.txt  #日志路径。
   logAppend: false #启动时，日志追加在已有日志文件内还是备份旧日志后，创建新文件记录日志, 默认false
   logRotate: rename #rename/reopen。rename，重命名旧日志文件，创建新文件记录；reopen，重新打开旧日志记录，需logAppend为true
   destination: file #日志输出方式。file/syslog,如果是file，需指定path，默认是输出到标准输出流中
   timeStampFormat: iso8601-local #日志日期格式。ctime/iso8601-utc/iso8601-local, 默认iso8601-local

processManagement:
   fork: true #以守护进程运行 默认false
   # pidFilePath: <string> #PID 文件位置

net:
   port: 27017 #监听端口，默认27017
   bindIp: 127.0.0.1 #绑定监听的ip，deb和rpm包里有默认的配置文件(/etc/mongod.conf)里面默认配置为127.0.0.1,若不限制IP，务必确保认证安全，多个Ip用逗号分隔
   maxIncomingConnections: 30 #最大连接数，可接受的连接数还受限于操作系统配置的最大连接数
   wireObjectCheck: true #校验客户端的请求，防止错误的或无效BSON插入,多层文档嵌套的对象会有轻微性能影响,默认true
   ipv6: false #是否启用ipv6,3.0以上版本始终开启
   unixDomainSocket: #unix socket监听，仅适用于基于unix的系统
      enabled: false #默认true
      pathPrefix: /tmp #路径前缀，默认/temp
      filePermissions: 0700 #文件权限 默认0700
   # ssl: #一般用不到
   #    sslOnNormalPorts: <boolean>  # deprecated since 2.6
   #    mode: <string>
   #    PEMKeyFile: <string>
   #    PEMKeyPassword: <string>
   #    clusterFile: <string>
   #    clusterPassword: <string>
   #    CAFile: <string>
   #    CRLFile: <string>
   #    allowConnectionsWithoutCertificates: <boolean>
   #    allowInvalidCertificates: <boolean>
   #    allowInvalidHostnames: <boolean>
   #    disabledProtocols: <string>
   #    FIPSMode: <boolean>

security:
   authorization: disabled# enabled/disabled #开启客户端认证
   javascriptEnabled:  true #启用或禁用服务器端JavaScript执行
   

storage:
   dbPath: /data/mongodb/db #数据库，默认/data/db,如果使用软件包管理安装的查看/etc/mongod.conf
   indexBuildRetry: true #重启时，重建不完整的索引
   journal: 
      enabled: true #启动journal,64位系统默认开启，32位默认关闭
      # commitIntervalMs: <num> #journal操作的最大时间间隔，默认100或30
   directoryPerDB: false #使用单独的目录来存储每个数据库的数据,默认false,如果需要更改，要备份数据，删除掉dbPath下的文件，重建后导入数据
   # syncPeriodSecs: 60 #使用fsync来将数据写入磁盘的延迟时间量,建议使用默认值
   engine: wiredTiger #存储引擎，mmapv1/wiredTiger/inMemory 默认wiredTiger
 
operationProfiling: #性能分析
   slowOpThresholdMs: 100 #认定为查询速度缓慢的时间阈值，超过该时间的查询即为缓慢查询，会被记录到日志中, 默认100
   mode: off #operationProfiling模式 off/slowOp/all 默认off
```

```
vim /etc/mongod.conf
 
# mongod.conf
 
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/
 
# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
 
# Where and how to store data.
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:
 
# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
  timeZoneInfo: /usr/share/zoneinfo
 
# network interfaces
net:
  port: 27017
  # 修改ip
  bindIp: 0.0.0.0  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.
```



##### 开启启动

```
cd /etc/init.d
vim mongod
 
#! /bin/bash
# chkconfig: 2345 90 91
# description: Start and Stop mongodb
# processname: mongod
 
EXEC=/usr/bin/mongod
CONF=/etc/mongod.conf
LOCKFILE=/var/lock/subsys/mongod
RETVAL=0
case "$1" in
    start)
        echo -n $"Starting mongod: "
        $EXEC -f $CONF
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch $LOCKFILE
        ;;
    stop)
        echo -n $"Stopping mongod: "
        $EXEC -f $CONF --shutdown
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f $LOCKFILE
        ;;
    restart)
        ${0} stop
        ${0} start
        ;;
    *)
        echo "Usage: /etc/init.d/mongod {start|stop|restart}" >&2
        exit 1
esac
```



### 3.安装wekan

##### 3.1下载

```bash
wget https://releases.wekan.team/wekan-3.80.zip

# vim start_wekan.sh

#!/bin/bash
#配置mongodb链接url，这边配置的是不带账号密码的
export MONGO_URL='mongodb://localhost:27017/wekan'
#访问url
export ROOT_URL='http://10.10.10.11'    
#引入动态链接库，这个可以根据自己的环境配置
#export LD_LIBRARY_PATH=/***/library:$LD_LIBRARY_PATH
#监听端口，80需要root权限
export PORT=80
#启动命令，这边省略了我的路径信息
/usr/local/node/bin/node /usr/local/wekan/main.js > log.txt 2>&1 &

npm install -g node-gyp
/usr/local/node/bin/node /usr/local/wekan/programs/server/node_modules/fibers/build


# 如果报错
yum update libstdc++
```



