wget https://storage.googleapis.com/kubernetes-release/release/v1.6.4/bin/linux/amd64/kubectl



wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

```
chmod +x kubectl minikube
mv minikube  kubectl /usr/local/bin
```

```bash
minikube start --registry-mirror=https://registry.docker-cn.com
```

Rpm 

```shell
wget https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -ivh minikube-latest.x86_64.rpm
```

