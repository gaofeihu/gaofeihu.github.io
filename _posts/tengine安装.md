###  nginx安装

#### 下载相关软件

```
wget https://tengine.taobao.org/download/tengine-2.3.2.tar.gz

tar -zxvf tengine-2.3.2.tar.gz  && cd tengine-2.3.2
```

#### 安装依赖

```bash
yum install -y gcc gcc-c++  openssl-devel  pcre pcre-devel  zlib zlib-devel
```

#### 添加用户

```bash
useradd -M -s /sbin/nologin tengine
```

#### 编译安装

```bash

./configure --prefix=/usr/local/tengine --user=tengine --group=tengine   --with-http_stub_status_module --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module && make && make install

#启用 realip 模块（将用户 IP 转发给后端服务器）
--with-http_realip_module
# 添加缓存清除扩展模块
--add-module=../ngx_cache_purge-1.3
# 查看安装了哪些模块
/usr/local/nginx/sbin/nginx -V
# 配置前可以参考：./configure --help给出说明

```

#### 软连接设置

```bash
# 为了使tengine服务器的运行更加方便，可以为主程序tengine创建链接文件，以便管理员直接执行tengine命令就可以调用Nginx的主程序。

ln -s /usr/local/tengine/sbin/nginx /usr/local/bin/
# 查看软连接是否创建成功
ll /usr/local/bin/nginx  
```

#### tengine服务脚本

```bash
# 为了使tengine服务的启动、停止、重载等操作更加方便，可以编写Nginx服务脚本，并使用chkconfig和systemctl工具来进行管理，也更加符合RHEL系统的管理习惯。

# vim /etc/init.d/tengine

#!/bin/bash

# chkconfig: 2345 99 20

PROG="/usr/local/tengine/sbin/nginx"

PIDF="/usr/local/tengine/logs/nginx.pid"

case "$1" in

start)
         $PROG
;;

stop)
         kill -s QUIT $(cat $PIDF)
;;

restart)
         $0 stop
         $0 start
;;

reload)
         kill -s HUP $(cat $PIDF)
;;

*)
         echo "Usage: $0 {start|stop|restart|reload}"
         exit 1
esac

echo "tengine $1 success!"
exit 0
```

#### tengine服务设置为开机自启

```bash
chmod +x /etc/init.d/tengine

chkconfig --add tengine

chkconfig tengine on

chkconfig --list tengine

#启动nginx 
service tengine start|stop|restart|reload

```

#### 静态服务器配置文件

