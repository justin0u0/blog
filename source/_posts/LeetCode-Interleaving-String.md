---
title: LeetCode - Interleaving String
date: 2021-01-29 22:25:01
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories:
  - LeetCode
---

# 題目

題目連結：[https://leetcode.com/problems/interleaving-string/](https://leetcode.com/problems/interleaving-string/)

給定字串 `s1`, `s2` 以及 `s3`，問是否能將 `s1`, `s2` 交織（interleaving) 而成 `s3`。

若字串兩字串 `s`, `t`，其中 `s = s1 + s2 + ... + sn`, `t = t1 + t2 + ... + tm` 且 `|n - m| < 1`，
則 `s`, `t` 的交織 (interleaving) 可以是 `s1 + t1 + s2 + t2 + ...` 或是 `t1 + s1 + t2 + s2 + ...`。

# 範例說明

## Example 1:

![](https://assets.leetcode.com/uploads/2020/09/02/interleave.jpg)

```
Input: s1 = "aabcc", s2 = "dbbca", s3 = "aadbbcbcac"
Output: true
```

<!-- More -->

## Example 2:

```
Input: s1 = "aabcc", s2 = "dbbca", s3 = "aadbbbaccc"
Output: false
```

## Example 3:

```
Input: s1 = "", s2 = "", s3 = ""
Output: true
```

# 想法

題目對於交織的說明容易誤導思考的方向，其實不用在乎要先將字串的切斷再輪流加入、連接起來。可以直接想成是兩個字串隨機的順序將字元放入新的字串就好。

假設 `s1`, `s2` 兩字串的索引從 1 開始。

定義 `dp(i, j)` 代表 `s1[1 ~ i]`, `s2[1 ~ j]` 兩個子字串可以交織而成 `s3[1, i + j]`。

則 `dp(i, j) = true` 當：
1. `s1[1 ~ i - 1]`, `s2[1 ~ j]` 可以交織而成 `s3[i + j - 1]`，且 `s1[i] == s3[i + j]`。即 `dp(i - 1, j) == true && s1[i] == s3[i + j]`。
2. `s1[1 ~ i]`, `s2[1 ~ j - 1]` 可以交織而成 `s3[i + j - 1]`，且 `s2[j] == s3[i + j]`。即 `dp(i, j - 1) == true && s2[j] == s3[i + j]`。

注意 `dp(0, 0) = true`，因為兩個空字串可以交織而成空字串。

# 實作細節

實作時，因為 `s1`, `s2`, `s3` 都是從 0 開始索引的，因此在使用到 `s1`, `s2`, `s3` 的時候都要多減一。

也要注意到轉移 1 是從 `dp(i - 1, j)` 轉移到 `dp(i, j)`，因此只有在 `i > 0` 時才能轉移；同理轉移 2 則只能在 `j > 0` 時轉移。

可以發現，轉移式中，`dp(i - 1, j)` 只會從 `dp(i - 1, j)` 以及 `dp(i, j - 1)` 轉移，因此其實可以不用 `N * M` 大小的陣列來記錄。

使用一個一維的 `dp(j)` 代表 `dp(i, j)`，並且迴圈外層 `i` 從 `0 ~ N`，內層 `j` 從 `0 ~ M`，當要從 `dp(i - 1, j)` 轉移時，`dp(j)` 即為 `dp(i - 1, j)`，所以即是從 `dp(j)` 轉移到 `dp(j)`；當要從 `dp(i, j - 1)` 轉移時，即為從 `dp(j - 1)` 轉移到 `dp(j)`。

注意迴圈的順序是不能改變的，轉移才不會錯誤。

# 程式碼

## Space O(NM)

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/interleaving-string/
 * Runtime: 4ms
 * Time Complexity: O(NM)
 * Space Complexity: O(NM)
 */

class Solution {
public:
  bool isInterleave(string s1, string s2, string s3) {
    int n = s1.length();
    int m = s2.length();
    
    if (n + m != s3.length()) return false;

    vector<vector<bool>> dp(n + 1, vector<bool>(m + 1, false));

    dp[0][0] = true;
    for (int i = 0; i <= n; i++) {
      for (int j = 0; j <= m; j++) {
        if (i || j) {
          dp[i][j] = ((i && dp[i - 1][j] && s1[i - 1] == s3[i + j - 1]) || (j && dp[i][j - 1] && s2[j - 1] == s3[i + j - 1]));
        }
      }
    }
    return dp[n][m];
  }
};

```

## Space O(min(N, M))

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/interleaving-string/
 * Runtime: 0ms
 * Time Complexity: O(NM)
 * Space Complexity: O(1)
 */

class Solution {
public:
  bool isInterleave(string s1, string s2, string s3) {
    int n = s1.length();
    int m = s2.length();
    
    if (n + m != s3.length()) return false;

    if (n > m) {
      swap(s1, s2);
      swap(n, m);
    }

    vector<bool> dp(m + 1, false);

    dp[0] = true;
    for (int j = 1; j <= m; j++)
      dp[j] = (dp[j - 1] && s2[j - 1] == s3[j - 1]);
    for (int i = 1; i <= n; i++) {
      for (int j = 0; j <= m; j++) {
        dp[j] = ((dp[j] && s1[i - 1] == s3[i + j - 1]) || (j && dp[j - 1] && s2[j - 1] == s3[i + j - 1]));
      }
    }
    return dp[m];
  }
};

```
