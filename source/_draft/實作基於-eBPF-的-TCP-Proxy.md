---
title: 實作基於 eBPF 的 TCP Proxy
date: 2024-12-07 16:49:06
description:
tags:
	- eBPF
	- Go
categories: eBPF
---

# 前言

eBPF 是一個作為新一代的 Linux 拓展機制，雖然提供了很強大的功能，但是對於初學者來說學習曲線還是有點高，網路上的資源也相對較少（各種 GPT 在當時甚至產了一堆不能用的 Code）。

想當初參考著 Isovalent 的影片 [A Load Balancer from scratch](https://www.youtube.com/watch?v=L3_AOFSNKK8) 嘗試用 **XDP** 這個 program type 實作一個 TCP Proxy，卻發現竟然會有掉封包的問題，後來才發現 XDP 根本就不能拿來做 per-packet 的 TCP Proxy 或是 Load Balancer，直接被誤導...。

這篇文章會用 eBPF 的 **SK_SKB** 這個 program type 來實作一個 TCP proxy，最後也會跟 user-space 的 TCP proxy 做效能比較。

如果對 eBPF 完全不認識的話，可以先看看 eBPF 的[簡介](https://ebpf.io/what-is-ebpf/)。

<!-- More -->

# 封包接收流程和 eBPF Hook Points

eBPF 允許使用者撰寫一些程式碼，並在 Linux Kernel 預先定義好的 hooks 被觸發的時候執行這個程式碼。例如 system call 被執行的時候、socket 收到 TCP 封包的時候。所以要實作一個 TCP Proxy，我們必須先了解 Linux Kernel 的封包接收的流程，以及 eBPF 可以在哪些步驟有提供 hooks 可以使用。

簡易的封包接收流程如下圖：

![Kernel 封包接收流程和 eBPF Hooks](/assets/實作基於-eBPF-的-TCP-Proxy/kernel-packet-receiving-flow-with-ebpf-hooks.png)

1. 首先，	


> 最後，如果你喜歡這篇文章，或是文章對你有幫助的話，可以幫我按個喜歡、或是留言！你的支持就是我寫作的最大動力。有任何想問的問題也可以在底下留言喔～
