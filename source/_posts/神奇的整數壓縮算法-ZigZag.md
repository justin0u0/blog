---
title: 神奇的整數壓縮算法——ZigZag
date: 2021-09-05 04:48:33
description:
tags:
categories: Others
mathjax: true
---

在 Thirft 與 Protocol Buffers 中，都使用了一種整數壓縮的演算法叫做 ZigZag。

算法本身很簡單，卻也很實用，因此分享給大家 ZigZag 的實作與想法。

<!-- More -->

# 二進制與二補數

在電腦的世界，所有數字都是以二進位儲存的，我們假設數字是儲存在 8 bits 的變數中，例如：$(1)_{10}=(00000001)_{2}$、$(3)_{10}=(00000010)_{2}$。因此如果所有數字都是正數，則使用 8 個 bits 的最大數字很明顯是 $(255)_{10}=(11111111)_2$。

可惜這個世界是有負數存在的，因此人們在考慮要如何在二進位中表示負數時，有了以下這些想法：

1. 原碼（True form）
	這個想法很直觀，使用第一個 bit 做為 signed bit，如果是正數則為 0，負數則為 1。

	因此正負數除了第一個 bit 之外，剩下的表達方式與數值本身一樣。例如 $(11)_{10}=(00001011)_{2}$，$(-11)_{10}=(10001011)_{2}$。

2. 1's 補數（One's complement）
	這個的想法也很直觀，直接將正數的所有 bit 取反當作負數的表達式。例如 $(11)_{10}=(00001011)_{2}$，$(-11)_{10}=(11110100)_{2}$。

3. 2's 補數（Two's complement）
	然而以上兩種方式都有兩個問題：
	1. 數字 0 有兩種表達方式，原碼中有 $+0=(00000000)_2$ 與 $-0=(10000000)_2$；1's 補數中有 $+0=(00000000)_2)$ 與 $-0=(11111111)_2$。會造成混淆。
	2. 加法上的不便：在加法的實作上，兩種方式若直接做二進位的加法，都會出現奇怪的現象（請讀者自己加加看，就不補充例子了）。

	2's 補數即先取反（做 1's 補數）後，再 $+1$。

	例如：$(11)_{10}=(00001011)_{2}$，$(-11)_{10}=(11110101)_{2}$

	```
	(11)     ：00001011
	(-11) 1's：11110100（取反）
	(-11) 2's：11110101（+1）
	```

# ZigZag

接著進入正題，在大多數情況下，軟體工程師習慣使用 32 bits 的變數來儲存整數，例如 C/C++ 中的 `int`、Java 中的 `int`。因此在網路傳輸時，往往也會直接使用 32 bits 的數字做為傳輸類型，而 32 bits 的有號整數可以最大可以儲存到 2147483647，也就是 21 億。

但是現實世界中，較小的數字往往比較常出現，例如使用者的 ID、商品的數量、商品的價格等，往往都是幾十幾百幾千到幾萬不等的數字。如果只是要傳輸一個數字 $(1)_{10}=(00000000\_00000000\_00000000\_00000001)_2$，卻需要傳輸這麼多不需要的 0，感覺就很浪費。

因此 ZigZag 的核心想法就是**當數字很小的時候，就只傳送有需要的 bytes 即可**，例如數字 $(1)_{10}$ 只傳送 $(00000001)_2$。

如果只有正數的話就很容易實作，可惜我們需要考慮負數的存在。負數 $(-1)_{10}=(11111111\_11111111\_11111111\_11111111)_2$，前面都是 1，就沒辦法直接丟棄了。

因為 ZigZag 希望比較小的數字都用比較少的 bytes，因此 ZigZag 決定將數字依照絕對值大小排序，順序如下：

```
順序： 0  1  2  3  4  5  6 ...
數字： 0 -1 +1 -2 +2 -3 +3 ...
```

觀察數字與順序在二進位的關係（這裡為了方便，先回到 8bits）：

