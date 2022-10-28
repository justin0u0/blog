---
title: PostgreSQL 如何預估 Function Return Rows 以及對 Query 的效能影響
date: 2022-10-16 17:04:38
description:
tags:
- PostgreSQL
categories:
- PostgreSQL
---

今天要來跟大家分享 PostgreSQL 是如何預估 function 的 return rows 的？以及 function 的 return rows 會對 query 的效能有什麼影響？

透過真實案例可以看到當 function 的 return rows 與實際不同時，會造成的效能影響，再透過簡單的分析和 PostgreSQL 原始碼分析做找出原因，最後再用簡單的幾個方式讓 PostgreSQL 可以更準確的預測 function 的 return rows。

環境：PostgreSQL 11.17

<!-- More -->

# 先備知識

PostgreSQL 會利用 cost estimation 來創建 query plan，而其中在每個步驟後會有一個 return rows，代表 PostgreSQL 預估這個步驟會回傳多少 rows。

舉個簡單的例子來說：

```sql
CREATE TABLE IF NOT EXISTS test (
	id INT PRIMARY KEY,
	value INT NOT NULL
);

INSERT INTO test(id, value) SELECT generate_series(1, 100000), generate_series(1, 100000);
VACUUM ANALYZE test;
```

我們先創建一個 table，並且插入 id 為 1 ~ 100000，value 為 1 ~ 100000 的資料，並且執行 VACUUM ANALYZE 來更新 table 的統計資訊。

```sql
EXPLAIN SELECT * FROM test WHERE id > 100;
                        QUERY PLAN
-----------------------------------------------------------
Seq Scan on test  (cost=0.00..1693.00 rows=99900 width=8)
	Filter: (id > 100)
```

```sql
EXPLAIN SELECT * FROM test WHERE id > 99000;
                                QUERY PLAN
--------------------------------------------------------------------------
Index Scan using test_pkey on test  (cost=0.29..38.77 rows=1056 width=8)
	Index Cond: (id > 99000)
```

再來我們分別搜尋 id > 100 和 id > 99000 的資料，可以看到第一個 query 的 return rows 為 99900，而第二個 query 的 return rows 為 1056。PostgreSQL 很好的預估了 return rows 並且可以根據 return rows 來決定接下來的 query plan。

# 真實案例

我們有一段類似這樣的 query：

```sql
SELECT
	series.date,
	COALESCE(stats.count, 0) AS count
FROM
	(
		SELECT GENERATE_SERIES((NOW() - INTERVAL '6 DAYS')::TIMESTAMP, NOW()::TIMESTAMP, '1 DAY')::DATE
	) AS series(date)
	LEFT JOIN stats ON stats.member_id = 123 AND stats.date = series.date;
```

這段 query 想要做的事情很簡單，就是取得 `member_id = 123` 的最近 7 天的資料（count），並且如果有些日期沒有資料，就回傳 0。

