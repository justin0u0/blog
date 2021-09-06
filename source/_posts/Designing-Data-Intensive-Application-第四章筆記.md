---
title: Designing Data-Intensive Application 第四章筆記
date: 2021-08-31 23:17:44
description: |
	應用程式是不會永恆不變的，隨著新的 features 加入資料的儲存格式可能改變。因此本章節主要探討第一章節中所提到的 maintainability 中的 evolability。
	本章節會討論在 JSON、XML、Protocol Buffers、Thrift、Arvo 這些資料格式下的相容性問題，以及在 REST、RPC、Message Queue 下如何使用這些資料格式傳輸資料。
tags:
	- Notes
	- DDIA
categories: Notes
mathjax: true
---

應用程式是不會永恆不變的，隨著新的 features 加入資料的儲存格式可能改變。因此本章節主要探討第一章節中所提到的 maintainability 中的 **evolability**。

在 relational database 中，通常需要更新 schema；而在 schemaless database 中，新舊版本的資料格式可以同時存在。

Application code 也會因為資料格式的改變而有所變化，但是在大型應用程式中，做到瞬間的版本更新是不可能的：

- Server side applications：通常會執行 **rolling upgrade**，因此新舊版本的程式會通時運作。

	{% note info %}
	#### Rolling Upgrade

	透過逐漸部署新版本到 server，確認新版本正常運作後，才逐漸移除舊版本的部署，以達到 zero-downtime 的版本升級。
	{% endnote %}

- Client side applications：是否更新取決於使用者，因此會同時擁有多種版本在運作。

以上兩點就說明了在軟體開發中，相容性的重要性。相容性包含兩個方向：

- **Backward compatibility（向下相容）**：新的程式碼可以讀舊的資料。
- **Forward compatibility（向上相容）**：舊的程式碼可以讀新的資料。

本章節會討論在 JSON、XML、Protocol Buffers、Thrift、Arvo 這些資料格式下的相容性問題，以及在 REST、RPC、Message Queue 下如何使用這些資料格式傳輸資料。

<!-- More -->

# Formats for Encoding Data

資料在程式中以 objects、structs、lists、hash tables、trees 等格式儲存在 memory 中，這些資料結構經常透過 pointers 來存取資料。但是透過網路傳輸資料時，這些資料必須轉換成 sequences of bytes（例如 JSON）

<strong>這種從 in-memory 結構轉換到 byte sequence 的過程叫做 *encoding*、*serialization* 或是 *marshalling*；反過來則叫 *decoding*、*deserialization* 或是 *unmarshalling*。</strong>

## Language-Specific Formats

一些 programming language 有自己的 encoding 方式，例如 Java 中的 `java.io.Serialiable`。使用這些 encoding 很方便，但是可能有以下問題：

- Language-specific encoding 通常只能在一個 langauge 使用，要使用其他 language 讀取是很困難的。
- 這些 encoding 通常不支援資料的上下相容。
	
	{% note info %}
	#### Golang gob library

	Golang 內建的 encoding `gob` 可以自動忽略 `struct` 中新增或是刪除的欄位，可以做到一些上下相容。

	例如 encode 端的結構長這樣：
	```go
	struct { A, B int } // encode
	```

	在 decode 端以下情況都是被允許的：
	```go
	struct { A, B int, C string } // new field
	struct { A int } // missing field
	```

	{% endnote %}

## JSON, XML and Binary Variants

接著介紹一些標準的 encoding 方式，例如 JSON、XML、CSV。他們被設計成 human-readable 的格式，被大多數的語言支援，並且被廣泛的使用，但是也有一些各自的問題存在：

- XML、CSV 無法區分數字以及只包含數字的字串；JSON 無法區分整數以及浮點數。
- XML、JSON 都不支援 **binary encoding**。

但這些問題依然不影響 JSON、XML 或是 CSV 在資料交換上的使用（尤其是跨機構的），**因為他們被廣泛的支援以及認可，這比起效能或是格式的問題還要重要**。

### Binary encoding

上面有提到，XML 與 JSON 都不支援 **binary encoding**，但是在跨機構的資料交換上面，被廣泛使用以及支援的格式比起效能或格式問題更重要。反之，在機構內自己使用，就可以多去考慮效能的問題。