```
數字：           順序：          順序、去除 last bit：
 0 (00000000)   0 (00000000)   0 (0000000)
-1 (11111111)   1 (00000001)   1 (0000000)
+1 (00000001)   2 (00000010)   2 (0000001)
-2 (11111110)   3 (00000011)   3 (0000001)
+2 (00000010)   4 (00000100)   4 (0000010)
-3 (11111101)   5 (00000101)   5 (0000010)
+3 (00000011)   6 (00000110)   6 (0000011)
```

可以觀察到，若將順序中的最後一個 bit 看成 signed bit，則剩下的 bits 中，正數即原本的數字，而負數即原數字取反。

因此我們只要**將原數字左移一位，負數再做取反後，將 signed bit 補到最後一位即可**。實際操作一次：

```
+3 = 00000011
    
   = 0000011x（左移一位）
   = 00000110（補上 signed bit）
   = 6
```

```
-3 = 11111101

   = 1111101x（左移一位）
	 = 0000010x（取反）
	 = 00000101（補上 signed bit）
   = 5
```

最後 ZigZag 厲害的地方就在於，程式上的實作也非常簡單，可以透過位元運算達成：

```go
func int8ToZigZag(n int8) int8 {
	return (n << 1) ^ (n >> 7)
}

fmt.Println(int8ToZigZag(3))  // 6
fmt.Println(int8ToZigZag(-3)) // 5
```

其原理也很簡單，首先要知道，`<<` 是算術左移運算子（arithematic left shift operator），會將所有 bits 向左移動一格後補上 0；而 `>>` 是 算術右移運算子（arithematic right shift operator），會將所有 bits 向右移動後<font color="red">補上 signed bit</font>。

因此所有數在右移 7（`n >> 7`）後，正數因為原 signed bit 是 0，每次左移之後都會在左邊補上 0，所以最後變成 `00000000`；而負數因為原 signed bit 是 1，所以每次右移都會在左邊補上 1，所以最後變成 `11111111`。

再來 `(n << 1)` 即數字左移一位，且最後右邊一位會補上 0。最後 `^` 為 xor 運算子，所以觀察 `(n << 1) ^ (n >> 7)`：

```
(n >> 7)：
正數：      負數：
00000000   11111111

(n << 1)：
正數：      負數：
xxxxxxx0   yyyyyyy0
```

可以發現最右邊的 signed bit 部分，正數的一定是 0，負數的一定是 1。左邊數字部分，我們知道 `0 ^ x = x` 且 `1 ^ y = ~y`，所以正數的數字一定保持不變，而負數會被取反。

而這正是我們想要的結果。

最後回到 32bits 的數字：

```go
func int32ToZigZag(n int32) int32 {
	return (n << 1) ^ (n >> 31)
}
```

Decode 時只要將操作反過來即可（注意 golang 在 unsigned int 才會做 logical right shift，所以要先轉 `uint32`）：

```go
func zigZagToInt32(n int32) int32 {
	u := uint32(n)
	return int32(u>>1) ^ -(n & 1)
}
```

知道了如何對一個數字做 ZigZag encoding 後，我們只要再思考如何決定傳輸時要送幾個 bytes 即可：

一種做法是用額外的一個 byte 代表接下來的整數有幾個 bytes，例如 $(00000001\_00000010)_2$ 的第一個 byte 代表接下來的整數只有一個 byte，而第二個 byte 開始才是真正要傳輸的數字。但是這樣的做法最少需要兩個 bytes 才能表示一個數字。