而 `stats` 表中有 `(member_id, date)` 的 index `stats_pkey`，並且我們知道 generate_series 只會產生 7 個 rows，因此期望上如果 PostgreSQL 使用 [*Indexed Nested Loop Join*](https://www.interdb.jp/pg/pgsql03.html#_3.5.1.1.)，就可以在 7 次 index scan 完成這個 query。


但事實上使用 `EXPLAIN` 後卻發現 PostgreSQL 先對 `stats` 使用 `member_id` 做了一次 index scan 過濾後，才使用 merge join 將兩表合併。

```sql
Merge Left Join  (cost=21048.31..21120.93 rows=4508 width=12)
  Merge Cond: ((((generate_series(((now() - '6 days'::interval))::timestamp without time zone, (now())::timestamp without time zone, '1 day'::interval)))::date) = stats.date)
  ->  Sort  (cost=92.36..94.86 rows=1000 width=4)
		Sort Key: (((generate_series(((now() - '6 days'::interval))::timestamp without time zone, (now())::timestamp without time zone, '1 day'::interval)))::date)
		->  Result  (cost=0.00..32.53 rows=1000 width=4)
			->  ProjectSet  (cost=0.00..5.03 rows=1000 width=8)
				->  Result  (cost=0.00..0.01 rows=1 width=0)
  ->  Sort  (cost=20955.95..20962.00 rows=2421 width=16)
		Sort Key: stats.date
		->  Bitmap Heap Scan on stats  (cost=239.32..20819.87 rows=2421 width=16)
			Recheck Cond: (member_id = 123)
			->  Bitmap Index Scan on stats_pkey  (cost=0.00..238.72 rows=2421 width=0)
				Index Cond: (member_id = 123)
```

可以看到下面的 sort 是對 stats 表使用 `member_id = 123` 的 index 進行過濾，並且根據 `member_id` 選擇的不同，PostgreSQL 會因為 `member_id` 在表中出現的頻率甚至可能選擇 `(Parallel) Seq Scan`（高頻率時）或是 `Index Scan`（低頻率時）來做第一次的過濾。

而上面的 sort 是對 `generate_series` 產生的 rows 進行過濾，雖然我們知道 `generate_series` 只會產生 7 個 rows，但 PostgreSQL 的 query planner 並沒辦法知道這件事情，而預估出來的 rows 竟然是 1000！

# 分析

有了 `EXPLAIN` 的結果，接下來就可以分析以下兩個問題：

## 為什麼 PostgreSQL 對 function 產生的 rows 會預估成 1000？

PostgreSQL 儲存 function 的相關資訊是在 `pg_proc` 這張表中，而當中有一個欄位 [prorows](https://www.postgresql.org/docs/11/catalog-pg-proc.html#:~:text=prorows,not%20proretset)，這個欄位就是用來預估 function 產生的 rows 數量的。

要設定 `prorows` 可以在 `CREATE FUNCTION` 時指定，而根據[文件](https://www.postgresql.org/docs/11/sql-createfunction.html#:~:text=often%20than%20necessary.-,ROWS%20result_rows,-A%20positive%20number)的說明：

{% note info %}

Rows: A positive number giving the estimated number of rows that the planner should expect the function to return. This is only allowed when the function is declared to return a set. The default assumption is 1000 rows.

{% endnote %}

我們可以知道 `prorows` 的預設值是 1000，並且我們可以查看 `generate_series` 的 `prorows` 是多少：

```sql
SELECT proname, prosrc, prorows FROM pg_proc WHERE proname = 'generate_series';

     proname     |            prosrc            | prorows
-----------------+------------------------------+---------
 generate_series | generate_series_timestamp    |    1000
 generate_series | generate_series_step_int4    |    1000
 generate_series | generate_series_int4         |    1000
 generate_series | generate_series_step_int8    |    1000
 generate_series | generate_series_int8         |    1000
 generate_series | generate_series_step_numeric |    1000
 generate_series | generate_series_numeric      |    1000
 generate_series | generate_series_timestamptz  |    1000
```

可以看到確實是 1000，這也是為什麼 PostgreSQL 在 planning 時，預估 `generate_series` 會產生 1000 個 rows。

## 為什麼 PostgreSQL 會選擇先過濾一次 `member_id` 再做 Join？

在上面 `EXPLAIN` 的結果可以看到，PostgreSQL 選擇了先對內表（`stats`）進行一次過濾才做 Join，而不是我們預期的直接使用 *Indexed Nested Loop Join*（或嚴格來說是 [*index scan with parameterized path*](https://github.com/postgres/postgres/blob/REL_11_STABLE/src/backend/optimizer/README#L705)）。

{% note info %}
**Pseudo Plan of Index Nested Loop Join**
```
Nest Loop
	-> Seq Scan on series
	-> Index Scan using stats_pkey on stats
		Index Condition: (stats.member_id = 123) AND (stats.date = series.date)
```
{% endnote %}

由上面可以看出，對於 indexed nested loop join 來說，外表（`series`）越小越好，因為 nested loop join 就是對每個外表的 row 進行一次內表的過濾，但內表的大小並不是太重要。

因此當外表太大時，planner 可能就會改用 merge join 或是 hash join 的方式來合併兩表。而採用 merge join 或是 hash join 時，planner 就可以先使用 `member_id = 123` 的條件來過濾 `series`，可以直接讓內表的數量大幅減少（以我們的例子來說大約是一千萬個 rows -> 數千個 rows），來加速 merge join 或是 hash join 的過程。

## 當 Function Return Rows 錯誤時的 Nested Loop Join Cost

我們可以透過把其他 join method 關閉的方式來強制 PostgreSQL 使用 nested loop join，來看看 nested loop join 的 cost 是多少：

```sql
SET enable_hashjoin = FALSE;
SET enable_mergejoin = FALSE;
SET enable_material = FALSE;
EXPLAIN 
SELECT
	series.date,
	COALESCE(stats.count, 0) AS count
FROM
	(
		SELECT GENERATE_SERIES((NOW() - INTERVAL '6 DAYS')::TIMESTAMP, NOW()::TIMESTAMP, '1 DAY')::DATE
	) AS series(date)
	LEFT JOIN stats ON stats.member_id = 123 AND stats.date = series.date;

Nested Loop Left Join  (cost=0.56..59249.13 rows=4524 width=12)
  ->  Result  (cost=0.00..32.53 rows=1000 width=4)
		->  ProjectSet  (cost=0.00..5.03 rows=1000 width=8)
			->  Result  (cost=0.00..0.01 rows=1 width=0)
  ->  Index Scan using stats_pkey on stats  (cost=0.56..59.16 rows=5 width=16)
		Index Cond: ((member_id = 123) AND (date = (((generate_series(((now() - '6 days'::interval))::timestamp without time zone, (now())::timestamp without time zone, '1 day'::interval)))::date)))
```

可以看到 index scan 所需的 cost 為 59.16，而因為外表（`stats`）預估有 1000 個 rows，因此 cost 理所當然的會是 $59.16 \times 1000 + C \approx 59249.13$。確實比[上面](#真實案例)使用 merge left join 得到的 cost 21120.13 還要高。

{% note info %}
詳細的 indexed nested loop join cost 計算方式可以參考 [The Internals of PostgreSQL](https://www.interdb.jp/pg/pgsql03.html#_3.5.1.3.) 的介紹。
{% endnote %}

{% note info %}
實際上 index scan 的 cost 會受到設定中的 `random_page_cost` 以及資料分布（index selectivity、most common values、．．．）的影響：

- `random_page_cost` 越低，index scan 的 cost 越低。筆者使用的是預設值 10，當改為實際上在 production 上的值 1.1 時，index scan 的 cost 只剩 7.09，total cost 為 7187.16。（但同時 merge left join 的 total cost 也降到 2961.17，所以 PostgreSQL 還是會選擇 merge left join）。
- 如果 `member_id = 123` 在表中出現的次數過多，index scan 的 cost 也會增加（因為過濾的效率變差了，導致更多的 rows 返回）。PostgreSQL 也有可能改採用 bitmap scan 或是 (parallel) seq scan 的方式來過濾。
{% endnote %}

# 原始碼分析

## PostgreSQL Set Returning Function(SRF) Rows Estimation

我們來分析 PostgreSQL 底層是如何預估 SRF 產生的 rows 數量的。

根據上面部分的 `EXPLAIN` 結果，我們可以看到首先是由 `ProjectSet` 這個節點產生 1000 個 rows 這個結論的：

```sql
Result  (cost=0.00..37.53 rows=1000 width=8)
	->  ProjectSet  (cost=0.00..5.03 rows=1000 width=8)
		->  Result  (cost=0.00..0.01 rows=1 width=0)
```

而 `ProjectSet` 節點是由函數 [`create_set_projection_path`](https://github.com/postgres/postgres/blob/REL_11_STABLE/src/backend/optimizer/util/pathnode.c#L2634) 產生。Call path 如下：

- {% codeblock pathnode.c/create_set_projection_path lang:c https://github.com/postgres/postgres/blob/REL_11_STABLE/src/backend/optimizer/util/pathnode.c#L2634 first_line:2668 %}
	itemrows = expression_returns_set_rows(node);
	{% endcodeblock %}

- {% codeblock clauses.c/expression_returns_set_rows lang:c https://github.com/postgres/postgres/blob/REL_11_STABLE/src/backend/optimizer/util/clauses.c#L804 first_line:812 %}
	if (expr->funcretset)
		return clamp_row_est(get_func_rows(expr->funcid));
	{% endcodeblock %}

- {% codeblock lsyscache.c/get_func_rows lang:c https://github.com/postgres/postgres/blob/REL_11_STABLE/src/backend/utils/cache/lsyscache.c#L1664 first_line:1673 %}
	result = ((Form_pg_proc) GETSTRUCT(tp))->prorows;
	ReleaseSysCache(tp);
	return result;
	{% endcodeblock %}

可以看到 `ProjectSet` 確實是由 function 的 `prorows` 來預測 return rows 的數量的。

# 解決方案

## 更改 `prorows` 的值

我們可以先做以下的實驗，創建一個 `my_generate_series` function，並將 `prorows` 設為 7：

```sql
CREATE FUNCTION my_generate_series(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, INTERVAL)
	RETURNS TABLE (t TIMESTAMP WITH TIME ZONE) AS
	$$ SELECT * FROM generate_series($1, $2, $3) $$
	LANGUAGE SQL ROWS 7;

      proname       |                   prosrc                    | prorows
--------------------+---------------------------------------------+---------
 my_generate_series |  SELECT * FROM generate_series($1, $2, $3)  |      10
```

將 query 改為使用 `my_generate_series`：

```sql
EXPLAIN 
SELECT
	series.date,
	COALESCE(stats.count, 0) AS count
FROM
	(
		SELECT my_generate_series((NOW() - INTERVAL '6 DAYS')::TIMESTAMP, NOW()::TIMESTAMP, '1 DAY')::DATE
	) AS series(date)
	LEFT JOIN stats ON stats.member_id = 123 AND stats.date = series.date;

Nested Loop Left Join  (cost=0.56..426.14 rows=32 width=12)
  ->  Result  (cost=0.00..2.28 rows=7 width=4)
		->  ProjectSet  (cost=0.00..0.32 rows=7 width=8)
			->  Result  (cost=0.00..0.01 rows=1 width=0)
  ->  Index Scan using stats_pkey on stats  (cost=0.56..60.49 rows=5 width=16)
		Index Cond: ((member_id = 123) AND (date = (((my_generate_series((((now() - '6 days'::interval))::timestamp without time zone)::timestamp with time zone, ((now())::timestamp without time zone)::timestamp with time zone, '1 day'::interval)))::date)))
```

可以看到 `ProjectSet` 節點的 rows 數量已經從 1000 變成 7，並且正確的使用了我們預期的 nested loop join。

而 total cost 也從從原本的 59249.13 降到 $60.49 \times 7 + C \approx 426.14$。

{% note info %}
如果讀者使用的 PostgreSQL 版本 >= 12，也可以試試直接更改 `generate_series` 的 `prorows`：
```sql
ALTER FUNCTION generate_series(TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, INTERVAL) ROWS 7;
```
{% endnote %}

但在實際環境中，我們要特別創建一個 `generate_series` 函數感覺有點多此一舉，所以我們可以使用另一個方法。

## 加上 LIMIT

我們可以在 `generate_series` 的 subquery 後加上 `LIMIT`：

```sql
EXPLAIN
SELECT
	series.date,
	COALESCE(stats.count, 0) AS count
FROM
	(
		SELECT
			generate_series((NOW() - INTERVAL '6 DAYS')::TIMESTAMP, NOW()::TIMESTAMP, '1 DAY')::DATE
		LIMIT 7
	) AS series(date)
	LEFT JOIN stats ON stats.member_id = 123 AND stats.date = series.date;

Nested Loop Left Join  (cost=0.56..424.09 rows=32 width=12)
  ->  Limit  (cost=0.00..0.23 rows=7 width=4)
		->  Result  (cost=0.00..32.53 rows=1000 width=4)
			->  ProjectSet  (cost=0.00..5.03 rows=1000 width=8)
				->  Result  (cost=0.00..0.01 rows=1 width=0)
  ->  Index Scan using stats_pkey on stats  (cost=0.56..60.49 rows=5 width=16)
		Index Cond: ((member_id = 123) AND (date = (((generate_series(((now() - '6 days'::interval))::timestamp without time zone, (now())::timestamp without time zone, '1 day'::interval)))::date)))
```

可以看到因為多了一個 `Limit` 節點回傳了 7 個 rows 給上層，我們一樣能得到預期的結果。

# 補充

## PostgreSQL 12 Planner Support Function

現在我們可以透過 `prorows` 的設定或是 `LIMIT` 來讓 planner 更好的預測 return rows 的數量。但當 function 的 return rows 真的是 dynamic 的時候怎麼辦呢？

而 PostgreSQL 針對 function 沒辦法很好的預估 return rows 在 PostgreSQL 12 時提出了解決辦法，稱作 [planner support function](https://www.postgresql.org/docs/12/xfunc-optimization.html)，基本上就是允許在 function 上面綁定一個 support function 用來幫助 planner 根據參數的不同估計 return rows 的數量。

我們可以很快的體驗一下有沒有 support function 的差異：

```sql
-- PG 11
EXPLAIN SELECT GENERATE_SERIES(1, 10);

                   QUERY PLAN
------------------------------------------------
ProjectSet  (cost=0.00..5.02 rows=1000 width=4)
  ->  Result  (cost=0.00..0.01 rows=1 width=0)

-- PG 12
EXPLAIN SELECT GENERATE_SERIES(1, 10);

                   QUERY PLAN
------------------------------------------------
 ProjectSet  (cost=0.00..0.52 rows=10 width=4)
   ->  Result  (cost=0.00..0.01 rows=1 width=0)
```

這是因為在 PostgreSQL 12 整數的 `generate_series` 已經有了預設的 support function，我們可以看新增的 `prosupport` 欄位。

```sql
SELECT proname, prosrc, prorows, prosupport FROM pg_proc WHERE proname = 'generate_series';
     proname     |            prosrc            | prorows |          prosupport
-----------------+------------------------------+---------+------------------------------
 generate_series | generate_series_timestamp    |    1000 | -
 generate_series | generate_series_step_int4    |    1000 | generate_series_int4_support
 generate_series | generate_series_int4         |    1000 | generate_series_int4_support
 generate_series | generate_series_step_int8    |    1000 | generate_series_int8_support
 generate_series | generate_series_int8         |    1000 | generate_series_int8_support
 generate_series | generate_series_step_numeric |    1000 | -
 generate_series | generate_series_numeric      |    1000 | -
 generate_series | generate_series_timestamptz  |    1000 | -
```

很可惜直到目前（PostgreSQL 15）為止，`generate_series` 都還是只有支援整數的 support function，所以對於使用 timestamp 來說，還是要使用上面提到的方法。

# 總結

PostgreSQL 目前對於 function 的 return rows 雖然有了新的 `prosupport` 欄位來支援一些簡單函數的 return rows 預估，但大多數的 functions 都還是使用預設值 1000 的。因此在未來如果有在 query 內使用到 function，不仿用 `EXPLAIN` 注意 PostgreSQL 的 estimated function return rows 是否會影響到 query plan。如果發現與預想中的 plan 不同，可以透過上面提到的幾個方法改寫 query 來達到預期的效果！

> 最後，如果你喜歡這篇文章，或是文章對你有幫助的話，可以幫我按個喜歡、或是留言！你的支持就是我寫作的最大動力。有任何想問的問題也可以在底下留言喔～
