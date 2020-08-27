---
title: Service mesh 服務網格之介紹--微服務中的 TCP
date: 2020-08-27 05:55:42
tags:
  - Kubernetes
  - Istio
  - Service mesh
categories:
  - Kubernetes
---

# Service Mesh

此篇文章為參考 Phil Calçado 所寫之 Pattern: Service Mesh，結合一些自己的想法所寫下。圖片皆來自其文章。

## 原始通訊時代

在人們剛開始接觸網路時，兩台機器之間的溝通可以被想像成下圖：

![/assets/service-mesh/Untitled.png](/assets/service-mesh/Untitled.png)

但漸漸的會發現，機器與機器之間的溝通可能會出現資料遺失、重試等問題，因此需要更複雜的邏輯來處理機器之間的溝通。

<!-- More -->

![/assets/service-mesh/Untitled%201.png](/assets/service-mesh/Untitled%201.png)

當機器越來越普及，工程師們開始思考如何解決多個連線、資料加密、服務發現等問題，以實現一個 Network System。因此機器開始需要實現一個名為 `Flow Control` 的邏輯，用來確認傳輸的速度不會大於接收的速度、處理網路傳輸的資料遺失、資料加密等等問題。因此，服務中除了實現 Business Logic，還開始需要實現 `Flow Control`。

![/assets/service-mesh/Untitled%202.png](/assets/service-mesh/Untitled%202.png)

Services need to implement both business logic & flow control.

為了避免每個服務都要自己實踐一個網路傳輸處理的邏輯，TCP/IP 協議出現了。TCP/IP 解決了網路傳輸的問題，將服務中的 Flow Control 抽象出來，成為網路層的一部分。

![/assets/service-mesh/Untitled%203.png](/assets/service-mesh/Untitled%203.png)

---

## 微服務時代


TCP/IP 作為機器之間的溝通當然還是一個好的工具，然而微服務中的服務發現、熔斷機制等，在 TCP/IP 中都並沒有被實現。

**服務發現**：
在單體式服務中，服務運行在同一個 Process 下，服務發現可以輕易的做到。
要存取其他的服務也能透過 DNS、Load Balancer、Port Number 來取得。
分散式架構中，服務分散在不同的機器上，因此需要有一個方法來找到要存取的服務。
[https://www.nginx.com/blog/service-discovery-in-a-microservices-architecture/](https://www.nginx.com/blog/service-discovery-in-a-microservices-architecture/)

**熔斷機制**：
微服務中一個服務要存取其他服務的資料，例如，服務 A 要存取服務 B，服務 B 要存取服務 C，若服務 C 處在不可運行的狀態，而導致服務 B 不斷的等待服務 C，將導致服務 B 最終無法負荷而崩潰，而服務 B 的崩潰又會導致服務 A 的崩潰，因此產生**雪崩效應**。**熔斷機制**，當服務 B 發現服務 C 不可用時，自動終止其資料請求並回傳錯誤，因為服務 C 有可能在某個時間點恢復運行，因此服務 B 會對服務 C 定期的嘗試取得回應。
[https://microservices.io/patterns/reliability/circuit-breaker.html](https://microservices.io/patterns/reliability/circuit-breaker.html)

因此歷史重演，各個服務開始實現自己的服務發現、熔斷機制邏輯。

![/assets/service-mesh/Untitled%204.png](/assets/service-mesh/Untitled%204.png)

各個服務都要實現自己的服務發現、熔斷機制等邏輯過於麻煩。因此，開始有 Library 的出現來實現這類邏輯。例如：[Twitter's Finagle](https://finagle.github.io/blog/)、[Facebook's Proxygen](https://github.com/facebook/proxygen)。

![/assets/service-mesh/Untitled%205.png](/assets/service-mesh/Untitled%205.png)

然而，使用 Library 也有一些問題存在：

1. 函式庫實現了細節，在實際應用中變更難以追蹤、解決框架出現的問題。
2. 函式庫限制了語言，然而微服務最重要的特性之一就是「與語言無關」。
3. 函式庫的升級、測試、部署都會需要工程師花時間來研究。

---

## Service Mesh

要改變網路的傳輸協議是困難的，因此 Sidecar 的模式被提出，Sidecar 為一個 Proxy，在 Sidecar 中抽象了負載平衡、服務發現、認證授權、流量控制各種分散式服務所需要的邏輯。透過代理的方式來完成服務與服務之間的溝通。

![/assets/service-mesh/Untitled%206.png](/assets/service-mesh/Untitled%206.png)

各種 Sidecar 的實現開始出現，例如：[Linkerd](https://linkerd.io/2016/02/18/linkerd-twitter-style-operability-for-microservices/)、[Envoy](https://eng.lyft.com/announcing-envoy-c-l7-proxy-and-communication-bus-92520b6c8191?gi=41e38b4401fe) 等等。

每個服務旁都有一個 Sidecar 來輔助與其他服務的溝通，全局圖看起來如下。綠色的即為服務，而藍色的部分即為所謂的 **Service Mesh 服務網格**。

![/assets/service-mesh/Untitled%207.png](/assets/service-mesh/Untitled%207.png)

Kubernetes 的出現，讓更多企業、使用者關注並使用 Service Mesh 的服務。因此，一個 Sidecar 的控制面板出現，用來實現更好的 Service Mesh 管控。而 [Istio](https://istio.io/) 即為最佳代表。

![/assets/service-mesh/Untitled%208.png](/assets/service-mesh/Untitled%208.png)

![/assets/service-mesh/Untitled%209.png](service-mesh/Untitled%209.png)

# 結論

---

Service mesh 此詞的發明人 William Morgan 對 **Service Mesh** 的定義如下：
**A service mesh is a dedicated infrastructure layer for handling service-to-service communication. It’s responsible for the reliable delivery of requests through the complex topology of services that comprise a modern, cloud native application. In practice, the service mesh is typically implemented as an array of lightweight network proxies that are deployed alongside application code, without the application needing to be aware.**

可以看到以下三個重點：

1. **Infrastructure layer, through the complex topology of services**
    基礎設施層＋拓樸中穿梭。可以知道 Service Mesh 的定義即為**微服務中的 TCP**！
2. **Network proxies**
    網路代理即為 Service Mesh 的實現方式。
3. **Without the application needing to be aware**
    Service Mesh 中要解決最重要的問題，就是讓開發人員不用再去思考一切關於服務溝通的問題！

# 參考資料
[Pattern: Service Mesh](https://philcalcado.com/2017/08/03/pattern_service_mesh.html)
