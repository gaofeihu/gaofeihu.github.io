```
#!/bin/bash
Info_File=/tmp/ddos_check.log

#从连接数获取
#netstat -lant|awk -F "[ :]+" '/180:80/{clsn[$6]++}END{for(pol in clsn)print pol,clsn[pol]}' >$Info_File

# 从日志获取
awk '{hotel[$1]++}END{for(pol in hotel)print pol,hotel[pol]}' access.log | sort -nk2 -r >$Info_File

while read line 
do 
   Ip_Add=`echo $line |awk '{print $1}'`
   Access=`echo $line |awk '{print $2}'`
   if [ $Access -ge 10000 ]; then
       iptables -I INPUT -s $Ip_Add -j DROP
   elif [ $Access -le 5000 ]; then
       echo "小于5000"
   else
       echo "大于5000小于10000"
   fi
done <$Info_File
```

**需求：**请根据web日志或者或者网络连接数，监控当某个IP并发连接数或者短时内PV达到100，即调用防火墙命令封掉对应的IP。

**防火墙命令为：**iptables-I INPUT -s IP地址 -j DROP。

**脚本实现**