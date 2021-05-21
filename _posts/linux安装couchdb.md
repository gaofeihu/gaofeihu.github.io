



```
wget https://www.apache.org/dyn/closer.lua\?path\=/couchdb/source/3.1.1/apache-couchdb-3.1.1.tar.gz


apk add autoconf autoconf-archive automake 
 
apk add curl-devel erlang-asn1 erlang-erts erlang-eunit
apk add gcc-c++ erlang-os_mon erlang-xmerl erlang-erl_interface help2man js-devel-1.8.5 

apk add libicu-devel libtool perl-Test-Harness
```

```
docker run -d --name my-couchdb -e COUCHDB_USER=admin -e COUCHDB_PASSWORD='123qwe!@#' --restart=always  -p 5984:5984 couchdb 
```

