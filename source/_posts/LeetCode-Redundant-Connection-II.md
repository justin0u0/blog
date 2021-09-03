---
title: LeetCode 685 - Redundant Connection II
tags:
  - LeetCode
  - Graph
  - Union Find
categories: LeetCode
mathjax: true
date: 2021-04-26 13:29:50
---

# 題目
題目連結：[https://leetcode.com/problems/redundant-connection-ii/](https://leetcode.com/problems/redundant-connection-ii/)

給定一個 `N` 個點的有根樹，再加上一條邊。

求出移除哪一條邊可以使得圖變回有根樹，若有多種解答，則輸出給定的邊中比較後面的那一條。

# 範例說明

## Example 1:

![](/assets/LeetCode-Redundant-Connection-II/graph1.jpeg)

```
Input: edges = [[1,2],[1,3],[2,3]]
Output: [2,3]
```

<!-- More -->

## Example 2:

![](/assets/LeetCode-Redundant-Connection-II/graph2.jpeg)

```
Input: edges = [[1,2],[2,3],[3,4],[4,1],[1,5]]
Output: [4,1]
```

# 想法

## 分類討論

首先，在一張有根樹上面 DFS，扣除掉 DFS 所走的 Tree edges 後，最後加上的邊可能產生的情況有以下三種：

1. **Back edge**：邊 `u->v` 中，`v` 是 `u` 的祖先。
2. **Forward edge**：邊 `u->v` 中，`u` 是 `v` 的祖先。
3. **Cross edge**：邊 `u->v` 中，`u` 不是 `v` 的祖先且 `v` 也不是 `u` 的祖先。

<img src="/assets/LeetCode-Redundant-Connection-II/case.jpg" width="50%">

我們知道一棵有根樹中，**除了 root 之外，每一個點的入度為 1**。而 **Forward edge** 以及 **Cross edge** 的情況，可以發現這兩種情況都會使得**有一個點的入度為二**，也就是有兩個父親節點。並且，假設造成入度為二的兩條邊為 `e1` 以及 `e2`，可以發現移除 `e1` 與移除 `e2` 都可以使圖還原回一棵有根樹。

再來剩下 **Back edge** 的情況，我們知道當有 back edge 時，必定會有有向環的產生。這裡我們分成兩種情況討論：
1. (1.1) **Back edge** 的邊 `u->v` 中，`v` 是樹的根：這時**不會有入度為二的點產生**，但是可以發現不管移除環上的哪一個點，都可以使圖還原回一棵有根樹。
2. (1.2) **Back edge** 的邊  `v` 不是樹的根：這時**一樣有入度為二的點產生**，並且在這種情況必須要移除 back edge 才能使得圖還原回一棵有根樹。

## 並查集 Union Find/Disjoint Set

接著我們暫停一下，介紹一個資料結構 **並查集**。

**並查集** 是一種用於合併集合、查詢兩個集合是否屬於同一個集合的資料結構。其中單次查詢、合併的平均時間複雜度都是 $O(\alpha(n))$，其中 $\alpha$ 為[反阿克曼函數](https://zh.wikipedia.org/wiki/%E9%98%BF%E5%85%8B%E6%9B%BC%E5%87%BD%E6%95%B8#%E5%8F%8D%E5%87%BD%E6%95%B8)，可以想成是非常小的數即可。也就是說，並查集是非常高效的資料結構。

使用並查集，一開始每一個點都屬於一個集合。假設給定的邊集合是一個樹，則會發現每次合併一條邊的兩端點 `u` 與 `v` 時，`u` 與 `v` 一定屬於不同的集合，因為樹上的每一條邊都是 cut edge，連接著兩個 components。

也就是說，當給定的邊集合有環時，則會發現在合併環上的最後一條邊時，邊的兩端點 `u` 與 `v` 已經在同一個集合裡面了。

**p.s. 這裡的環指的是無向的環，因為並查集是沒有方向性的。**

## 總結

接著我們總結要如何找到需要移除的邊：
1. 沒有入度為二的點，則為情況 1.1 **Back edge 且 `v` 是 root**，則只要找到環上的最後一條邊即是答案。
  
    根據上述並查集的介紹，只要不斷的將邊的兩端點進行集合的合併，必定會有一條邊在合併之前，邊的兩個端點已經在同一個集合內，此時這條邊 `e` 即是我們要找的答案。

2. 有入度二的點，可能是情況 2 **Forward edge**、情況 3 **Cross edge** 或是情況 1.2 **Back edge 且 `v` 不是 root**。

    假設造成入度為二的兩條邊為 `e1` 與 `e2`，其中 `e2` 是比較晚出現的那條。
    
    **Forward edge** 與 **Cross edge** 的情況較簡單，只要刪除 `e2` 即可。

    在 **Back edge 且 `v` 不是 root** 的情況下，由於邊出現的順序是不一定的，所以 back edge 可能是 `e1` 也可能是 `e2`，當然我們可以透過從 root 進行 DFS 來找到 back edge 是哪一條。
    
    然而我們想要一個更 general 的做法。考慮上面並查集的做法，因為圖中還是有環，所以可以找到一條邊使得合併之前，兩個端點已經在一個集合內，然而這條邊可能不是 back edge 而是環上的其他邊，所以這個方法還是區分不出來 back edge 是 `e1` 還是 `e2`。

    **考慮一個方法，我們在合併邊時，不將 `e2` 加入合併的過程，也就是，在出現第二條入度為 2 的邊時，不將這條邊做集合的合併。**如此一來，若最後還是出現了環（也就是有一條邊在合併之前兩端點就在同一個集合內了）的情況，則我們知道 `e1` 才是 back edge；反之，`e2` 才是 back edge。

    接著我們要確認這個方法會不會影響先前的判斷，可以發現在情況1.1 **Back edge 且 `v` 是 root**，由於沒有入度 2 的點，所以所有的邊還是會加入合併的過程，因此不影響。另外，在情況2 **Forward edge** 與情況 3 **Cross edge**，不將 `e2` 這條邊做集合的合併則圖中一定沒有環，所以 `e2` 還是我們要刪除的邊，一樣是正確的。

# 實作細節

實作上，`pa[x]=y` 代表 `x` 與 `y` 在同一個集合內，利用遞迴可以不斷向上找，當 `pa[x]=0` 則代表已經找完了。這裡對並查集就不多介紹了，有興趣的讀者可以上網查詢。

`parent[i]` 用來記錄指向點 `i` 的邊的索引值 ，初始化時所有的 `parent[i]=0`。因此當一條邊 `u->v` 要加入時發現 `parent[v]` 已經不等於 0 時，可以知道這條邊即是第二條造成入度為 2 的邊，記錄為 `e2`，同時 `e1`，第一條造成入度為 2 的邊，即是 `parent[v]` 所記錄的邊。

當邊不是 `e2` 時，則將邊的兩端點進行合併，並且注意合併前如果兩端點的集合已經相同，則紀錄 `e` 為造成環的最後一條邊。

最後，先判斷有沒有入度為 2 的邊（可以判斷 `e1` 與 `e2` 有沒有被賦值過），若沒有的話，則必定是情況1.1，所以直接返回 `e` 即可；反之，若有入度為 2 的邊，則如果沒有環出現，要刪除的邊是較晚出現的 `e2`，否則一定是情況1.2 且要刪除的邊為 `e1`。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/redundant-connection-ii/
 * Runtime: 4ms
 */

class Solution {
private:
  int findSet(int* pa, int x) {
    return (!pa[x]) ? x : (pa[x] = findSet(pa, pa[x]));
  }
public:
  vector<int> findRedundantDirectedConnection(vector<vector<int>>& edges) {
    int n = (int)edges.size();

    int *pa = new int[n + 1]();
    int *parent = new int[n + 1]();

    int e1 = -1, e2; // e1, e2 are edges that cause a node to have 2 in degree
    int e = -1; // e is the index of edge that cause a cycle last
    for (int i = 0; i < n; i++) {
      auto& edge = edges[i];
      if (parent[edge[1]]) { // Found vertex edge[1] is the vertex that in degree = 2
        e1 = parent[edge[1]] - 1;
        e2 = i;
      } else {
        parent[edge[1]] = i + 1;

        // We skip adding e2
        int fx = findSet(pa, edge[0]);
        int fy = findSet(pa, edge[1]);
        if (fx != fy) // no cycle found, merge
          pa[fx] = fy;
        else // cycle found, the last edge that cause a cycle is i
          e = i;
      }
    }

    if (e1 == -1)
      return edges[e];
    if (e == -1)
      return edges[e2];
    return edges[e1];
  }
};

```
