---
title: LeetCode 115 - Distinct Subsequence
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2021-01-31 14:18:45
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/distinct-subsequences/](https://leetcode.com/problems/distinct-subsequences/)

給定兩字串 `s`, `t`，求出 `s` 字串中有多少的子序列（subsequence）等於 `t`。

# 範例說明

## Example 1:

```
Input: s = "rabbbit", t = "rabbit"
Output: 3
Explanation:
As shown below, there are 3 ways you can generate "rabbit" from S.
rabbbit
rabbbit
rabbbit
```

## Example 2:

```
Input: s = "babgbag", t = "bag"
Output: 5
Explanation:
As shown below, there are 5 ways you can generate "bag" from S.
babgbag
babgbag
babgbag
babgbag
babgbag
```

<!-- More -->

# 想法

假設字串 `s`, `t` 從索引 1 開始編號。

定義 `dp(i, j)` 代表 `s[1 ~ j]` 可以產生幾個子序列等於 `t[1 ~ i]`。

接著考慮 `dp(i, j)` 的數量要怎麼求得，分為以下兩種情形：
1. `s[j] ≠ t[i]`：
   
    因為 `s[j]` 不能匹配到 `t[i]`，所以 `s[1 ~ j - 1]` 可以匹配到 `t[1 ~ j]` 之數量等於 `s[1 ~ j]` 可以匹配到 `t[1 ~ j]` 的數量。
    
    Example: `s = ababc` 中有 4 個子序列等於 `t = ab`，因為 `s` 的最後一個字元 `c` 不匹配到 `t` 的最後一個字元 `b`，因此移除 `c` 對能匹配的數量是沒有影響的，也就是 `s = abab` 也有 4 個子序列等於 `t = ab`。

    總結來說：
      $$dp(i,\ j)=dp(i,\ j-1)\quad if\ s[j]\ne t[i]$$

2. `s[j] = t[i]`：

    `s[1 ~ j]` 中的子序列，可以分為**有用到 `s[j]` 的子序列**與**沒有用到 `s[j]` 的子序列**。
    
    1. 沒有用到 `s[j]` 的子序列：
      **沒有用到 `s[j]` 的子序列其實就是 `s[1 ~ j - 1]` 的子序列**，其中等於 `t[1 ~ i]` 的數量也就是 **`dp(i, j - 1)`**。
    2. 有用到 `s[j]` 的子序列：
      若有用到 `s[j]` 且子序列等於 `t[1 ~ i]`，**代表 `s[j]` 恰好匹配到 `t[i]`**，因此 `s[1 ~ j]` 中等於 `t[1 ~ i]` 的數量**等於 `s[1 ~ j - 1]` 中的子序列等於 `t[1 ~ i - 1]` 的數量**，也就是 **`dp(i - 1, j - 1)`**。

    總結來說：
      $$dp(i,\ j)=dp(i,\ j-1)+dp(i-1,\ j-1)\quad if\ s[j]=t[i]$$

# 實作細節

注意實際情況中，`s`, `t` 兩字串都是從索引值 0 開始編號，因此在使用 `s[j]`, `t[i]` 的時候要分別改為 `s[j - 1]` 與 `t[i - 1]`。

另外，邊界值的部分，所有 `dp(0, j) = 1`，因為任何長度的 `s` 字串都有一種子序列（空集合）可以等於空字串。

另外，可以發現當 `i > j` 時，`dp(i, j)` 一定等於 0，因為 `s` 長度比 `t` 短的話是不可能有子序列等於 `t` 的。

最後，雖然答案在 `int` 範圍內，但是運算過程是有可能超出的，所以要使用 `long long` 的 dp 陣列，最後回傳再換回 `int` 即可。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/distinct-subsequences/
 * Runtime: 0ms
 */

class Solution {
public:
  int numDistinct(string s, string t) {
    int m = s.length();
    int n = t.length();
    vector<vector<long long>> dp(n + 1, vector<long long>(m + 1, 0));

    for (int i = 0; i <= m; i++)
      dp[0][i] = 1;
    for (int i = 1; i <= n; i++) {
      for (int j = i; j <= m; j++) {
        if (s[j - 1] == t[i - 1])
          dp[i][j] = dp[i - 1][j - 1] + dp[i][j - 1];
        else
          dp[i][j] = dp[i][j - 1];
      }
    }
    return (int)dp[n][m];
  }
};

```
