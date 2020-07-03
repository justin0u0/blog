---
title: LeetCode 514 - Freedom Trail
date: 2020-07-01 21:28:09
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
mathjax: true
categories: LeetCode
---

# 題目
[題目連結](https://leetcode.com/problems/freedom-trail/)

給定一個環狀的字串 `ring`，再給一個字串 `key`，要求利用 `ring` 在最少步數內拼出字串 `key`。

一開始指標在字串 `ring` 的第一個字元上，將指標順時鐘或是逆時鐘動一格算是一步。當指標所指的字元等於你要拼的 `key` 中的字元，你還必須花一步來按下確認按鈕。

# 範例說明
<img src="https://assets.leetcode.com/uploads/2018/10/22/ring.jpg" width="30%" />
<!-- more -->

**輸入：**

`ring = "godding"`

`key = "gd"`

**輸出：** 4

**說明：** 一開始指標在 `ring` 的第一個字元 `g`，所以我們只要花一步按下確認鈕就好。再來我們花費兩步逆時針旋轉 `ring` 兩次，讓指標到達 `d`。再花一步按下確認鈕，總共花費 4 步。

# 想法
`ring` 中的字元是會重複的，因此我們無法確定離當前指標比較近的目標字元會使我們的答案最佳化。
因此我們換個想法，如果在搜尋第 `i` 個字元 `key[i]` 時，旋轉到位置 `j` 的最佳答案，紀錄為 `dp(i, j)`。

定義 `N = ring 的長度`, `M = key 的長度`。
定義將 `ring` 從位置 `k` 轉到位置 `j` 的最小花費為 `dist(k, j)`。那麼我們可以輕易發現：
$$dp(i, j) = min(dp(i - 1,k)+dist(k,j)+1), \quad \forall i \in [1, M]\ ,\forall j \in [0, N) $$
也就是 `dp(i, j)` 等於從第 `i - 1` 步的任意位置轉到位置 `j` 的花費加上原來記錄的最小花費`dp(i - 1, k)`，再加上一步按確認鍵。

初始化時只要將 `dp(0, 0)` 設成 0，其餘位置設成無限大，`dp(i, j)` 只在 `ring[j] = key[i]` 時計算。便能求出答案為：
$$min(dp(M, j)), \quad \forall\ j \in [0, N)$$

總時間複雜度為 `O(N^2 * M)`。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/freedom-trail/
 */

class Solution {
private:
  const int INF = 0x3f3f3f3f;
public:
  int findRotateSteps(string ring, string key) {
    const int ringLength = (int)ring.length();
    const int keyLength = (int)key.length();
    // 初始化 keyLength * ringLength 的陣列，並將值都設為無限大
    vector<vector<int>> dp(keyLength + 1, vector<int>(ringLength, INF));
    dp[0][0] = 0;

    for (int i = 1; i <= keyLength; i++) {
      char target = key[i - 1];
      for (int j = 0; j < ringLength; j++) {
        if (target == ring[j]) {
          for (int k = 0; k < ringLength; k++) {
            // 從位置 k 到位置 j，dist(k, j) = min(clockwise, anticlockwise) + 1
            int clockwise = (k - j + ringLength) % ringLength;
            int anticlockwise = (j - k + ringLength) % ringLength;
            dp[i][j] = min(dp[i][j], dp[i - 1][k] + min(clockwise, anticlockwise) + 1);
          }
        }
      }
    }

    // 答案為 dp[keyLength] 中的最小值
    int steps = INF;
    for (int i = 0; i < ringLength; i++) {
      steps = min(steps, dp[keyLength][i]);
    }
    return steps;
  }
};

```
