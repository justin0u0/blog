---
title: Designing Data-Intensive Application 第三章筆記
date: 2021-08-10 13:39:16
description: |
	本章節首先介紹資料庫的 storage engine 是如何儲存資料，使得查詢可以變得更快速。並介紹兩種常被資料庫使用的資料結構 LSM-Tree 以及 B-Tree。
	再來淺談一般用於網路服務的資料庫與資料分析用的資料庫的設計理念有什麼不同。
	最後介紹較不常見的 column-oriented database 的優缺點、設計以及使用情境。
tags:
	- Notes
	- DDIA
categories: Notes
mathjax: true
---

本章節首先介紹資料庫的 storage engine 是如何儲存資料，使得查詢可以變得更快速。並介紹兩種常被資料庫使用的資料結構 *LSM-Tree* 以及 *B-Tree*。

再來淺談一般用於網路服務的資料庫與資料分析用的資料庫的設計理念有什麼不同。

最後介紹較不常見的 *column-oriented database* 的優缺點、設計以及使用情境。

![image source: https://www.omnisci.com/technical-glossary/columnar-database](/assets/Designing-Data-Intensive-Application-第三章筆記/column_vs_row_db.png)

那身為資料庫的使用者，為什麼需要知道資料庫的 storage engine 是如何設計的呢？除了要選出最適合的資料庫之外，為了要對資料庫性能進行調校，也必須了解資料庫底層是如何儲存資料的，才能根據使用情況做出最好的選擇。

<!-- More -->

# Data Structures That Power Your Database

這整個段落會以一個簡單的 key-value 資料庫來討論儲存資料的方式。

這個資料庫必須支援兩種最基本的操作：

- `set(k, v)`：把 key `k` 設成值 `v`。
- `get(k)`：查詢 key 為 `k` 的值。

首先最簡單的做法即每次 `set(k, v)` 時將一筆 log 插入到檔案的最後一行。查詢 `get(k)` 時可以透過 sequence scan 在檔案中用 $O(N)$ 的時間找到紀錄。

當然一般的資料庫並不會這樣設計，因為還必須考慮效能、儲存空間、並發等問題，但是寫 log 在資料庫中是很常見的行為。

`O(N)` 的查詢不是很有效率，資料庫通常會通過 *index* 來加快查詢的速度，index 的設計即是透過儲存一些額外的資訊來幫助快速的查找資料，因此不同的查詢通常就需要不同的 index。

雖然**好的 index 可以提升查詢的速度，但是每個 index 都會降低寫入的速度**，因此身為一個好的工程師要也要對 index 的選擇做出好的決定。

## Hash Indexes

我們可以透過 in-memory hash table 將 key 對應到其真正在檔案的 byte offset，如此一來就可以在 $O(1)$ 的時間找到 key 的位置，再透過 disk IO 直接讀取資料；並且只要在 `set(k, v)` 時只要順便更新 hash map 即可。

Hash index 也有一些限制，例如：
- Hash table 要被整個放進 memory 才能有好的效能，所以資料過多時 memory 可能不夠用。
- 不能做範圍的查詢，例如 key 是時間戳的話，hash index 沒有辦法指定查詢一段時間內的資料。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/hashmap.png)

另外，為了避免不斷插入資料造成檔案無限增大，通常可以做兩件事情：

1. Segment：每當檔案達到一定的大小，就寫到一個新的檔案（segment file）。
2. Compaction：對於相同的 key，可以只保留最新的紀錄。做完 compaction 後 segment 的大小會變小，因此也可以同時做 merge segment + compaction。

有多個檔案後，每個 segment 都必須維護一個 in-memory hash table，`get(k)` 時從最新的檔案開始尋找，因為有做 merge segment 的操作，所以可以避免檔案數量過多。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/merge_segment_compaction.png)

