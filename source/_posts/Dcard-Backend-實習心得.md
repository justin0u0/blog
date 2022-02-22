---
title: Dcard Backend 實習心得
date: 2022-01-28 10:57:37
description:
tags:
	- Dcard
categories: Others
---

嗨大家好，我是 Justin，目前就讀清華大學資訊工程學系四年級，在 Dcard 做 backend intern 也半年了，想跟大家分享在 Dcard 實習這半年來的心得～

![Dcard 真的是一間很有活力的公司，Slack 群組常常有各種梗圖xD](/assets/Dcard-Backend-實習心得/slack.png)

在進入 Dcard 之前，因為已經有些後端開發經驗，但是並沒有機會接觸到**高流量**的系統是如何設計與開發的。因此找實習時，主要就是希望能接觸到大型系統開發以及能使用到最新技術。Dcard 在這方面算是非常符合，流量的部分相信不用多做說明，使用的技術部分也是相當的新，包含 Golang、Kubernetes、Microservices、gRPC 以及 OpenTelemetry 這些雲原生生態系最熱門技術 Dcard 都有在使用！

<!-- More -->

# Dcard Backend Team 日常

開發方面，Dcard Backend 目前主要使用 Golang 作為開發語言，但還是有少部分比較早期的 repo 使用 NodeJS。目前都採用 Microservices 架構，對內服務使用 gRPC，對外則是一般的 RESTful API。而 Backend 內部有一套 code generating tool，可以幫助避免 boilerplate code 的撰寫，讓工程師們只需要專注於 business logic 與 architecture design 上。資料庫主要使用 PostgreSQL 以及 Redis。Infra 的部分則是 Kubernetes。

在 Dcard Backend 會用到很多新的技術，例如 Capture Data Change（CDC）就是我在 Dcard 才第一次聽到並且使用到的技術。在 Microservices 中，最難處理的就是跨 services 的資料同步問題。早期 Dcard 內部是使用 event-driven 的方式，也就是透過 application layer 發送訊息到 message queue 中，再由另一端的 service subscribe 並消費這些 events。使用 event-driven 的麻煩之處在於工程師還要自己定義 event 的形式並且撰寫發送與接收的邏輯，另外要確保資料的寫入與 event 是否有同時寫到 message queue 中也是一個難點。現在 Dcard Backend 都大量改用 CDC 來處理這些資料同步化的問題，利用 PostgreSQL 的 logical replication 功能，工程師就只需要專注在訂閱資料的變化即可。

我認為在 Dcard 實習很棒的一點在於，**這邊的工作環境不會讓你感受到因為你是實習生，而就不看重你的意見，或是會讓你感到不敢發言，在這裡各種意見都是歡迎的**，並且大家都會很踴躍的提出看法。舉例來說，因為 Dcard Backend 常常會有一些新技術的使用或是架構上的改進，因此 backend 在每週五都會有一次 sync up 會議進行分享與討論，在這些會議上我也常常能提出很多看法意見～

在 Dcard Backend，**主管也不會因為你是實習生，而派遣一些不重要的工作給你**。像我現在就獨立的待在一個 delivery team 裡面，學習與 PM 溝通開出你認為可以實作的 spec，與 Android/iOS/Web 工程師們溝通適合的 API 並且常常會需要記得為他們考慮向下相容的問題。我目前做過最有趣的專案是抽卡匹配算法的改善，因為自己本身是就是打競賽的，從沒想過真的有一天能將競賽用到的 Dinic 演算法用在實務的 backend 開發上，真的是很有意思。

但如果平時都自己待在 delivery team，要怎麼知道自己的架構設計好不好呢？在**開發大型專案之前，會透過舉辦 Design Review 的形式，大家自由的參加 review 來討論這樣的設計是不是有任何改進的地方**。若在設計上面有任何疑問，公司一些比較資深的前輩或是主管也都非常好相處，有任何不懂的地方就去提問、討論，他們都能提供很棒的建議！

在 Dcard Backend 每兩週會舉辦一次讀書會，像是我剛加入時剛好開始讀一本叫做 *Designing Data-Intensive Application* 的書，最近也剛讀完整本書了。書中講到的各種分散式系統架構下重要的理論，真的是讓我受益良多。我也在讀書會中負責分享了其中的一個章節。對這本書有興趣的也可以去看我的[部落格文章](https://blog.justin0u0.com/tags/DDIA/)，雖然我還剩下很多章節的文章還沒補完😢。

另外，每週五下午會舉辦 developer's session，不同 team 的工程師出來分享一些開發上的知識。例如 backend 分享過 cache-control 的機制讓前端工程師了解為什麼資料不會立即更新；Android 之前分享過如何處理 emoji 字數統計的問題。

# Dcard 公司福利

Dcard 公司福利也是很讚的一部分，吃不完的零食，冰箱飲料有午後時光，每週二五公司請客一杯手搖，每週二還會提供午餐，每週五提供下午茶，特殊節日也會送一堆禮物～

{% img /assets/Dcard-Backend-實習心得/food.jpg 600 600 %}

另外公司的上班時間也很彈性，基本上表定時間是上午 10 點到晚上 7 點，但是有事的話都可以提早離開時數自己補。這樣的制度對還在上學的我真的很讚，不用特地為了考兩小時的期中考請假，直接提早兩小時去上班，在公司直接考試完再繼續工作XD！

# 投 Dcard Backend 實習

如果你有興趣投 Dcard Backend 實習但擔心不知如何準備的，可以去看我的另一篇文章[2021-Dcard-Backend-Intern-面試經驗分享](https://blog.justin0u0.com/2021-Dcard-Web-Backend-Intern-%E9%9D%A2%E8%A9%A6%E7%B6%93%E9%A9%97%E5%88%86%E4%BA%AB/)，相信會對你的準備很有幫助的！有任何疑問也歡迎來找我詢問～

> 最後，如果你喜歡這篇文章，或是文章對你有幫助的話，可以幫我按個喜歡、或是留言！你的支持就是我寫作的最大動力。有任何想問的問題也可以在底下留言喔～