而 ZigZag 採用了另一種做法，就是每個 byte 中都**使用第一個 bit 作為「還有沒有下一個 byte」的判斷**，也就是說如果 first bit 是 1，則代表這個數字還沒有結束；如果 first bit 是 0，則代表這個數字已經結束。因此在傳輸時，其實每個 byte 能被使用的 bits 只有 7 個。而這種做法被稱作 [*Base128 Varint*](https://developers.google.com/protocol-buffers/docs/encoding#varints)。

舉例來說，如果我們想要傳輸 1337 這個數字，先做 `int32ToZigZag(1337) = 2674 = 0b10100_1110010`，傳輸時由低位先傳，所以傳出的第一個 byte 為 `11110010`，可以看到因為還沒傳完，所以第一個 bit 為 1，後 7 個 bits 才是真正的資料 `1110010`；傳出的第二個 bit 為 `00010100`，因為已經沒有下一個 byte 了，所以第一個 bit 為 0。

實作上也是很簡單，`^0x7F` 是 $(11111111\_11111111\_11111111\_10000000)_2$，所以 `n & ^0x7F` 的作用在於檢查 `n` 是不是只有最後 7 個 bits 有數字。如果是的話，就寫入 `n`；否則就只寫入 `n` 的最後 7 bits 加上前面的一個 1（代表後面還有數字）。

```go
func writeVarint32(n int32) (int, []byte) {
	i32buf := make([]byte, 5)
	idx := 0
	for {
		if (n & ^0x7F) == 0 {
			i32buf[idx] = byte(n)
			idx++
			break
			// return;
		} else {
			i32buf[idx] = byte((n & 0x7F) | 0x80)
			idx++
			u := uint32(n)
			n = int32(u >> 7)
		}
	}
	return idx, i32buf
}
```

也因為這種方式一次只能傳輸 7 個 bits 的真實資料，因此一個 32bits 的整數是有可能要花費 5 個 bytes 才傳完的（不過要在數字很大的時候）。

# 總結

ZigZag 在處理有號整數的壓縮是非常精妙的，在實作中也僅僅使用不到百行的程式碼就可以完成。

也因此 Thrift、Protobuf 和 Arvo 這三大 binary encoding libraries 都有透過 ZigZag encoding 做有號整數壓縮來減少傳輸的量。

全部的實作在這裡，有興趣的讀者可以自己替換數字跑跑看。

```go
package main

import "fmt"

func int32ToZigZag(n int32) int32 {
	return (n << 1) ^ (n >> 31)
}
func zigZagToInt32(n int32) int32 {
	return int32((uint32(n) >> 1)) ^ -(n & 1)
}

func writeVarint32(n int32) (int, []byte) {
	i32buf := make([]byte, 5)
	idx := 0
	for {
		if (n & ^0x7F) == 0 {
			i32buf[idx] = byte(n)
			idx++
			// p.writeByteDirect(byte(n));
			break
			// return;
		} else {
			i32buf[idx] = byte((n & 0x7F) | 0x80)
			idx++
			// p.writeByteDirect(byte(((n & 0x7F) | 0x80)));
			u := uint32(n)
			n = int32(u >> 7)
		}
	}
	return idx, i32buf
}

func main() {
	fmt.Println(int32ToZigZag(1337)) // 2647

	fmt.Println(zigZagToInt32(2674)) // 1337

  l, b := writeVarint32(2674)
  for i := 0; i < l; i++ {
    fmt.Printf("%08b ", b[i]) // 11110010 00010100
  }
  fmt.Println("")
}
```

# 參考資料

- [Thrift Compact protocol encoding](https://github.com/apache/thrift/blob/master/doc/specs/thrift-compact-protocol.md)
- [Thrift Compact protocol encoding implementation in Golang](https://github.com/apache/thrift/blob/master/lib/go/thrift/compact_protocol.go)
- [Protocol Buffers encoding - Signed Integers](https://developers.google.com/protocol-buffers/docs/encoding#signed_integers)
- https://blog.csdn.net/zgwangbo/article/details/51590186

> 最後，如果你喜歡這篇文章，或是文章對你有幫助的話，可以幫我按個喜歡、或是留言！你的支持就是我寫作的最大動力。有任何想問的問題也可以在底下留言喔～