上述的做法在 [Bitcask](https://en.wikipedia.org/wiki/Bitcask)，一個快速的日誌型鍵值資料庫中被使用。但是實務上還有幾個問題要處理：

- File format：可以先 encode 字串成 bytes 再儲存，會更加有效率。
- Deleting records：可以在 log 中紀錄一個特別的刪除紀錄，讓 merge segment 時可以知道 key 不被保留。
- Crash recovery：如果資料庫重啟，所有 in-memory hash table 都會不見。可以透過從頭讀取 segment files 來恢復 hash table，但是會花很久的時間。實際上可以透過定期的對 hash table 進行 snapshot 來快速的恢復資料庫。
- Partially written records：資料庫隨時都有可能重啟，重啟可能造成寫到一半的 log，透過 checksum 可以偵測到錯誤的 log 並忽略。
- Concurrency control：只能有一個寫入線程，但是可以有多個讀取線程。

## SSTables and LSM-Trees

先不考慮如何做到，假設要求寫入 segment files 時，所有的紀錄必須 *sorted by key*，並且相同的 key 只出現一次，這樣的格式就稱作 *Sorted String Table* 或是簡稱 *SSTable*。如此一來可以得到幾個好處：

- Merge segment files + compaction 變得更簡單，可以透過類似 *mergesort* 合併時的方式來合併檔案（利用多個指標指向檔案的頭，每次挑最小的 key 出來將紀錄加入到新的檔案，並將該指標向後移動一格）。並且當 key 相同時，可以只保留較新檔案內的紀錄即可。
- 可以做 sparse hash table，只儲存部分的 key 在 in-memory hash table 中，`get(k)` 時只要查到 `k` 在 hash map 中的上一個＆下一個 key，即可以確認 `k` 出現的範圍。如此一來就可以避免 hash table 超過 memory 大小上限的問題。
	![](/assets/Designing-Data-Intensive-Application-第三章筆記/sstable_sparse_index.png)
- 可以做 range query，因為檔案是根據 key 排序的，所以可以一次將某個 key range 內的紀錄讀出。

### Constructing and maintaining SSTables

所以現在來探討如何做到強制 segment files 內的所有紀錄必須 *sorted by key*。

透過 in-memory 的自平衡二元搜尋樹，例如 [*AVL樹*](https://zh.wikipedia.org/zh-tw/AVL%E6%A0%91) 或是 [*紅黑樹*](https://zh.wikipedia.org/wiki/%E7%BA%A2%E9%BB%91%E6%A0%91)，我們可以很簡單的在 memory 維護一個可查詢、可插入，並且很有效率的資料結構。

透過這樣的資料結構，可以將處理資料的流程改為：

- `set(k, v)` 時，直接插入到 in-memory 的資料結構中，通常這種 in-memory tree 叫做 *memtable*。
- 當 memtable 超過一定大小時，可以在 $O(N)$ 的時間依照 key 的排序遍歷整個 memtable，將資料寫入到新的 SSTable segment file 中。當 SSTable 正在寫入時，所有的 `set(k, v)` 都寫入到新的 memtable 以避免 concurrency 的問題。
- `get(k)` 時，先找 memtable，再找最新的 SSTable，再找次新的 SSTable ... 以此類推。
- 定期的在背景執行 merging & compaction。

這種方式唯一的問題是當資料庫重啟時，memtable 內的資料會全部不見。爲了維護 durability，可以透過另外的 log 紀錄 `set(k, v)`，僅作為 recovery 時恢復 memtable 使用，因此當 memtable 的資料確認寫入 SSTable 後，相對的 log 即可刪除。

### Making an LSM-tree out of SSTables

LSM-Tree 一詞最早出現，指的是使用 log-structured，並且使用 merging 和 compaction sorted files 的 storage engine。

因此 SSTables 其實是 LSM-Trees 的一種實作，最早在 [Google Bigtable 的論文](https://storage.googleapis.com/pub-tools-public-publication-data/pdf/68a74a85e1662fe02ff3967497f31fda7f32225c.pdf) 中出現，後來被使用在 LevelDB、RocksDB、[Cassandra](https://cassandra.apache.org/doc/latest/cassandra/architecture/storage_engine.html) 和 [HBase](https://hbase.apache.org/book.html#_hfile_format) 等資料庫中。

### Performance optimizations

查詢不存在的 key 必須遍歷 memtable 以及所有的 SSTables，可能會很花時間。可以透過 Bloom filter，一個空間、時間效率極佳，可以用於判斷一個值是否存在的資料結構，缺點是無法做刪除，以及有機率將不存在的資料誤判成存在。

另外，在 compaction strategy 方面，主要分為 [*sized-tiered*](https://docs.scylladb.com/kb/compaction/#size-tiered-compaction-strategy-stcs) 與 [*leveled-tiered*](https://docs.scylladb.com/kb/compaction/#leveled-compaction-strategy-lcs) 兩種方式，在 [ScyllaDB 的文檔](https://docs.scylladb.com/kb/compaction/#compaction)中有很詳細的介紹各種 compaction 方式，這裡就不多提了。

## B-Trees

再來介紹最常被資料庫使用的 index *B-Tree*。

B-Trees 與 SSTables 一樣將資料排序儲存，但是 B-Trees 不像 SSTables 儲存不定大小的檔案，而是將資料（每一個 b-tree 節點）儲存進 fixed-size 的 blocks/pages 中，每次都以一個 page 為單位進行讀寫，因此更符合硬碟的設計。

B-Tree 是一種自平衡的樹，先介紹 B-Tree 的一些性質：
- 每一個非葉節點會儲存一些 sorted 的 keys，每個節點最多儲存 $m$ 個 keys，可以分隔出 $m+1$ 個區間，每個區間會有一個 reference pointer 指向子節點。通常 $m+1$ 會被稱作 b-tree 的分支因子（branching factor）。
	![](/assets/Designing-Data-Intensive-Application-第三章筆記/b-tree.png)
- 所有的葉節點都在同樣的高度，儲存真正的值。
- 除了根之外的非葉節點都至少有 $\lceil m/2\rceil-1$ 個 keys，而根節點最少只要有 $1$ 個 key。

查詢 `get(k)` 時，從 b-tree 的根開始可以透過排序的 key 來確定資料是存在哪一個子節點中，一直到 b-tree 的葉節點就可以找到資料真正的位置。

`set(k, v)` 時：
- 若 `k` 已存在，只要找到儲存位置再覆蓋掉 value 即可。
- 若 `k` 不存在，先找到 key 對應的葉節點，再將新的值插入到葉節點即可，但若葉節點空間不足，取葉節點中間的 key 出來，將葉節點分成兩半儲存到兩個新的 page 上，再將中間的 key 插入到上層節點即可，並更新兩個指標指到兩個新的葉節點。當然，如果上層節點空間也不夠，就會再做一次 split & update parent node 的動作。
	![](/assets/Designing-Data-Intensive-Application-第三章筆記/b-tree_growing.png)

B-tree 的 branching factor 通常會是幾百，因此可以讓樹的高度維持在 3 ~ 4 層，從而加快存取速度（一個 4 層、4KB Page、branching factor 500 的 b-tree 可以儲存超過 256TB 的資料）。

### Making B-trees reliable

一個 transaction 可能同時對多個 pages 進行寫入，若斷電可能會造成寫入不完全的狀況。因此通常會透過 *write-ahead log*（WAL），在修改執行之前先紀錄一筆修改的 log，以便在 recovery 的時候進行 undo/redo。

## Comparing B-Trees and LSM-Trees

最後做一些 B-trees 和 LSM-trees 的比較：

- LSM-trees 通常寫入較快；B-trees 通常讀取比較快。
- LSM-trees 通常比較節省空間；B-trees 會有 internal fragmentation，造成一些空間浪費。
- LSM-trees 的 throughput 不穩定，當 merging + compaction 時可能會佔據其他 queries 要使用的 I/O Bandwidth；相對來說 B-trees 就較為穩定。
- LSM-trees 的 key 可能會出現在多個檔案中；而 B-tree 的 index 只會出現在一個位置，對於資料庫來說比較好做 transaction 時 lock 的 implementation。

## Other Indexing Structures

上面討論的都是以 primary key 當作 index 的做法，通常為了其他常用的查詢也會在其他的 column 上面建立 *secondary indexes*，可以透過 SQL 的 `CREATE INDEX` 建立。

### Storing values within the index

在 B-tree 的葉節點中，儲存的值可以是 row 真正的資料，也可以是指向 row 儲存位置的參照，而真正儲存資料的位置通常叫做 *heap file*。在有多個 secondary indexes 的情況下，使用 heap file 可以避免重複資料。

更新資料時，只要更新 *heap file* 的值即可。但如果更新的 value 比原本還大，會造成所有的 reference 都需要移動，這時可以更新所有 index 的參照位置，或是在原本參照的位置再留一個新的位置參照。

直接儲存 row 真正得資料的方式叫做 *clustered index*，反之叫做 *non-clustered index*。

### Multi-column indexes

如果查詢的條件包含多個欄位，這時只有一個欄位的 index 可能就不夠好。

常見的做法是 *concatenated index*，直接把多個 column 的 key 連接在一起成為新的 key，因此連接是有順序性的。例如 `(lastname, firstname)` 的 index 就無法加速對只有 `firstname` 的查詢，但是可以加速只有 `lastname` 的查詢。

另一種做法在地理資訊較常見，透過多個 column 的 keys 計算成一個獨立的數字，可以對 GEO 的範圍查詢做加速。例如 [R-tree](https://zh.wikipedia.org/wiki/R%E6%A0%91)。

### Full-text search and fuzzy indexes

Full-text search 允許在一篇內文中尋找單詞或是句子，並且忽略文法、單複數、大小寫等等。

ElasticSearch 中透過分詞、過濾、文法轉換等過程，將文章 parse 成一個個 token，再做 token 對應到文章的[倒排索引](https://www.elastic.co/guide/cn/elasticsearch/guide/current/inverted-index.html)（inverted index）來達成有效率的 full-text search。

模糊搜尋允許查詢 edit distance 在一定範圍內的所有單詞，也就是對錯字有容錯。

### Keeping everything in memory

Redis 即現在很常見的 in-memory 資料庫，所有的資料都儲存在 memory 裡面，因此可以做到一些在 disk 上面難以實作的資料結構，例如 set 或是 priority queue。

在 memory 最大的好處就是快，但壞處就是沒有 durability。

# Transaction Processing or Analytics

一般交易、社交平台等網路服務都會用 Database 來儲存資料，通常應用程式會面對使用者，常用 key 來查詢一小部分的資料，處理大量的插入與更新。因為這些應用程式通常是互動性的，所以這種 pattern 通常叫做 *online transaction processing*（OLTP）。

相對的，資料庫也越來越常被應用在資料分析上，通常會需要查詢很多筆資料，但是只讀取一小部分的欄位，並且返回 aggregation (count, sum, average) 後的資料。這種 pattern 叫做 *online analytic processing*（OLAP）。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/OLTP_OLAP.png)

## Data Warehousing

一開始一些 OLTP 的資料庫在 OLAP 上也有很好的表現，但是 OLTP 服務通常要求高可用性並且要有好的 performance，而商業分析通常會掃過大量的數據，進而影響其他請求的效能。因此在 1980 ~ 1990 年代，一些比較大型的公司開始把分析用的資料移到獨立的資料庫，通常叫做 *data warehouse*。

Data warehouse 包含一些資料副本，通過定期的 dump 或是串流更新，將資料轉換成好用來分析的格式再儲存進分析用的資料庫，這種流程就叫做 *Extract-Transform-Load*（ETL）。一些資料庫也為 data warehousing 而生，例如 Teradata、Vertica、SAP HANA 和 ParAccel。甚至也有適合用在 data warehouse 的 data model，例如 *Star Schema*。

## Stars and Snokeflakes: Schemas for Analytics

*Star schema* 首先將資料分為「事實（fact）」與「維度（dimension）」兩個部分：

- Fact tables：儲存事件，以及任何可以用來分析的數值欄位。例如電商平台的事實資料可以是銷售紀錄，可用於分析的欄位包括價格、數量、時間等。事實資料表通常包含資料欄位以及一些 foreign key 來關聯其他的維度資料。一般而言事實資料表的列數（rows）非常多，並且隨著時間還會繼續成長。事實資料表通常會有很多欄位（columns），通常在上百到上千個不等。
- Dimension tables：儲存事件的實體，例如商品、銷售員、銷售活動、顧客等詳細資訊。一般而言維度資料表的列數較少。維度資料表也可以有很多欄位用來描述這些實體。

這樣的設計可以將要分析的資料都保留在最中間的事實資料表中，並且可以透過一層的簡單 join 拿到其他與事件相關的資訊，因此 star schema 適合用於資料分析。

![Image source: https://docs.microsoft.com/zh-tw/power-bi/guidance/star-schema](/assets/Designing-Data-Intensive-Application-第三章筆記/star_schema.png)

而 *Snowflake schema* 是 star schema 的一種變體，允許 dimension tables 可以有附屬的 sub-dimension tables。

# Column-Oriented Storage

通常資料分析時會讀很多 rows 以及很少一部分的 columns，而一般在 OLTP 資料庫的 storage engine 都是 *row-oriented* 的，也就是說在 disk 中資料是一個 row 接著一個 row 儲存的。因此在資料分析時，row-oriented 的設計會讓資料庫必須讀出整個 row 的資料到 memory，再去掉不必要的 columns，這可能會浪費掉很多時間。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/row-oriented.png)

因此有 *column-oriented* 的 storage engine 出現，將相同的 column 儲存在一起（通常是每個 column 儲存到獨立檔案），查詢時就可以只將需要的 columns 讀出。要注意各個 column 必須是以一樣的排序方式儲存的，才能夠還原出原本的 rows。例如所有 column 中的第一個值都是對應到同一個 row 的資料。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/column-oriented.png)

另外，Cassandra 和 HBase 都有 column familes 的概念，但並不是 column-oriented。在每個 column family 中資料還是一個一個 rows 儲存的，所以還是算 rows-oriented。

## Column Compression

將 column 儲存在一起可以做 column compression 來節省儲存空間。其中一種常見的方式是 *bitmap encoding*。

Bitmap encoding 對每個不一樣的值都用一個 bitmap 來儲存他們在第幾個 row 出現，例如下圖中 `product_sk` 這個 column 中，總共有 6 個相異值，因此就需要 6 個 bitmaps 來儲存。其中 `product_sk=74` 這個數字排在第 5 個，因此就將其 bitmap 中的第 5 個值設為 1。如此一來只要儲存所有的 bitmaps 即可。

而儲存 bitmaps 可以透過 run-length encoding 來節省空間。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/bitmap_encoding.png)

做 bitmap index 在一些 data warehouse 的 query 中也有好的表現，例如：

1. `WHERE product_sk IN (30, 68, 69)`：只要 load `product_sk` 是 30, 68, 69 的 bitmaps 後做 bitwise OR 即可得到結果。
2. `WHERE product_sk = 31 AND store_sk = 3`，只要 load `product_sk = 31` 以及 `store_sk = 3` 的 bitmaps 後做 bitwise AND 後即可得到結果。

## Sort Order in Column Storage

在 column-oriented store 中 **rows 的儲存順序可以任意，但是每個 columns 都必須是以一樣的方式排序**。

使用者可以根據常用的 query 來決定要根據哪個 column 做排序。例如選擇根據 date key 做排序，則 query optimizer 就可以幫「查詢一段時間內的資料」這樣的查詢做加速。另外如果這個欄位還有做 bitmap index 的話，因為資料已經排序過，所以 bitmap 中的所有 0 跟 1 都會聚集在一起，透過 run-length encoding 後就可以節省非常多的儲存空間。

## Writing to Column-Oriented Storage

使用排序後資料插入會變困難，因為無法在檔案中做插入。這時可以使用 LSM-tree，在 memory 上做寫入與排序，等到一定的大小後與舊的 column files 合併並寫到新的檔案中。這種做法被 Vertica 採用。

## Aggregation: Data Cubes and Materialized Views

Date warehouse 常會使用到一些 aggregation functions 例如 `COUNT`、`SUM`、`AVG`、`MIN` 與 `MAX` 等等，如果一個 aggregation 的結果經常被其他 query 使用，那 cache 住這個結果成為一個 *materialized view*，之後的 query 可以直接在這個 table 上面做 query 以節省時間。

一種在 OLAP 常見的 *materialized view* 叫做 *data cube* 或是 *OLAP cube*，由多個 dimensions 的資料透過 aggregation 後得到，以下是一個 2D 的 OLAP cube。在表上可以快速得到某日的營業額、某月營業額、某商品單月營業額等等資訊。

![](/assets/Designing-Data-Intensive-Application-第三章筆記/OLAP_cube.png)

# Summary

總結來說，本章節的重點在介紹資料庫的各種 storage engine 設計，以及其優缺點。

首先介紹了 OLTP 中兩種常見的儲存方式：

- Log-structured：只能以插入的方式寫檔。檔案透過合併與壓縮的方式來減少儲存空間。SSTables 與 LSM-trees 都是屬於這種類型。
- Update-in-place：動態的寫入 disk 中的 page。B-trees 是屬於這種類型的，並且 B-trees 被應用在大多數的 relational databases 與很多 non-relational databases 中。

另外以更大的面向將資料庫分成 OLTP 與 OLAP 兩種類型：

- OLTP 通常面向使用者，有較多的 insert 與 update 操作，且使用 key 來存取少量的資料，因此 storage engine 透過儲存 index 來快速的查詢資料。
- OLAP 通常只在大公司的資料分析用途中出現，query 數量少但每次存取大量資料，透過 column-oriented storage 來減少 disk I/O bandwidth。

身為應用程式的開發者，上述這些內容可以幫助你更好的調校資料庫的 indexing 或是 storage engine，並且在閱讀資料庫文檔時有足夠充足的知識。

> 最後，如果你喜歡這篇文章，或是文章對你有幫助的話，可以幫我按個喜歡、或是留言！你的支持就是我寫作的最大動力。有任何想問的問題也可以在底下留言喔～
