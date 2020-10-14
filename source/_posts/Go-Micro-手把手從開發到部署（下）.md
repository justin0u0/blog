---
title: Go-Micro 手把手從開發到部署（下）
date: 2020-10-07 09:27:56
tags:
  - Golang
  - Go-Micro
  - Kubernetes
  - Docker
categories:
  - Go-Micro
---

本篇文章主要著重在部署上一篇文章所完成的 Go-Micro 微服務。

上一篇文章：[Go-Micro-手把手從開發到部署（上）](/Go-Micro-手把手從開發到部署（上）)

本篇文章的所有程式碼都放在 Github 上：[https://github.com/justin0u0/go-micro-demo](https://github.com/justin0u0/go-micro-demo)

<!-- More -->

# 五、更改註冊中心為 Etcd

更改註冊中心為 Etcd 能讓我們在最後部署的時候有方便的註冊中心可以使用。

首先我們編寫開發用的 `docker-compose` 檔案：

```bash
// docker-compose.dev.yaml

version: '3.5'

services:
  etcd:
    image: bitnami/etcd:latest
    container_name: etcd
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
      - ETCD_ADVERTISE_CLIENT_URLS=http://etcd:2379
    ports:
      - 2379:2379
      - 2380:2380
```

並執行：

```bash
docker-compose -f ./docker-compose.dev.yaml up -d
docker container ls

CONTAINER ID        IMAGE                 COMMAND                 CREATED             STATUS              PORTS                              NAMES
40a286edc78b        bitnami/etcd:latest   "/entrypoint.sh etcd"   4 seconds ago       Up 2 seconds        0.0.0.0:2379-2380->2379-2380/tcp   etcd
```

接個要更改 Go-Micro 所使用的註冊中心，方法很簡單，只要在 `go run .` 時加上參數 `--registry=etcd` 即可。

因此我們重啟 `greeter-service` 以及 `greeter-api`，可以看到 Registry 部分已經更改為 [etcd]！

```bash
cd greeter-service
go run . --registry=etcd

2020-10-06 17:00:17  file=v2@v2.9.1-0.20200723075038-fbdf1f2c1c4c/service.go:211 level=info Starting [service] micro.service.greeter
2020-10-06 17:00:17  file=grpc/grpc.go:887 level=info Server [grpc] Listening on [::]:58394
2020-10-06 17:00:17  file=grpc/grpc.go:718 level=info Registry [etcd] Registering node: micro.service.greeter-7c93a606-f41e-422c-9e34-1403ee52844b
```

```bash
cd greeter-api
go run . --registry=etcd
```

這裡要注意，Go-Micro 所預設尋找的 Etcd 路徑為 `127.0.0.1:2379`，所以如果你的 Etcd 路徑不在此的話，要加上 `--registry_address=192.0.0.1:1234` 參數（更改 `192.0.0.1:1234` 為你的 Etcd Client Port） 。

為了驗證我們的 Server 有成功 Register 到 Etcd 之中，我們可以到 Etcd 的 Container  之中查看：

```bash
docker exec -it etcd bash

etcdctl get /micro/registry --prefix
```

最後測試結束，關閉 Etcd 服務：

```bash
docker-compose -f ./docker-compose.dev.yaml down
```

---

# 六、撰寫 Dockerfile 以打包映像

完成 `greeter-service` 以及 `greeter-api`，我們可以分別編寫 Dockerfile 來打包映像檔。

本文皆採用 Multi-stage Build 來大幅減少打包出來的映像的大小，有興趣的讀者可以參考 [Docker 官方文件](https://docs.docker.com/develop/develop-images/multistage-build/)。

```docker
# greeter-service/Dockerfile

FROM golang:1.14 AS builder
WORKDIR /app
ENV GO111MODULE=on
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -o greeter-service

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/greeter-service .
ENV PARAMS=""
ENTRYPOINT ./greeter-service $PARAMS
```

```docker
# greeter-api/Dockerfile

FROM golang:1.14 AS builder
WORKDIR /app
ENV GO111MODULE=on
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -o greeter-api

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/greeter-api .
ENV PARAMS=""
CMD ./greeter-api $PARAMS
```

可以看到兩份檔案的倒數兩行，我們使用了 Docker 的 Environment Variable 來為我們的參數預留。因此在使用這兩個 Image 的時候，不要忘記加上 `PARAMS` 這個 Environment Variable。

最後來建立 Docker Image：

```bash
docker build -t greeter-service ./greeter-service
docker build -t greeter-api ./greeter-api

docker images
```

---

# 七、使用 docker-compose 來測試本地部署

撰寫 `docker-compose.yaml` 檔案：

```yaml
version: '3.5'

services:
  greeter-service:
    image: greeter-service:latest
    ports: 
      - 50051:50051 # The opening port
    environment:
      MICRO_SERVER_ADDRESS: ":50051" # Specify the Go-micro server port
      PARAMS: "--registry etcd --registry_address etcd:2379"
    networks:
      - greeter
    depends_on:
      - etcd # Start after Etcd service start
  
  greeter-api-service:
    image: greeter-api:latest
    ports:
      - 3000:3000
    environment:
      PARAMS: "--registry etcd --registry_address etcd:2379"
    networks:
      - greeter
    depends_on:
      - etcd
  
  etcd:
    image: bitnami/etcd:latest
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
      - ETCD_ADVERTISE_CLIENT_URLS=http://etcd:2379
    ports:
      - 2379:2379
      - 2380:2380
    networks:
      - greeter

networks:
  greeter:
    driver: bridge
```

這裡要注意一件事情，在 Docker 中，Container 是無法透過 `localhost` 來互相存取的。要讓 Container 可以互相存取，可以先透過建立一個 Bridge Network，也就是在 `docker-compose.yaml` 中的最下方處：

```yaml
networks:
  greeter:
    driver: bridge
```

即可以建立一個名為 `greeter` 的 network。接著，將需要加入此 network 的 service 都加上

```yaml
networks:
  - greeter
```

後，即可以透過 DNS 來互相 Access，例如 `etcd` 的 Domain 就是 `etcd`，因此連線的 Connection Url 應該變成 `http://etcd:2379` 而非原本的 `127.0.0.1:2379`。

因此在 `greeter-service` 以及 `greeter-api` 的 `environment` 中，都要設 `PARAMS` 為 `--registry=etcd --registry_address=http://etcd:2379`。

最後測試我們的 `docker-compose.yaml`：

```bash
docker-compose up -d
docker container ls

CONTAINER ID        IMAGE                               COMMAND                  CREATED              STATUS              PORTS                              NAMES
a7542f922298        go-micro-demo_greeter-service       "/bin/sh -c './greet…"   About a minute ago   Up About a minute   0.0.0.0:50051->50051/tcp           go-micro-demo_greeter-service_1
b0ccad820ccb        go-micro-demo_greeter-api-service   "/bin/sh -c './greet…"   About a minute ago   Up 3 seconds        0.0.0.0:3000->3000/tcp             go-micro-demo_greeter-api-service_1
4c9e4813ef37        bitnami/etcd:latest                 "/entrypoint.sh etcd"    About a minute ago   Up About a minute   0.0.0.0:2379-2380->2379-2380/tcp   go-micro-demo_etcd_1
```

```bash
curl "http://localhost:3000/greeter?name=test"
                                                                                                                                    ⏎
{"message":"Hello, test"}
```

完成後，專案的目錄結構如下：

```bash
.
├── docker-compose.dev.yaml
├── docker-compose.yaml
├── greeter-api
│   ├── Dockerfile
│   ├── client
│   │   └── greet.go
│   ├── go.mod
│   ├── go.sum
│   ├── main.go
│   ├── proto
│   │   ├── greeter.pb.go
│   │   ├── greeter.pb.micro.go
│   │   └── greeter.proto
│   └── router
│       └── router.go
├── greeter-service
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum
│   ├── main.go
│   └── proto
│       ├── greeter.pb.go
│       ├── greeter.pb.micro.go
│       └── greeter.proto
└── proto
    └── greeter.pb.go
```

---

# 八、使用 Kubernetes 來部署應用

## Minikube 設定

首先，為了方便，我們使用的是 Minikube 作為 Kubernetes Cluster。

而我們會使用到 Kubernetes Ingress，因此需要做以下設置：

```bash
minikube delete
minikube start --vm=true
minikube addons enable ingress
```

建立 Kubernetes  部署用的資料夾：

```bash
mkdir k8s
```

## 設定 Namespace

首先，我們要把應用都部署到 `go-micro` 這個 namespace 之下：

```yaml
# k8s/namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: go-micro
```

```bash
kubectl apply -f ./k8s/namespace.yaml
```

## 設定 Deployment

再來，建構 Deployment，其中有幾個要注意的地方：

1. 這裡可以看到我們將 `spec.template.spec.containers[0].imagePullPolicy` 都設為 `Never`，因為我們需要 Kubernetes 使用本地的 Docker Image，而要讓 Minikube 能獲取本地的 Docker Image，我們需要先執行 `eval $(minikube docker-env)`，並且再執行一次 `docker build -t greeter-api ./greeter-api && docker build -i greeter-service ./greeter-service`
    當然你也可以將 Image Push 到 Cloud Registry，這時你的 `imagePullPolicy` 就要改回 `Always`，或是不設定。
2. 可以看到我們的 `registry_address` 還是保留在 `etcd:2379`。說明了我們在稍後必須利用 Kubernetes Service 來將 Etcd 的 IP DNS 設為 `Etcd`

```yaml
# k8s/deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: greeter-service
  namespace: go-micro
spec:
  selector:
    matchLabels:
      app: greeter-service
  template:
    metadata:
      labels:
        app: greeter-service
    spec:
      containers:
      - name: greeter-service
        image: greeter-service:latest
        imagePullPolicy: Never
        resources:
          limits:
            memory: "32Mi"
            cpu: "50m"
        ports:
        - containerPort: 50051
        env:
        - name: MICRO_SERVER_ADDRESS
          value: ":50051"
        - name: PARAMS
          value: "--registry etcd --registry_address etcd:2379"
---      
apiVersion: apps/v1
kind: Deployment
metadata:
  name: greeter-api
  namespace: go-micro
spec:
  selector:
    matchLabels:
      app: greeter-api
  template:
    metadata:
      labels:
        app: greeter-api
    spec:
      containers:
      - name: greeter-api
        image: greeter-api:latest
        imagePullPolicy: Never
        resources:
          limits:
            memory: "32Mi"
            cpu: "50m"
        ports:
        - containerPort: 3000
        env:
        - name: PARAMS
          value: "--registry etcd --registry_address etcd:2379"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: etcd
  namespace: go-micro
spec:
  selector:
    matchLabels:
      app: etcd
  template:
    metadata:
      labels:
        app: etcd
    spec:
      containers:
      - name: etcd
        image: bitnami/etcd:latest
        resources:
          limits:
            memory: "64Mi"
            cpu: "100m"
        ports:
        - containerPort: 2379
        - containerPort: 2380
        env:
        - name: ALLOW_NONE_AUTHENTICATION
          value: "yes"
        - name: ETCD_ADVERTISE_CLIENT_URLS
          value: "http://etcd:2379"
```

## 設定 Service

Service 需要做到幾件事情：

1. 將 Etcd 設一個 ClusterIP 並且使其擁有 DNS Name = Etcd

    只要 `type=ClusterIP`，Kubernetes 就會為 Service Name 建立一個 DNS，所以 Etcd 的 `metadata.name` 一定要為 `etcd`。

2. 將 greeter-api 設定 NodePort 以能從外面 Access

```yaml
# k8s/service.yaml

apiVersion: v1
kind: Service
metadata:
  name: etcd
  namespace: go-micro
spec:
  selector:
    app: etcd
  ports:
  - name: client
    port: 2379
    targetPort: 2379
  - name: peer
    port: 2380
    targetPort: 2380
---
apiVersion: v1
kind: Service
metadata:
  name: greeter-api
  namespace: go-micro
spec:
  selector:
    app: greeter-api
  type: NodePort
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30012
```

```bash
kubectl apply -f ./k8s/.
```

```bash
curl "$(minikube ip):30012/greeter?name=test"

{"message":"Hello, test"}
```

## 設定 Ingress

最後，我們希望能夠透過一般的 Domain 來 Access API，這時候可以透過 Kubernetes Ingress 來達成。假設 Domain 為 `greeter.go-micro.com`，則：

```yaml
# k8s/ingress.yaml

apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: greeter-api
  namespace: go-micro
spec:
  rules:
  - host: greeter.go-micro.com
    http:
      paths:
      - backend:
          serviceName: greeter-api
          servicePort: 80
```

```bash
kubectl apply -f ./k8s/.
```

測試時，我們可以將本地的 greeter.go-micro.com 映射到 Kubernetes 的 Node IP，也就是 Minikube 的 IP。

```bash
# macOS
echo $(minikube ip) greeter.go-micro.com | sudo tee -a /etc/hosts
dscacheutil -flushcache # refresh /etc/hosts so the change apply immediately
```

```bash
curl "http://greeter.go-micro.com/greeter?name=test"

{"message":"Hello, test"}
```