```bash
user  nginx nginx;

pid logs/nginx.pid;

error_log  logs/error.log  warn;
#nginx默认是没有开启利用多核cpu的配置的。需要通过增加worker_cpu_affinity配置参数来充分利用多核cpu，cpu是任务处理，当计算最费时的资源的时候，cpu核使用上的越多，性能就越好。
worker_processes 8;#开启利用多核CPU,最多开启8个，8个以上性能就不会再提升了，而且稳定性会变的更低，因此8个进程够用了 ，特殊值auto（1.9.10)版本。
worker_cpu_affinity  0001 0010 0100 1000 0001 0010 0100 1000;#允许将工作进程自动绑定到可用的CPU ，特殊值auto（1.9.10)版本

worker_rlimit_nofile 51200;# 该值最大为65535，理论值应该是最多打开文件数（ulimit -n）与nginx进程数相除，但是nginx分配请求并不是那么均匀，所以最好与ulimit -n的值保持一致。

 
events
{
    use epoll;
    multi_accept on;
    worker_connections 51200;# nginx总并发连接数= nginx worker数  *  worker_connections
}
 
http
{
    include       mime.types;
    default_type  application/octet-stream;
    charset utf-8;
    server_tokens off;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 40s;
    client_header_timeout 10;
    client_body_timeout 10;
    client_header_buffer_size 4k;
    server_names_hash_bucket_size 128;
    large_client_header_buffers 4 32k;
    client_max_body_size 100m;
    send_timeout 10;
    reset_timedout_connection on;
    open_file_cache max=102400 inactive=20s;
    open_file_cache_min_uses 1;
    open_file_cache_valid 30s;
 
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 128k;      #出现110错误需要更改相应大小值
    fastcgi_buffers 256 128k;
    fastcgi_busy_buffers_size 256k;    #fastcgi_buffers的两倍
    fastcgi_temp_file_write_size 256k; #fastcgi_buffers的两倍
 
    proxy_connect_timeout 90;
    proxy_send_timeout 90;
    proxy_read_timeout 90;
    proxy_buffer_size 128k;        #出现110错误需要更改相应大小值
    proxy_buffers 256 128k;
    proxy_busy_buffers_size 256k;    #proxy_buffers的两倍
    proxy_temp_file_write_size 256k; #proxy_buffers的两倍
 
    gzip  on;
    gzip_min_length     256;
    gzip_buffers        4 16k;
    gzip_http_version   1.1;
    gzip_vary on;
    gzip_comp_level 5;
    gzip_disable "MSIE [1-6]\.";
    gzip_proxied any;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        image/jpeg
        image/gif
        image/png
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;# text/html根本就不需要写的，gzip默认就会压缩它的
 
    log_format access '{"@timestamp":"$time_iso8601",'
            '"host":"$server_addr",'
            '"clientip":"$remote_addr",'
            '"size":$body_bytes_sent,'
            '"responsetime":$request_time,'
            '"upstreamtime":"$upstream_response_time",'
            '"upstreamhost":"$upstream_addr",'
            '"http_host":"$host",'
            '"url":"$uri",'
            '"xff":"$http_x_forwarded_for",'
            '"referer":"$http_referer",'
            '"agent":"$http_user_agent",'
            '"status":"$status"}';# 这是输出日志为json，方便elk收集
    server {
        listen 80;
        server_name 10.10.10.11;
        access_log off;  # 关闭日志
        return  301 https://$server_name$request_uri; #永久重定向到 https 站点
    }
    
    server {
       listen       443;
       server_name  10.10.10.11;
			 
       ssl   on;# ssl配置
       ssl_certificate       sslkey/fehu.crt;
       ssl_certificate_key   sslkey/fehu.key;
       ssl_session_timeout   5m;
       ssl_protocols TLSv1 TLSv1.1 TLSv1.2 SSLv2 SSLv3;
       ssl_ciphers AESGCM:ALL:!DH:!EXPORT:!RC4:+HIGH:!MEDIUM:!LOW:!aNULL:!eNULL; 
       ssl_prefer_server_ciphers on;
       
       location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ttf|eot|otf|fon|font|ttc|woff|woff2)$ {
          expires 7d;     #过期/缓存时间为7天
          access_log off; # 不记录图片日志
       }
       location ~ .*\.(js|css|html|json)$ {
          expires      12h;   #过期、缓存时间为12小时
          access_log off; # 不记录图片日志
       }
       
       access_log /usr/local/nginx/logs/access.log access; # 日志配置
       error_log /usr/local/nginx/logs/error.log; # 日志配置
       
       index index.html index.php;
       root /html;
       
       server_tokens off; # 关闭服务器版本号
       
       location /nginx_status{ # 状态统计
        stub_status on;
        access_log off; 
        allow 192.168.88.1;
				deny all;
				auth_basic "Welcome to nginx_status!"; 
 				auth_basic_user_file /usr/local/nginx/users/htpasswd.nginx;# 设置用户名和密码
      }
    }
}

```

设置状态统计的访问用户

```bash
# vim /usr/local/nginx/users/htpasswd.nginx
admin:CRJhzBl.eh/0I

# 或者
htpasswd -c /usr/local/nginx/users/htpasswd.nginx 用户名
```



#### 多进程配置

```
两颗CPU参数配置

   worker_processes  2;

   worker_cpu_affinity 0101 1010;

四颗CPU参数配置

   worker_processes  4;

   worker_cpu_affinity 0001 0010 0100 1000;

八颗CPU参数配置

   worker_processes  8;

   worker_cpu_affinity 00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;

八颗CPU参数配置

   worker_processes  8;

   worker_cpu_affinity 0001 0010 0100 1000 0001 0010 0100 1000;
   
# 1.9.0 以上版本可以设置为auto
```

#### 生成SSL证书

