---
title: Go-Micro 手把手從開發到部署（上）
date: 2020-10-06 22:36:52
tags:
  - Golang
  - Go-Micro
  - Kubernetes
  - Docker
categories:
  - Go-Micro
---

# 零、前言

本篇文章將使用 Go-Micro 這個 Golang Microservice Framework 來建置一個最基礎的微服務。並部署一個簡單的 HTTP API Server 來作為驗證。

這裡有一個筆者當初一直被混淆的部分：

- Go-Micro

    [https://github.com/micro/go-micro](https://github.com/micro/go-micro)

    是 Go microservices development framework，用來開發微服務，提供 Authentication, Service Discovery, Message Encoding... 微服務所需的功能。而且基本上所有的組件都是可以抽換的。非常方便。

- Micro

    [https://github.com/micro/micro](https://github.com/micro/micro)

    是一個 CLI。不是必要的套件，但是可以快速的生成模板、運行服務、查看服務，micro 是基於 go-micro 開發的，但此篇文章中不會使用到。

另外，筆者之開發環境為 MacOS 10.15.7。

本篇文章的所有程式碼都放在 Github 上：[https://github.com/justin0u0/go-micro-demo](https://github.com/justin0u0/go-micro-demo)

下一篇文章：[Go-Micro-手把手從開發到部署（下）](/Go-Micro-手把手從開發到部署（下）)

<!-- More -->

---

# 一、環境建置

## 環境介紹

```markdown
### Language
- golang v1.14
  - Gin v.1.6.3
  - Go-micro v2.9.1

### Container Orchestration
- docker v19.03.13
- docker-compose v1.27.4
- kubernetes v1.18.3
- minikube v1.12.3

### Communication Protocal
- Protobuf v3.13.0

### Registry
- etcd 
```

## 安裝

### Go

[Download and install](https://golang.org/doc/install)

```bash
# macOS
brew install go

go version
# go version go1.14.6 darwin/amd64
```

### Docker

用來打包完成的微服務。

[Install Docker Desktop on Mac](https://docs.docker.com/docker-for-mac/install/)

```bash
docker version

Client: Docker Engine - Community
 Cloud integration  0.1.18
 Version:           19.03.13
 API version:       1.40
 Go version:        go1.13.15
 Git commit:        4484c46d9d
 Built:             Wed Sep 16 16:58:31 2020
 OS/Arch:           darwin/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.13
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.13.15
  Git commit:       4484c46d9d
  Built:            Wed Sep 16 17:07:04 2020
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v1.3.7
  GitCommit:        8fba4e9a7d01810a393d5d25a3621dc101981175
 runc:
  Version:          1.0.0-rc10
  GitCommit:        dc9208a3303feef5b3839f4323d9beb36df0a9dd
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683
```

### Docker-compose

在 MacOS 上只要安裝完 Docker Desktop for Mac，就會自帶 `docker-compose` 指令。

[Install Docker Compose](https://docs.docker.com/compose/install/)

```bash
docker-compose version

docker-compose version 1.27.4, build 40524192
docker-py version: 4.3.1
CPython version: 3.7.7
OpenSSL version: OpenSSL 1.1.1g  21 Apr 2020
```

### Protobuf

Go-Micro 支持 http, tcp, grpc 通訊協議；支持 json, protobuf, bytes 等編碼方式。

其預設的通訊協議為 http，編碼方式為 protobuf。

[Releases · protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf/releases)

```bash
# macOS
brew install protobuf

protoc --version
# libprotoc 3.13.0
```

### Kubernetes/Minikube

在本地上起一個 Kubernetes 的環境其中一個方式就是安裝 Minikube。

[Install Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

```bash
# macOS
brew install minikube
```

---

# 二、微服務的構建－Proto 文件

我們首先想要完成一個最簡單的 Greeter 服務。

Greeter 服務需要給其一個 Name，之後 Greeter 會回應 `Hello, {Name}`。

在 Go-Micro 中，你需要先定義好 Request, Response 的 Interface，所以我們首先要編寫 Proto 文件。

## 開啟新的 Project

```bash
mkdir go-micro-demo && cd go-micro-demo
mkdir greeter-service && cd greeter-service
export GO111MODULE="on"
go mod init greeter-service

mkdir proto && vim proto/greeter.proto
```

## 生成 Proto 文件

```go
// greeter-service/proto/greeter.proto

syntax = "proto3";

package greeter;
option go_package = "proto;greeter";

service Greeter {
  // 定義 API Interface，Greet 為此 API 的 Name，
  // 代表 給 Greet API Request 當參數，並返回 Response
  rpc Greet(Request) returns (Response) {}
}

// Request 需要攜帶 type 為 string 的參數 name
message Request {
  string name = 1; // 數字不重複即可
}

// Response 會返回 type 為 string 的參數 greeting
message Response {
  string greeting = 2; // 數字不重複即可
}
```

完成後，檔案目錄應該如下：

```bash
.
└── greeter-service
    ├── go.mod
    └── proto
        └── greeter.proto
```

## 生成 Go, Go-Micro 文件

完成 Proto 檔案之後，我們需要 protobuf 幫我們生成需要的 go 文件以及 go-micro 文件。所以我們需要安裝 `protoc-gen-go` 以及 `protoc-gen-micro`。

```go
go get -u github.com/golang/protobuf/protoc-gen-go
go get github.com/micro/micro/v2/cmd/protoc-gen-micro@master
```

Golang 會把指令下載在 `$GOPATH/bin` 之下，因此我們需要將 `$GOPATH/bin` 設定在 `$PATH` 之下：

```bash
export PATH="$PATH:$(go env GOPATH)/bin"
```

完成後，我們即可以利用 Protobuf 幫我們生成需要的文件：

```bash
# go_out file 會生成在 go_out/proto
# micro_out file 會生成在 micro_out/proto
protoc -I . --go_out=. --micro_out=. ./proto/greeter.proto
```

完成後，可以看到 `protoc` 幫我們生成的兩個 Go File。

```bash
.
├── go.mod
└── proto
    ├── greeter.pb.go
    ├── greeter.pb.micro.go
    └── greeter.proto
```

進到 `greeter.pb.micro.go` 檔案，可以看到兩段註解：

```go
// Client API for Greeter service
// Server API for Greeter service
```

我們需要實作的 Interface 即是定義在這邊。

---

# 三、微服務的構建－Go-Micro Server

## Go-Micro 的基本介紹

有了上一篇文章生成的 Go, Go-Micro 文件，我們可以開始編寫 Go-Micro Service。

首先來認識 Go-Micro 這個框架：

![/assets/go-micro.png](/assets/go-micro.png)

- Server：用於接收請求，Server 會向註冊中心(Registry)註冊自己。
- Client：用於發送請求，Client 會向註冊中心尋找已經註冊的服務。
- Registry：註冊中心。用於服務發現。Go-Micro 現在預設的註冊中心為 mdns，但是你可以很方便的改變你的註冊中心。可以使用的註冊中心有 Consul, Etcd, Kubernetes, ZooKeeper...。本文所用的註冊中心即為 Etcd。
- Codec：負責處理傳輸的編碼解碼。預設為 Protobuf，但也支援 JSON, BSON 等等。
- Transport：負責處理服務與服務之間的同步/響應傳輸。預設為 HTTP，支援 RabbitMQ, WebSockets, NATS..
- Broker：負責處理服務的消息發送、訂閱。
- Selector：負責在註冊中心中挑選一個適合的服務進行調用。

## 撰寫 Go-Micro 服務

繼續上一篇的步驟，我們開始撰寫 Go-Micro 的第一個微服務。

創建一個 `main.go`，如下：

```bash
.
└── greeter-service
    ├── go.mod
    ├── go.sum
    ├── main.go # 入口文件
    └── proto
        ├── greeter.pb.go
        ├── greeter.pb.micro.go
        └── greeter.proto
```

```go
package main

import (
  "github.com/micro/go-micro/v2"
  "context"
  "greeter-service/proto" // replace greeter-service if you didn't name greeter-service when go mod init
  "log"
)

// GreeterService ...
type GreeterService struct {}

// Greet ... Implement interface left in proto/greeter.pb.micro.go server part
func (g *GreeterService) Greet(ctx context.Context, req *greeter.Request, res *greeter.Response) error {
  log.Println("Greeter service handle Greet", req.Name)
  res.Greeting = "Hello, " + req.Name
  return nil
}

func main() {
  service := micro.NewService(
    micro.Name("micro.service.greeter"), // The service name to register in the registry
  )

  service.Init()

  // The 'RegisterGreeterHandler' is implement in the proto/greeter.pb.micro.go file
  greeter.RegisterGreeterHandler(service.Server(), &GreeterService{})
  
  if err := service.Run(); err != nil {
    log.Print(err.Error())
    return
  }
}
```

## 運行服務

完成後，我們試著運行 Greeter Service：

```bash
cd greeter-service
go run .
```

結果發生錯誤：

```bash
# github.com/coreos/etcd/clientv3/balancer/resolver/endpoint
/Users/justin/go/pkg/mod/github.com/coreos/etcd@v3.3.18+incompatible/clientv3/balancer/resolver/endpoint/endpoint.go:114:78: undefined: resolver.BuildOption
/Users/justin/go/pkg/mod/github.com/coreos/etcd@v3.3.18+incompatible/clientv3/balancer/resolver/endpoint/endpoint.go:182:31: undefined: resolver.ResolveNowOption
# github.com/coreos/etcd/clientv3/balancer/picker
/Users/justin/go/pkg/mod/github.com/coreos/etcd@v3.3.18+incompatible/clientv3/balancer/picker/err.go:37:44: undefined: balancer.PickOptions
/Users/justin/go/pkg/mod/github.com/coreos/etcd@v3.3.18+incompatible/clientv3/balancer/picker/roundrobin_balanced.go:55:54: undefined: balancer.PickOptions
```

[似乎是 grpc 版本問題](https://github.com/etcd-io/etcd/issues/11563#issuecomment-580196860)，我們在 `go.mod` 加上下面這行：

```go
replace google.golang.org/grpc => google.golang.org/grpc v1.26.0
```

再執行一次：

```bash
go run .

2020-10-06 15:52:23  file=v2@v2.9.1-0.20200723075038-fbdf1f2c1c4c/service.go:211 level=info Starting [service] micro.service.greeter
2020-10-06 15:52:23  file=grpc/grpc.go:887 level=info Server [grpc] Listening on [::]:57713
2020-10-06 15:52:23  file=grpc/grpc.go:718 level=info Registry [mdns] Registering node: micro.service.greeter-8990d2fe-d477-4e61-a5b3-152d846cb488
```

可以看到這時候 Server 已經運行在 57713 這個 Port（而你的不一定會在 57713），也可以看到此 Server 被 register 到預設的 registry mdns 之中。但是由於是 RPC Server，所以還沒有辦法使用類似 Postman 的方式進行簡單的測試。

下一段文中，我們會寫一個 Client 來對此 Server 進行測試。

---

# 四、微服務的構建－Go-Micro Client

上一段文章中，我們利用了 Protobuf 所產生出來的 Go, Go-Micro 文件成功起起了一個 RPC Server。

本篇文章中，我們會利用 Gin 框架，完成我們的 API Server，也就是微服務的內部溝通使用 RPC，而對外使用 HTTP。

## 開啟新的資料夾


[https://github.com/gin-gonic/gin](https://github.com/gin-gonic/gin)

我們想要當 HTTP 對 `/greeter` 發起 GET Request，並攜帶 `name` 為參數時，返回一個 JSON 格式的 Response。

首先，最後部署的時候 Server 與 Client 會分別在兩個 Container/Pod 裡面，因此我們先開一個新的資料夾，並將 `greeter-service` 中的 `proto` 資料夾複製到 Client 中。

```bash
mkdir greeter-api && cd greeter-api
export GO111MODULE="on"
go mod init greeter-api
cp -r ../greeter-service/proto .
```

完成後目錄結構應該為下：

```bash
.
├── greeter-api
│   ├── go.mod
│   └── proto
│       ├── greeter.pb.go
│       ├── greeter.pb.micro.go
│       └── greeter.proto
└── greeter-service
    ├── go.mod
    ├── go.sum
    ├── main.go
    └── proto
        ├── greeter.pb.go
        ├── greeter.pb.micro.go
        └── greeter.proto
```

## 開始撰寫 API

首先，實作一個 RPC Client：

```bash
mkdir client && cd client
vim greet.go
```

```go
// greeter-api/client/greet.go

package client

import (
  "context"
  "github.com/micro/go-micro/v2"
  "github.com/gin-gonic/gin"
  "greeter-api/proto"
  "log"
)

var client greeter.GreeterService

// Init ... In the main function, you should call Init() first,
// so the 'client' defined above can be initialized.
func Init() {
  service := micro.NewService(
    micro.Name("micro.client.greeter"),
  )

  service.Init()

  // NewGreeterService is defined at proto/greeter.pb.micro.go file,
  // "micro.service.greeter" should match the name you defined in the server part.
  client = greeter.NewGreeterService("micro.service.greeter", service.Client())
}

// Greet ...
func Greet(ctx *gin.Context) {
  name := ctx.Query("name") // ctx.Query will return the GET request query string
  log.Println("Client handle Greet, name =", name)

  // Client request the RPC server for response
  res, err := client.Greet(context.TODO(), &greeter.Request{Name: name})
  if err != nil {
    log.Print(err.Error())
    // return with 400 error code and error message
    ctx.JSON(400, gin.H{"message": "server error"})
    return
  }

  // return 200 success code and the response from server
  ctx.JSON(200, gin.H{"message": res.Greeting})
}
```

完成 `Greet` 函數後，我們可以定義 Gin 的 Router 如下：

```bash
mkdir router && cd router
vim router.go
```

```go
// greeter-api/router/router.go

package router

import (
  "github.com/gin-gonic/gin"
  "greeter-api/client"
)

// NewRouter ...
func NewRouter() *gin.Engine {
  route := gin.Default()
  
  // When GET /greeter, handle the request with the Greet function we create above
  route.GET("/greeter", client.Greet)
  return route
}
```

最後編寫入口文件：

```go
// greeter-api/main.go

package main

import (
  "greeter-api/router"
  "greeter-api/client"
  "log"
)

func main() {
  // Remember to call the Init() function to initialize the go-micro client service
  client.Init()
  
  // Start Gin Router at port 3000
  r := router.NewRouter()
  if err := r.Run("0.0.0.0:3000"); err != nil {
    log.Print(err.Error())
  }
}
```

完成後，檔案目錄結構應該如下：

```bash
.
├── greeter-api
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
└── greeter-service
    ├── go.mod
    ├── go.sum
    ├── main.go
    └── proto
        ├── greeter.pb.go
        ├── greeter.pb.micro.go
        └── greeter.proto
```

## 運行服務

試著執行 API Service：

記得上一篇文章中的 Server 也要跑喔～

```bash
go run .

[GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.

[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:	export GIN_MODE=release
 - using code:	gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /greeter                  --> greeter-api/client.Greet (3 handlers)
[GIN-debug] Listening and serving HTTP on 0.0.0.0:3000
```

測試 API Server：

```bash
curl "http://localhost:3000/greeter?name=test"

{"message":"Hello, test"}
```

---

下一篇文章：[Go-Micro-手把手從開發到部署（下）](/Go-Micro-手把手從開發到部署（下）)
