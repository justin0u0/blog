---
title: LeetCode 44 - Wildcard Matching
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2020-07-12 17:22:13
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/wildcard-matching/](https://leetcode.com/problems/wildcard-matching/)

給一個字串 `s` 和樣板（pattern） `p`，實作支援 `'?'` 和 `'*'` 的 wildcard pattern matching。

```
'?' Matches any single character.
'*' Matches any sequence of characters (including the empty sequence).
```

計算 `s` 是否匹配 `p`。

# 範例說明

## Example 1:
```
Input:
s = "aa"
p = "a"
Output: false
Explanation: "a" does not match the entire string "aa".
```

## Example 2:
```
Input:
s = "aa"
p = "*"
Output: true
Explanation: '*' matches any sequence.
```

## Example 3:
```
Input:
s = "cb"
p = "?a"
Output: false
Explanation: '?' matches 'c', but the second letter is 'a', which does not match 'b'.
```

## Example 4:
```
Input:
s = "adceb"
p = "*a*b"
Output: true
Explanation: The first '*' matches the empty sequence, while the second '*' matches the substring "dce".
```

## Example 5:
```
Input:
s = "acdcb"
p = "a*c?b"
Output: false
```

<!-- More -->

# 想法

此題與 [LeetCode 10 - Regular Expression Matching](https://blog.justin0u0.com/LeetCode-Regular-Expression-Matching) 題目類似，實作起來也比較簡單。

有關動態規劃的詳細說明可以參考上述題目網址。這裡只做簡單的說明。

## DP 狀態
假設兩字串分別為 `s` 以及 `p`，而且從索引 1 開始編號。
所以我們可以定義 DP 狀態為： `d(i, j) = s[1 ~ i], p[1 ~ j] 是否匹配`。

## DP 轉移

1. 若 `p[j] = '*'`：
   1. 若 `'*'` 重複了 0 次，則 `d(i, j) = 1` 若且唯若 `d(i - 1, j) = 1`，也就是 `s[1 ~ i - 1]` 匹配到 `p[1 ~ j]`。
   2. 若 `'*'` 重複了一次以上，因為 `'*'` 能代表任何字元，所以 `d(i, j) = 1` 若且唯若 `d(i, j - 1) = 1`，也就是 `s[1 ~ i]` 匹配到 `p[1 ~ j - 1]`。
2. 若 `p[j]` 為一般字母，則 `d(i, j) = 1` 若且唯若 `d(i - 1, j - 1) = 1` 且 `s[i] = p[j]`。也就是如果 `s[1 ~ i - 1]` 匹配到 `p[1 ~ j - 1]` 且 `s[i] = p[j]`。
3. 若 `p[j] = '?'`，則與第二點類似。因為 `'?'` 能匹配到任何字元，所以 `s[i] = p[j]` 的條件永遠成立。
  
## DP 總整理
綜合上述 3 點，得到：
  $$d(i,\ j)=d(i-1,\ j)\ |\ d(i,\ j-1)\quad if\ p[j]=*$$
  $$d(i,\ j)=d(i-1,\ j-1)\quad if\ s[i]=p[j]\ or\ p[j]=?$$

最後考慮邊界情況：
1. 初始化 DP 陣列為 `false`
2. `d(0, 0) = 1`：`s` 與 `p` 為空應該算是匹配。
3. `d(i, 0) = 0, i > 0`：`p` 為空，但 `s` 不為空，不匹配。
4. `d(0, i)`：與 DP 轉移式相同，但只能從 `d(0, i - 1)` 轉移（因為無 `d(-1, i)`）。

最終答案為 `dp[|s|][|p|]`。

# 實作細節
真實清況中， `s` 與 `p` 皆為 Base 0（索引從 0 開始），因此所有的轉移都由 `d(i, j)` 轉為 `d(i + 1, j + 1)`。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/wildcard-matching/
 * Runtime: 356ms
 */

class Solution {
public:
  bool isMatch(string s, string p) {
    int sl = (int)s.length();
    int pl = (int)p.length();
    vector<vector<bool>> dp(sl + 1, vector<bool>(pl + 1));

    // 初始化陣列
    dp[0][0] = true;
    for (int i = 0; i < pl; i++) {
      if (p[i] == '*') dp[0][i + 1] = dp[0][i];
    }

    for (int i = 0; i < sl; i++) {
      for (int j = 0; j < pl; j++) {
        if (p[j] == '*') {
          // 轉移 1
          dp[i + 1][j + 1] = (dp[i][j + 1] || dp[i + 1][j]);
        } else if (p[j] == '?' || s[i] == p[j]) {
          // 轉移 2
          dp[i + 1][j + 1] = dp[i][j];
        }
      }
    }
    return dp[sl][pl];
  }
};

```