```bash
注意:在实验环境中可以用命令生成测试，在生产环境中必须要在 https 证书厂商注册

# 建立服务器私钥，生成 RSA 密钥
openssl genrsa -out fehu.key 2048
# 需要依次输入国家，地区，组织，email。最重要的是有一个 common name，可以写你的名字或者域 名。如果为了 https 申请，这个必须和域名吻合，否则会引发浏览器警报。生成的 csr 文件交给 CA 签 名后形成服务端自己的证书
openssl req -new -key fehu.key -out fehu.csr 
# 生成签字证书
openssl x509 -req -days 3650 -sha256 -in fehu.csr -signkey fehu.key -out fehu.crt

# 将私钥和证书复制到指定位置
```



#### 反向代理配置

```bash
user  nginx nginx;

pid logs/nginx.pid;

error_log  logs/error.log  warn;

worker_processes auto;#开启利用多核CPU,最多开启8个，8个以上性能就不会再提升了，而且稳定性会变的更低，因此8个进程够用了 ，特殊值auto（1.9.10)版本。nginx默认是没有开启利用多核cpu的配置的。需要通过增加worker_cpu_affinity配置参数来充分利用多核cpu，cpu是任务处理，当计算最费时的资源的时候，cpu核使用上的越多，性能就越好。
worker_cpu_affinity  auto;#允许将工作进程自动绑定到可用的CPU ，特殊值auto（1.9.10)版本

worker_rlimit_nofile 51200;# 该值最大为65535，理论值应该是最多打开文件数（ulimit -n）与nginx进程数相除，但是nginx分配请求并不是那么均匀，所以最好与ulimit -n的值保持一致。

 
events
{
    use epoll;
    multi_accept on;
    worker_connections 51200;# nginx总并发连接数= nginx worker数  *  worker_connections
}
 
http
{
    include       mime.types;
    default_type  application/octet-stream;
    charset utf-8;
    server_tokens off;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 40s;
    client_header_timeout 10;
    client_body_timeout 10;
    client_header_buffer_size 4k;
    server_names_hash_bucket_size 128;
    large_client_header_buffers 4 32k;
    client_max_body_size 100m;
    send_timeout 10;
    reset_timedout_connection on;
    open_file_cache max=102400 inactive=20s;
    open_file_cache_min_uses 1;
    open_file_cache_valid 30s;
 
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 128k;      #出现110错误需要更改相应大小值
    fastcgi_buffers 256 128k;
    fastcgi_busy_buffers_size 256k;    #fastcgi_buffers的两倍
    fastcgi_temp_file_write_size 256k; #fastcgi_buffers的两倍
 
    proxy_connect_timeout 90;
    proxy_send_timeout 90;
    proxy_read_timeout 90;
    proxy_buffer_size 128k;        #出现110错误需要更改相应大小值
    proxy_buffers 256 128k;
    proxy_busy_buffers_size 256k;    #proxy_buffers的两倍
    proxy_temp_file_write_size 256k; #proxy_buffers的两倍
 
    gzip  on;
    gzip_min_length     256;
    gzip_buffers        4 16k;
    gzip_http_version   1.1;
    gzip_vary on;
    gzip_comp_level 5;
    gzip_disable "MSIE [1-6]\.";
    gzip_proxied any;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        image/jpeg
        image/gif
        image/png
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;# text/html根本就不需要写的，gzip默认就会压缩它的
 
    log_format access '{"@timestamp":"$time_iso8601",'
            '"host":"$server_addr",'
            '"clientip":"$remote_addr",'
            '"size":$body_bytes_sent,'
            '"responsetime":$request_time,'
            '"upstreamtime":"$upstream_response_time",'
            '"upstreamhost":"$upstream_addr",'
            '"http_host":"$host",'
            '"url":"$uri",'
            '"xff":"$http_x_forwarded_for",'
            '"referer":"$http_referer",'
            '"agent":"$http_user_agent",'
            '"status":"$status"}';# 这是输出日志为json，方便elk收集
    
    
    upstream truck {# 反向代理池
        ip_hash;
        server 10.74.**.**:8080;        
       
    }
    upstream model{# 反向代理池
      server 10.74.**.**:8080;
    }
    
    upstream fastdfs{# 反向代理池
      server 10.74.**.**:8080;
    }

    
    server {
       listen       443;
       server_name  10.10.10.11;
			 
       ssl   on;# ssl配置
       ssl_certificate       sslkey/fehu.crt;
       ssl_certificate_key   sslkey/fehu.key;
       ssl_session_timeout   5m;
       ssl_protocols TLSv1 TLSv1.1 TLSv1.2 SSLv2 SSLv3;
       ssl_ciphers AESGCM:ALL:!DH:!EXPORT:!RC4:+HIGH:!MEDIUM:!LOW:!aNULL:!eNULL; 
       ssl_prefer_server_ciphers on;
       
       location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ttf|eot|otf|fon|font|ttc|woff|woff2)$ {
          expires 7d;     #过期/缓存时间为7天
          access_log off; # 不记录图片日志
       }
       location ~ .*\.(js|css|html|json)$ {
          expires      12h;   #过期、缓存时间为12小时
          access_log off; # 不记录图片日志
       }
       
       access_log /usr/local/nginx/logs/access.log access; # 日志配置
       error_log /usr/local/nginx/logs/error.log; # 日志配置
       
       index index.html index.php;
       root /html;
       
       server_tokens off; # 关闭服务器版本号
    
        
        location ~* /mintaian/datatransmission {#========模型接口===========#
          proxy_pass http://model;
          proxy_set_header Host $host; #重写请求头部，保证网站所有页面都可访问成功 
        	access_log /usr/local/nginx/logs/model/access.log access; # 日志配置
       		error_log /usr/local/nginx/logs/model/error.log; # 日志配置
        }

       
        location ~* /group1 { #代理测试文件服务器
            proxy_pass http://fastdfs;
            proxy_set_header Host $host; #重写请求头部，保证网站所有页面都可访问成功 
            access_log /usr/local/nginx/logs/group1/access.log access; # 日志配置
       		  error_log /usr/local/nginx/logs/group1/error.log; # 日志配置
        }

        location ~* /group2 {
            proxy_pass http://fastdfs;
            proxy_set_header Host $host; #重写请求头部，保证网站所有页面都可访问成功 
            access_log /usr/local/nginx/logs/group2/access.log access; # 日志配置
       		  error_log /usr/local/nginx/logs/group2/error.log; # 日志配置
        }
    
       
        location ~* /file/ { #file
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept';
            root /file;
        }
        
        location ~* / {
          proxy_pass http://truck;
                            proxy_set_header        Host $host:80;
                            proxy_set_header        X-Real-IP $remote_addr;
                            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                            client_max_body_size 400m;
                            proxy_connect_timeout 600;
                            proxy_send_timeout 600;
                            proxy_read_timeout 600;
                            
                            proxy_set_header Upgrade $http_upgrade;
                            proxy_set_header Connection "upgrade"; 
                            proxy_set_header X-Forwarded-Proto  $scheme;
            access_log /usr/local/nginx/logs/truck/access.log access; # 日志配置
       		  error_log /usr/local/nginx/logs/truck/error.log; # 日志配置
          }
       
    }
    
    server {
        listen 80;
        server_name localhost;
        return 301 https://$server_name$request_uri; #永久重定向到 https 站点
    }
}
```



####  服务器伪装

```properties
vim src/http/ngx_http_header_filter_module.c
修改前
static char ngx_http_server_string[] = “Server: nginx” CRLF;
static char ngx_http_server_full_string[] = "Server: " NGINX_VER CRLF;
…
修改后
static char ngx_http_server_string[] = “Server: Fehu” CRLF;
static char ngx_http_server_full_string[] = “Server: Fehu V999” CRLF;


#作为我们商业订购的一部分，从1.9.13版开始，可以使用带变量的字符串显式设置错误页面上的签名和“服务器”响应标头字段值。空字符串将禁用“服务器”字段的发射。

server_tokens on | off | build | string;

```

#### 返回json

```properties
 location /json {
            default_type application/json;
            add_header Content-Type 'text/html; charset=utf-8';
            return 200 '{"status":"success","result":"nginx json"}';
        }
```

​	

#### 自定义错误页面

```properties
# http添加
fastcgi_intercept_errors on;
# server添加
error_page 500 502 503 504 404 /404.html;
```

#### 或者

```properties
	error_page 404 403 503  @err;
	location @err{
		default_type application/json;
		add_header Content-Type 'text/html; charset=utf-8';
	}

```

