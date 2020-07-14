---
title: LeetCode 45 - Jump Game II
tags:
  - LeetCode
  - Greedy（貪心）
categories: LeetCode
date: 2020-07-13 10:48:31
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/jump-game-ii/submissions/](https://leetcode.com/problems/jump-game-ii/submissions/)

給一非負的整數序列，一開始在序列的第一格上。序列的值代表在此位置時最多可以跳多少距離，求最少幾步可以到達序列的最後一格。

# 範例說明

```
Input: [2,3,1,1,4]
Output: 2
Explanation: The minimum number of jumps to reach the last index is 2.
    Jump 1 step from index 0 to 1, then 3 steps to the last index.
```

<!-- More -->

# 想法
假設序列的第 i 個元素為 Ai，且序列從 0 開始編號。

在第 0 步的時候，假設 `R0 = 0`，則可以到達的範圍在 `0 ~ R0`。

第 1 步時，一步能到達的範圍在 `0 ~ R1`，其中 `R1 = A0`。但是從 `0 ~ R0` 的這個區間出發，必定只能到達 `0 ~ R1`，所以要算出第 2 步能到達的範圍時，可以排除從 `0 ~ R0` 出發的可能性。因此第 2 步可以到達的範圍應該是由 `[R0 + 1, R1]` 出發：

$$\bigcup\ [i,\ i+A_i],\quad\forall\ i\in [R0+1, R1]$$

假設聯集後的範圍在 `[L2, R2]`，代表 `[0 ~ R2]` 都可以在 2 步內到達。但是從 `0 ~ R1` 這個區間出發，必定只能到達 `0 ~ R2`，所以要算出第 3 步能到達的範圍時，可以排除從第 `0 ~ R1` 格出發的可能性，因此第 3 步可以到達的範圍應該是由 `[R1 + 1, R2]` 出發：

$$\bigcup\ [j,\ j+A_j],\quad\forall\ j\in [R1+1, R2]$$

以此類推，可以發現要算第 `i` 步能到達的區間，只需要由 `i - 1` 步能多走到的區間出發計算就好。

假設 `N` 為序列長度，因為每一個區間都不重複，所以總時間複雜度為 `O(N)`。

# 實作細節

紀錄 `[iL, iR]` 區間，代表要從這個區間出發找下一步可以到哪個範圍。`steps` 為當前的步數。

初始時，`steps = 0`，且 `[iL, iR] = [0, 0]`。

每一次都從 `[iL, iR]` 區間出發，尋找下一個 `iR`，紀錄為 `next_iR`：
$$next\_iR=max(i + Ai),\quad\forall\ i\in [iL, iR]$$
而下一個 `iL` 則為 `iR + 1`。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/jump-game-ii/
 * Runtime: 20ms
 */

class Solution {
public:
  int jump(vector<int>& nums) {
    int n = (int)nums.size();
    int steps = 0;
    int iL = 0, iR = 0;
    // iR >= n - 1，代表已經可以走到最後一格
    while (iR < n - 1) {
      int next_iR = 0;
      // 從 [iL, iR] 出發找下一步的範圍
      for (int i = iL; i <= iR; i++)
        next_iR = max(next_iR, i + nums[i]);
      // 下一個 iL
      iL = iR + 1;
      // 下一個 iR
      iR = next_iR;
      // 每一次都把 steps + 1
      steps++;
    }
    return steps;
  }
};

```
