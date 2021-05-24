---
title: LeetCode 72 - Edit Distance
date: 2020-07-18 11:47:01
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/edit-distance/](https://leetcode.com/problems/edit-distance/)

給定兩個字串 `word1`, `word2`，找到最少的操作步數將 `word1` 轉換成 `word2`。

有三種合法的操作：
1. 插入一個字元
2. 刪除一個字元
3. 替換一個字元

# 範例說明

## Example 1:
```
Input: word1 = "horse", word2 = "ros"
Output: 3
Explanation: 
horse -> rorse (replace 'h' with 'r')
rorse -> rose (remove 'r')
rose -> ros (remove 'e')
```

## Example 2:
```
Input: word1 = "intention", word2 = "execution"
Output: 5
Explanation: 
intention -> inention (remove 't')
inention -> enention (replace 'i' with 'e')
enention -> exention (replace 'n' with 'x')
exention -> exection (replace 'n' with 'c')
exection -> execution (insert 'u')
```

<!-- More -->

# 想法

在 [LeetCode - Regular Expression Matching](https://blog.justin0u0.com/LeetCode-Regular-Expression-Matching/) 中，有提到過當看見兩字串匹配的題目時，幾乎可以確定此題為動態規劃，且 DP 狀態為 `d(i, j)` 代表 `word1` 的前 `i` 個字元與 `word2` 的前 `j` 個字元為止，編輯距離為多少。

## DP 狀態
假設兩字串分別為 `word1` 以及 `word2`，而且從索引 1 開始編號。
所以我們可以定義 DP 狀態為： `d(i, j) = word1[1 ~ i], word2[1 ~ j] 是否匹配`。

## DP 轉移

首先，如果 `word1[i] = word2[j]`，則 `word1[1 ~ i]` 與 `word2[1 ~ j]` 所需的編輯距離等於 `word1[1 ~ i - 1]` 與 `word2[1 ~ j - 1]` 的編輯距離。所以：

  $$d(i,\ j)=d(i-1,\ j-1)\quad\ if\ word1[i]=word2[j]$$

再來考慮三種對 `word1` 的操作：
1. 插入一個字元：則求 `d(i, j - 1)` 的編輯距離再加一。
2. 刪除一個字元：則求 `d(i - 1, j)` 的編輯距離再加一。
3. 替換一個字元，則求 `d(i - 1, j - 1)` 的編輯距離再加一。

所以：
  
  $$d(i,\ j)=min(d(i-1,\ j), d(i,\ j-1), d(i-1,\ j-1))\quad\ if\ word1[i]\neq word2[j]$$

最後考慮邊界情況：
1. `d(0, 0) = 0`，因為兩字串為空時相等，編輯距離為 0。
2. `d(0, i) = i`，當 `word1` 為空，`word2` 不為空，則編輯距離為 `word2` 長度。
3. `d(i, 0) = i`，當 `word1` 不為空，`word2` 為空，則編輯距離為 `word1` 長度。

假設 `word1` 長 `N`，`word2` 長 `M`，則總時間複雜度為 `O(NM)`，DP 陣列為 `N*M` 大，所以總空間複雜度為 `O(NM)`。

## 空間優化

可以發現 DP 轉移只需要左邊、左上、上面三個位置，因此只需要紀錄當前這排的 DP 狀態。

利用一變數 `pre` 代表左上角的狀態，利用 `temp` 紀錄上方狀態，再進行轉移。

總空間複雜度降為 `O(M)`。

## 實作細節

因為真實情況中，`word1` 與 `word2` 皆為 Base 0（索引從 0 開始），所以要將轉移式中的 `d(i, j)` 都變為 `d(i + 1, j + 1)`。

# 程式碼

## O(N^2) Space
```cpp
/**
 * Author: jutin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/edit-distance/
 * Runtime: 24ms
 */

class Solution {
public:
  int minDistance(string word1, string word2) {
    int n = (int)word1.length();
    int m = (int)word2.length();
    vector<vector<int>> dp(n + 1, vector<int>(m + 1));

    for (int i = 0; i < n; i++) dp[i + 1][0] = i + 1;
    for (int i = 0; i < m; i++) dp[0][i + 1] = i + 1;

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        if (word1[i] == word2[j])
          dp[i + 1][j + 1] = dp[i][j];
        else
          dp[i + 1][j + 1] = min(min(dp[i + 1][j], dp[i][j + 1]), dp[i][j]) + 1;
      }
    }
    return dp[n][m];
  }
};

```

## O(N) Space
```cpp
/**
 * Author: jutin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/edit-distance/
 * Runtime: 20ms
 */

class Solution {
public:
  int minDistance(string word1, string word2) {
    int n = (int)word1.length();
    int m = (int)word2.length();
    vector<int> dp(m + 1);

    for (int i = 0; i < m; i++) dp[i + 1] = i + 1;

    for (int i = 0; i < n; i++) {
      int pre = dp[0];
      dp[0] = i + 1;
      for (int j = 0; j < m; j++) {
        int temp = dp[j + 1];
        if (word1[i] == word2[j])
          dp[j + 1] = pre;
        else
          dp[j + 1] = min(min(pre, dp[j + 1]), dp[j]) + 1;
        pre = temp;
      }
    }
    return dp[m];
  }
};
```
