#!/bin/bash
while [ "1" == "1" ]
do
clear
echo "----------------------menu----------------------"
echo "(1) service iptables restart"
echo "(2) iptables add"
echo "(3) iptables delete"
echo "(4) iptables stop"
echo "(5) iptables save(输完ACL后要记得保存和查看)"
echo "(6) iptables status"
echo "(7) iptables ACL list"
echo "(0) exit"
echo "-------------------------------------------------"
echo -n "enter you chose[0-7]:"
read num
if [ ${num} -lt 0 -o ${num} -gt 7 ]
    then
      echo "this is not between 0-7"
else
   if [ "${num}" == "1" ]
      then
      service iptables restart&
else
   if [ "${num}" == "2" ]
#######################################################
       then
          while [ "1" == "1" ]
          do
          clear
          echo "----------------------add ACL----------------------"
          echo "(1) 针对源IP放行添加"
          echo "(2) 针对服务器端口放行添加"
          echo "(3) 针对有端口和服务的ACL添加（这里要参数IP和端口 例如 0/0 80）"
          echo "(4) 自定义添加"
          echo "(5) 退回上一级"
          echo "-------------------------------------------------"
          echo -n "enter you chose[0-4]:"
          read aclnum
          if [ "${aclnum}" == "1" ]
             then
             read ip
             iptables -A INPUT -s ${ip} -p tcp --dport 22 -j ACCEPT
             service iptables save
          elif [ "${aclnum}" == "2" ]
             then
             rad ip
             iptables -A INPUT -p tcp --dport ${IP}  -j ACCEPT
             service iptables save
          elif [ "${aclnum}" == "3" ]
             then
             read ip port
             iptables -A INPUT -p tcp -s ${ip} --dport ${port} -j ACCEPT
             service iptables save
          elif [ "${aclnum}" == "4" ]
             then
             read addacl
             `${addacl}`
             service iptables save
          else
             break
          fi
          echo -n "是否想继续添加: [y/n]:"
          read contine
          if [ "${contine}" == "n" -o "${contine}" == "N" ]
             then
             break
             fi
          done
#######################################################
else
   if [ "${num}" == "3" ]
          then
          while [ "1" == "1" ]
          do
          clear
          echo "---------------------delete ACL----------------------"
          echo "(1) 针对源ip删除"
          echo "(2) 针对端口删除"
          echo "(3) 针对有端口和服务的ACL删除"
          echo "(4) 自定义删除"
          echo "(5) 退回上一级"
          echo "-------------------------------------------------"
          echo -n "enter you chose[0-5]:"
          read aclnum
          if [ "${aclnum}" == "1" ]
             then
             read ip
             iptables -D INPUT -s ${ip} -p tcp --dport 22 -j ACCEPT
             service iptables save
          elif [ "${aclnum}" == "2" ]
             then
             read port
             iptables -D INPUT -p tcp --dport ${port}  -j ACCEPT
             service iptables save
          elif [ "${aclnum}" == "3" ]
             then
             read ip port
             iptables -D INPUT -p tcp -s ${ip} --dport ${port} -j ACCEPT
             service iptables save
          elif [ "${aclnum}" == "4" ]
             then
             read deleteacl
             `${deleteacl}`
             service iptables save
          else
             break
          fi
          echo -n "是否想继续添加: [y/n]:"
          read contine
          if [ "${contine}" == "n" -o "${contine}" == "N" ]
             then
             break
             fi
          done
###################################################################
else
   if [ "${num}" == "4" ]
       then
       echo -e "`service iptables stop&` "
else
   if [ "${num}" == "5" ]
       then
       echo -e "`service iptables save&`"
else
   if [ "${num}" == "6" ]
       then
       echo -e "`service iptables status&`"
else
   if [ "${num}" == "7" ]
       then
         while [ "1" == "1" ]
       do
       clear
       echo "---------------------list ACL----------------------"
       echo "(1) 查看当前正在使用的规则集"
       echo "(2) 查看每个策略或每条规则、每条链的简单流量统计"
       echo "(3) 查看NAT表"
       echo "(4) 自定义查看"
       echo "(5) 退回上一级"
       echo "-------------------------------------------------"
       echo -n "enter you chose[0-5]:"
       read aclnum
       if [ "${aclnum}" == "1" ]
          then
          iptables -L
       elif [ "${aclnum}" == "2" ]
          then
          iptables -L -n -v
       elif [ "${aclnum}" == "3" ]
          then
          iptables -L -t nat
       elif [ "${aclnum}" == "4" ]
          then
          read listacl
          `${listacl}`
       else
        break
         fi
       echo -n "是否想继续添加: [y/n]:"
          read contine
          if [ "${contine}" == "n" -o "${contine}" == "N" ]
             then
             break
          fi
       done
################################################
else   
   exit
fi
  fi
    fi
     fi
      fi
       fi
        fi
         fi
echo -n "Do you contine [y/n]:"
read contine
if [ "${contine}" == "n" -o "${contine}" == "N" ]
   then
   exit
fi
done