JSON 雖然比 XML 好，但是比起 binary encoding format 還是多使用了很多空間，因此出現了一些 JSON binary encoding 的實作，例如 [MessagePack](https://msgpack.org/)、[BSON](https://docs.mongodb.com/manual/reference/bson-types/)、[BJSON](http://bjson.org/) 等等。

舉例來說，原本的 JSON 資料如下：

```json
{
	"userName": "Martin",
	"favoriteNumber": 1337,
	"interests": ["daydreaming", "hacking"]
}
```

扣除掉空白字元以及換行後，一共使用 81 個字元。

```javascript
const s = '{"userName":"Martin","favoriteNumber":1337,"interests":["daydreaming","hacking"]}';
console.log(s.length); // 81
```

而 MessagePack encode 過後的結果如下：
![MessagePack](/assets/Designing-Data-Intensive-Application-第四章筆記/message_pack.png)

一共只使用 66 個字元。

{% note %}
	#### 補充關於 MessagePack 編碼方式

	[MessagePack encoding](https://github.com/msgpack/msgpack/blob/master/spec.md)

	- MessagePack 用二進位 `1000xxxx` 代表 JSON Object，其中 `xxxx` 代表 object 的 keys 數量，因此可以看到第一個編碼為 83 (`10000011`)，代表是一個 JSON Object 包含 3 個 keys。
		那如果 keys 數量超過 15 個呢？則會使用 `0xde`（有小於 2^16 個 keys）或是 `0xdf`（有小於 2^32 個 keys）當作第一個編碼字元，再接著 keys 的長度。
		[MessagePack encoding - Map format](https://github.com/msgpack/msgpack/blob/master/spec.md#int-format-family)
	
	- MessagePack 對小於 2^7 的無號正整數使用 `0xxxxxxx` 編碼、對於小於 2^5 的有號整數使用 `111xxxxx` 做編碼，其中 `x` 的部分代表數字，這兩種都只使用了一個 byte 做編碼。另外對於小於 8bits、16bits、32bits、64bits 的整數與正整數都用一個不同 first byte 做區別，分別使用 2、3、5、9 個 bytes。
		[MessagePack encoding - Integer format](https://github.com/msgpack/msgpack/blob/master/spec.md#int-format-family)

	- MessagePack 對於不同長度的 string 也對不同長度範圍的字串使用不同的 first byte 來編碼。
		[MessagePack encoding - String format](https://github.com/msgpack/msgpack/blob/master/spec.md#str-format-family)
{% endnote %}

## Thrift and Protocol Buffers

Thrift 和 Protocol Buffers（protobuf）都是開源的 binary encoding libraries，他們都必須透過 schema 先定義好資料的格式才能做 encoding。

### Thrift

Thrift 的 schema 定義如下：

```thrift
struct Person {
	1: required string userName,
	2: optional i64 favoriteNumber,
	3: optional list<string> interests
}
```

而 protobuf 的 schema 定義如下（作者這裡提供的是 proto2 的語法，在 proto3 `required` 與 `optional` 已經棄用）：
```protobuf
message Person {
	required string user_name       = 1;
	optional int64  favorite_number = 2;
	repeated string interests       = 3;
}
```

透過 schema 的定義，Thrift 和 Protobuf 都透過 code generation 工具來生成 schema 在不同語言的實作，包含可以儲存 data 的 in-memory 格式（golang struct、jave class 等）以及 encoding 和 decoding 的函數。

Thrift 有兩種 encoding 模式，分別是 *BinaryProtocol* 與 *CompactProtocol*。

![Thrift - binary protocol](/assets/Designing-Data-Intensive-Application-第四章筆記/thrift_binary_protocol.png)

Thrift 在使用 BinaryProtocol 時，只使用了 59 bytes，相較於 MessagePack 的 65 bytes 又少了一些。

**可以發現使用 schema 後，優勢在於不需要像 JSON、XML 的 encoding 一樣儲存 key name（例如 `userName`），轉而儲存 field tag。也因此不管是 Thrift 還是 Protobuf，都可以看到每個 key 都會有一個 unique 的 field tag。**

![Thrift - compact protocol](/assets/Designing-Data-Intensive-Application-第四章筆記/thrift_compact_protocol.png)

Thrift 使用 CompactProtocol 甚至只需要 34 bytes 就可以儲存相同的資料。可以發現在 CompactProtocol 做了這些空間優化：

- 把 field tag 跟 field type encode 在同一個 byte 內。
- 關於整數的部分（包含表示字串長度的整數），使用了 zig-zag 整數壓縮，再透過 Base 128 Varint 的方式傳輸。

	{% note info %}
	#### ZigZag 與 Base 128 Varint

	這裡作者給的 schema 中，`favorite_number` 是 `int64` 有號整數，根據 [Thrift 提供的 spec](https://github.com/apache/thrift/blob/master/doc/specs/thrift-compact-protocol.md#integer-encoding)，`int32` 與 `int64` 都會做 zig-zag encoding。所以 1337 的部分編碼過後應該是 `11110010 00010100` 才對。

	關於 ZigZag 整數壓縮與 Base 128 Varint 的詳細介紹，可以看筆者的另一篇 blog：[神奇的整數壓縮算法-ZigZag](/神奇的整數壓縮算法-ZigZag)
	{% endnote %}

### Protocol buffers

![Protobol buffers](/assets/Designing-Data-Intensive-Application-第四章筆記/protobuf.png)

基本上 Protocol Buffers 的 encode 方式與 Thrift 中的 CompactProtocol 類似，特別注意兩點：

- [Protobuf 的文件](https://developers.google.com/protocol-buffers/docs/encoding#signed_integers)中有提到如果使用的是 `int32` 或是 `int64` 類型的話，負數都會使用完整的 10 個 bytes，只有在選擇 `sint32` 或是 `sint64` 這兩種 signed types 時才會使用 zig-zag encoding，會有更好的壓縮率。
- 不管是 `required` 或是 `optional` 都不會對 encode 後的 data 產生影響，`required` 跟 `optional` 的作用只有 runtime 時的檢查而已。也因為 `required` 與 `optional` 在 schema evolution 時造成不便（下面會介紹到），因此 protocol buffers 3 時 `required` 與 `optional` 都被移除。
	[Why required and optional is removed in Protocol Buffers 3?](https://stackoverflow.com/a/31814967)

### Field tags and schema evolution

每次的 schema change 都稱作 *schema evolution*，field name 是可以更改的，但是 field tag 不能更改。

- Forward compatibility（舊版本可以相容新版本資料）：
	- 可以增加新的 field，因為舊版本可以直接 omit 不認識的 field tag。
	- 可以刪除 optional 的 field，一個 `required` 的 field 不能被移除。刪除一個 `required` 的 field 會讓舊版本 code 讀到新版本資料時因為該 field 不存在而報錯。

- Backward compatibility（新版本可以相容舊版本資料）：
	- 可以增加新的 field，但是不能增加 `required` 的 field。增加一個 `required` 的 field 會讓新版本 code 讀到舊版本資料時因為該 field 不存在而報錯。
	- 可以刪除一個 field，因為新版本會直接 omit 不認識的 field tag。

刪除一個 field 後，該 field tag 也不能再被使用，因為可能還有舊的資料是使用者個 field tag 的。

### Datatypes and schema evolution

對於同樣的 field，一些資料型態的轉變是 ok 的：

- 從 int32 變成 int64 對於新版本程式是沒有問題的，但是舊版本程式若讀到 int64 的資料就會遺失高位的 bits。
- 在 protobuf 中使用 `repeated` 作為 array type，而實際上被 encode 時可以看到只是相同的 field tag 出現多次而已，因此在 protobuf 中把 `optional` 轉成 `repeated` 是可以的。新版本可以讀到舊的資料，而舊版本只會讀到 list 中的最後一筆資料。而在 thrift 中有 list 的 type，因此是無法做轉變的。

## Arvo

Apache Arvo 是另一種與 Thrift 和 Protocol Buffers 不太一樣的 binary encoding 格式。Arvo 也使用 schema，有比較適合人類使用的 Arvo IDL 與比較適合程式使用的 JSON 格式：

```arvo
record Person {
	string userName;
	union { null, long } favoriteNumber = null;
	array<string> interests;
}
```

```json
{
	"type": "record",
	"name": "Person",
	"fields": [
		{"name": "userName", "type": "string"},
		{"name": "favoriteNumber", "type": ["null", "long"], "default": null},
		{"name": "interests", "type": {"type": "array", "items": "string"}}
	]
}
```

![Arvo](/assets/Designing-Data-Intensive-Application-第四章筆記/arvo.png)

可以注意到 Arvo 沒有 tag number，並且 Arvo 在 encode 時也不會儲存 field name，所以 encode 和 decode 時 schema 需要匹配才能使用。

### The writer's schema and the reader's schema

Encode 與 decode 可以使用不同 schema，但 decode 時必須擁有當時 encode 用的 schema。而 decode 端的 schema 稱為 *reader's schema*，當時 encode 所使用的 schema 稱為 *writer's schema*。

![Arvo reader's and writer's schema](/assets/Designing-Data-Intensive-Application-第四章筆記/arvo_reader_writer_schema.png)

可以看到透過比對 field name，decode 時可以使用與 encode 不同的 schema。例如 writer's schema 中有 reader's schema 中不存在的 field `photoURL`，則 reader 忽略此欄位；或是 reader's schema 中有 writer's schema 中不存在的 field `userID`，則使用預設值。

### Schema evolution rules

Arvo 中：

- Forward compatibility：舊版本 reader's schema 與新版本 writer's schema。
- Backward compatibility：新版本 reader's schema 與舊版本 reader's schema。

要同時滿足兩種相容性，只能新增或刪除有 default value 的值。

### But what is the writer's schema

那麼 writer's schema 會儲存在哪裡呢？根據 Arvo 常被使用的情境，有以下幾種例子：

- File：常被使用在 Hadoop 中，Hadoop 是大型檔案系統。因此 writer's schema 可以直接被寫在檔案的 header 中。
- Database：在 database 中，每個 rows 可以多儲存一個 version number，再透過 version number 關聯出寫入時的 writer's schema。
- Network：透過網路傳輸的話，可以透過 RPC 的方式。

### Dynamically generated schemas

Arvo 與 Thrift 或是 Protocol Buffers 最大的不同在於 Arvo 適合做 *dynamically generated schema*，而 Thrift 或是 Protocol Buffers 因為有 tag number 要小心不能重複使用到，因此通常只能手動修改 schema。

## The Merits of Schemas

總結來說有 schemas 帶來以下的好處：
- 有更好的壓縮率，因為不需要儲存 field name。
- 本身就是有價值的文件，因為 schema 必須跟著 code 一起被版本更新。
- 維護一個 schemas 的資料庫，可以讓開發者在部署之前確認所有的相容性。
- 對於 statically typed programming languages 來說，code generation 可以幫助編譯期間的 type checking。

# Modes of Dataflow

接著介紹三種類型的 Dataflow：

- Via databases
- Via services
- Via asynchronous message passing 

## Dataflow Through Databases

資料進出資料庫時也需要做 encode 和 decode，因此也要考慮相容問題。

假設新版本新增了一個 field，並且寫了一筆資料到資料庫。而舊版本程式讀到這筆資料後，選擇 omit 不認識的 field，再更新回資料庫，那麼這個新的 field 上面的值就會遺失。

要避免這種情況，可以指定要更新的 fields 而不是一次更新整筆資料（Relational database 中 ORM 的 Save 通常就是更新一整筆資料，可以透過 Update 來更新需要的欄位就好）。

## Dataflow Through Services: REST and RPC

當資料傳輸需要透過 network，server 通常會暴露 API 在網路上，client 可以透過 API 向 server 拿取或是送出資料。而 client 可能也是一個 server 的角色，這種 pattern 被稱作 *service-oriented architecture (SOA)*，或是被稱作 *microservices*。*Microservices* 的主要目的之一就是讓每個 services 都可以獨立部署和更新，因此相容性在 API 設計上也是很重要的。

### REST

Web services 主要透過 REST 來設計 API，這種類型的 API 被稱作 RESTful API。

[REST](https://zh.wikipedia.org/wiki/%E8%A1%A8%E7%8E%B0%E5%B1%82%E7%8A%B6%E6%80%81%E8%BD%AC%E6%8D%A2) 是基於 HTTP 的一種設計方式，使用 URI 來辨識資源，對於資源的操作包含取得、建立、修改和刪除，恰好對應到 HTTP 的 `GET`、`POST`、`PUT` 和 `DELETE`方法。

在版本更新時，若無法做到相容，RESTful APIs 通常透過 URI 中的 version number 來提供多版本的 APIs。

### RPC

早期的 RPC 設計希望透過網路的請求使用起來跟呼叫 local function 很像，但其實這很難做到，因為有以下的差別：

- Local function 是可預期結果的，RPC 可能因為 network issue 有很多無法預期的結果（例如遺失、等待很久才回應...）。
- RPC 在遇到 error 時可以重試，但是上一次的結果可能是成功的，只是沒有成功回應結果。重試就要避免一些無法重複執行的請求重複執行。
- Local function 每次執行時間差不多；RPC 每次執行時間可能被 network latency 影響而差別很大。
- Local function 可以使用 pointers 或是 references；RPC 需要將 parameter 轉換成 sequence of bytes。

雖然 RPC 有上面提到的這些問題，但是新型的 RPC frameworks 並沒有就此沒落，例如 Google gRPC。因為這些新型的 RPC frameworks 更明確的區分 RPC 並不是一種 local function call，例如 [Finagle](https://twitter.github.io/finagle/) 提供 `futures` 來封裝可能失敗的請求。

gRPC 使用 protocol buffers encoding，比起 REST JSON 有更好的效能。但是缺點在於不易 debug 與實驗，因為 RPC 測試通常需要透過程式或是 code generation 工具。

RPC 中若使用 Thrift 或是 Protocol Buffers，則可以依照 schema evolution 的規則來做到上下相容。

## Message-Passing Dataflow

REST & RPC 都透過網路傳遞訊息並期望在短時間得到回應。

*Asyncronous message-passing systems*，透過將資料送到一個中介的 *message-broker (message queue, MQ)* 暫時儲存，再轉傳給其他服務。使用 message queue 有以下的優點：

- 如果接收者暫時無法回應，資料可以緩存在 MQ 裡面，提高可用性。
- 如果資料沒有送到 MQ 可以幫助重送訊息，做到 at-least-once delivery。
- 可以讓 senders 不需要知道 receivers 的位置、receivers 也不需要知道 senders 的位置。將兩邊的邏輯分開，senders 只需要專注在送出的訊息，而 receivers 只需要專注在訂閱並處理接收到的訊息。
- 可以透過篩選或是訂閱將訊息送給多個 receivers。

一些企業級、著名的 Message Queue 包括 RabbitMQ、NATS 以及 Apache Kafka。

# Summary

本章節介紹了各種常見的 encoding formats，提出他們在效能傷的不同，以及對於系統架構與相容性的影響。

- Programming language-specific formats：通常只限於一種語言中使用，並且通常不能做到相容性。
- Texture formats：例如 JSON、XML，這些格式通常對型態的定義很模糊，使用時要特別注意。
- Binary schema-driven formats：例如 Thrift、Protocol Buffers，這些格式能將資料壓縮的更小，並且提供上下相容的能力。另外 schema 本身能夠產生文件，但是壞處是 encoding 後的結果不是 human-readable 的。

另外介紹了三種 dataflow：

- Databases：寫的 process encode 資料，讀的 process decode 資料。
- RPC and REST APIs：Server 端 encode 資料，client 端 decode 資料。
- Asynchronous message passing：Sender 端 encode 資料，receiver 端 decode 資料。

最後，不管哪種 dataflow，不管是 server-side 還是 client-side 應用，都會有上下相容的問題，更新應用時多注意相容性問題，應用就可以頻繁的更新與部署了。

> 最後，如果你喜歡這篇文章，或是文章對你有幫助的話，可以幫我按個喜歡、或是留言！你的支持就是我寫作的最大動力。有任何想問的問題也可以在底下留言喔～
