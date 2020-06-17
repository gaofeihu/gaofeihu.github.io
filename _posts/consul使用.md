```
consul agent -server -bootstrap-expect 2 -data-dir /tmp/consul -node=n1 -bind=10.10.10.51 -ui -config-dir /etc/consul.d -rejoin -join 10.10.10.51 -client 0.0.0.0


consul agent -server -bootstrap-expect 2 -data-dir /tmp/consul -node=n2 -bind=10.10.10.52 -ui  -rejoin -join 10.10.10.51


consul agent -data-dir /tmp/consul -node=n3 -bind=10.10.10.53 -config-dir /etc/consul.d -rejoin -join 10.10.10.51
```



```json
{
  "service": {
    "name": "web",
    "tags": ["master"],
    "address": "127.0.0.1",
    "port": 1000,
    "checks": [
      {
        "http":"http://localhost:10000/health",
        "interval": "10s"
      }
    ]
  }
}
```

```
gaofeihudeMBP:ms silence$ micro new --type "srv"  fehu/micro/rpc/srv
Creating service go.micro.srv.srv in /Users/silence/Downloads/goProject/src/fehu/micro/rpc/srv

.
├── main.go
├── generate.go
├── plugin.go
├── handler
│   └── srv.go
├── subscriber
│   └── srv.go
├── proto/srv
│   └── srv.proto
├── Dockerfile
├── Makefile
├── README.md
└── go.mod


download protobuf for micro:

brew install protobuf
go get -u github.com/golang/protobuf/{proto,protoc-gen-go}
go get -u github.com/micro/protoc-gen-micro

compile the proto file srv.proto:

cd /Users/silence/Downloads/goProject/src/fehu/micro/rpc/srv
protoc --proto_path=.:$GOPATH/src --go_out=. --micro_out=. proto/srv/srv.proto


gaofeihudeMBP:src silence$ micro new --type "web" fehu/micro/rpc/web
Creating service go.micro.web.web in /Users/silence/Downloads/goProject/src/fehu/micro/rpc/web

.
├── main.go
├── plugin.go
├── handler
│   └── handler.go
├── html
│   └── index.html
├── Dockerfile
├── Makefile
├── README.md
└── go.mod

```





#### Apache

- 3.5.2 和3.5.3
  - 怀疑是因为注释中含有Indexes关键字

#### linux

- 定时任务，全部切换到root用户下。删除多余的crontab文件。

#### Weblogic

- ✅.7 日志审计修改为Warning。(待观察如果)
- ❓Session-timeout
- ❓min-pass



### 基线需要改的地方

##### linux

- 定时任务，全部切换到root用户下。删除多余的crontab文件。权限文件中只允许有root

##### Weblogic

- 将所有域的weblogic控制台日志审计等级修改为Warning。
- 删除多余的domain

##### oracle

- .7 .8 .6 定时任务修改
- .5 .6 卸载oracle



- .5 账号超时策略 （5.2.2）
- .6 账号口令策略（5.1.2）



.7.8定时作业修改

明日重点观察：
	早上科室跑批是否成功。