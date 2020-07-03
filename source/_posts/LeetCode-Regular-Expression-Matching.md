---
title: LeetCode 10 - Regular Expression Matching
date: 2020-07-03 10:33:56
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
mathjax: true
---

# 題目
給一個字串 `s` 和樣板（pattern） `p`，實作支援 `.` 和 `*` 的 regular expression。

```
'.' Matches any single character. 匹配一個任一字元。
'*' Matches zero or more of the preceding element. 匹配零到任意多個前一個字元
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
p = "a*"
Output: true
Explanation:
'*' means zero or more of the preceding element, 'a'.
Therefore, by repeating 'a' once, it becomes "aa".
```

<!-- More -->

## Example 3:
```
Input:
s = "ab"
p = ".*"
Output: true
Explanation:
".*" means "zero or more (*) of any character (.)".
```

## Example 4:
```
Input:
s = "aab"
p = "c*a*b"
Output: true
Explanation:
c can be repeated 0 times, a can be repeated 1 time. 
Therefore, it matches "aab".
```

## Example 5:
```
Input:
s = "mississippi"
p = "mis*is*p*."
Output: false
```

# 想法

## 動態規劃 Dynamic programming
首先，遇到兩字串匹配的問題，我們通常都可以用一個二維的 dynamic programming 表格來解決。
筆者喜歡將 DP 表格從一開始編號，因為 0 是邊界，常常拿來儲存邊界資訊。而這題也不例外。
遇到 DP 問題，筆者通常都會思考兩個方向：
1. 狀態：定義 `d(i)`, `d(i, j)` ... 代表什麼意義。
2. 轉移：定義 `d(i)` 的答案從哪裡來，`d(i, j)` 的答案從哪裡來...

轉移時務必要注意答案要從已經計算完的區間得來。

## DP 狀態
假設兩字串分別為 `s` 以及 `p`，而且從索引 1 開始編號。
所以我們可以定義 DP 狀態為： `d(i, j) = s[1 ~ i], p[1 ~ j] 是否匹配`。

## DP 轉移

1. 首先，我們可以發現，如果一個字元的後面為一個 `*` 字元，那麼我們應該要把這個字元跟連著的 `*` 看成一組。也就是說，如果遇到一個字元後面緊接著一個 `*`，那麼我們可以直接把忽略這個字元的作用直接繼承上一排的狀態，所以轉移式為：

  $$d(i,\ j)=d(i,\ j-1)\quad if\ \textcolor{red}{p[i+1]=*}$$

2. 再來，如果 `p[j]` 為一般的字母且匹配到 `s[i]`，那麼我們 `d(i, j)=1` 若且唯若 `d(i - 1, j - 1) = 1`。也就是如果 `s[1 ~ i - 1]` 能匹配到 `p[1 ~ j - 1]` 且 `s[i] == p[j]`，那麼 `s[1 ~ i]` 匹配到 `p[1 ~ j]`。所以轉移式為：

  $$d(i,\ j)=d(i-1,\ j-1)\quad if\ \textcolor{red}{p[j+1]\ne*}\ \& \ \textcolor{red}{s[i]=p[j]}$$

3. 再來我們考慮 `p[j]='.'` 的情況，可以發現其實 `p[j]='.'` 的轉移與第二點類似，只是 `.` 可以代表任意字元，因此我們 `s[i]=p[j]` 的條件永遠成立。所以轉移式為：

  $$d(i,\ j)=d(i-1,\ j-1)\quad if\ \textcolor{red}{p[j+1]\ne*}\ \&\ \textcolor{red}{p[j]=.}$$

4. 最後我們考慮 `p[j]='*'` 的情況，有兩種情況能使 `d(i, j) = 1`。
   
   1. 如果 `*` 重複了 0 次，代表此狀態跟上一排一樣，所以轉移式應該與第一點相同。
   2. 如果 `*` 重複一次以上，必須滿足 `*` 的前一個字元 `p[j - 1]` 應該等於當前的 `s[i]`（當然 `p[j - 1] = '.'` 也是可以的），且 `s[1 ~ i - 1]` 要能匹配 `p[1 ~ j]`，也就是 `d(i - 1, j) = 1`。滿足上述兩點性質，就代表我們可以再加上一個 `p[j - 1]` 字元使得 `d(i, j) = 1`。
  
    所以轉移式為：
    $$d(i,\ j)=(\textcolor{red}{d(i,\ j-1)=1}\ |\ \textcolor{blue}{(}\textcolor{red}{d(i-1,j)=1}\ \&\ \textcolor{purple}{(}\textcolor{red}{p[j-1]=s[i]}\ |\ \textcolor{red}{p[j-1]=.}\textcolor{purple}{)}\textcolor{blue}{)}) \quad if\ \textcolor{red}{p[j]=*}$$

## DP 總整理

有了上述 4 點，我們可以整理轉移式為：
  $$d(i,\ j)=d(i,\ j-1)\quad if\ \textcolor{red}{p[i+1]=*}$$

  $$d(i,\ j)=d(i-1,\ j-1)\quad else\ if\ \textcolor{red}{s[i]=p[j]\ |\ p[j]=.}$$

  $$d(i,\ j)=(\textcolor{red}{d(i,\ j-1)}\ |\ \textcolor{blue}{(}\textcolor{red}{d(i-1,j)}\ \&\ \textcolor{purple}{(}\textcolor{red}{p[j-1]=s[i]}\ |\ \textcolor{red}{p[j-1]=.}\textcolor{purple}{)}\textcolor{blue}{)}) \quad else\ if\ \textcolor{red}{p[j]=*}$$

最後我們考慮邊界情況，我們發現：

1. `d(0, 0)=1`：`s` 與 `p` 同時為空應該要算是匹配。
2. `d(i, 0)=0, i > 0`：`p` 為空但 `s` 不為空，不匹配。
3. `d(0, i)`：與 DP 轉移式相同，只是無法從 `d(-1, i)` 轉移，所有轉移皆從 `d(0, i - 1)` 而來。

最終答案即是 `dp[|s|][|p|]`

# 範例與 DP 對照
## Example 1

| s\p | X | a |
|-----|---|---|
| X   | 1 | 0 |
| a   | 0 | 1 |
| a   | 0 | 0 |

## Example 2

| s\p | X | a | * |
|-----|---|---|---|
| X   | 1 | 1 | 1 |
| a   | 0 | 0 | 1 |
| a   | 0 | 0 | 1 |

## Example 4

| s\p | x | c | * | a | * | b |
|-----|---|---|---|---|---|---|
| x   | 1 | 1 | 1 | 1 | 1 | 0 |
| a   | 0 | 0 | 0 | 0 | 1 | 0 |
| a   | 0 | 0 | 0 | 0 | 1 | 0 |
| b   | 0 | 0 | 0 | 0 | 0 | 1 |

# 實作細節
因為真實情況中，`s` 與 `p` 皆為 Base 0（索引從 0 開始），所以實作中可以考慮兩種做法：
1. 將字串都轉換為 Base 1。
2. 將轉移式中的 `d(i, j)` 都變為 `d(i + 1, j + 1)`。

筆者實作中採用的是第二種方法。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/regular-expression-matching/
 */

class Solution {
public:
  bool isMatch(string s, string p) {
    int sLength = (int)s.length();
    int pLength = (int)p.length();

    // 宣告 (sLength + 1) * (pLength + 1) 大小的 2D DP 陣列表格，並初始化為 0
    vector<vector<bool>> dp(sLength + 1, vector<bool>(pLength + 1, false));
    // 邊界 1
    dp[0][0] = true;

    // 邊界 3
    for (int i = 0; i < pLength; i++) {
      if ((i != pLength - 1 && p[i + 1] == '*') || p[i] == '*')
        dp[0][i + 1] = dp[0][i];
    }

    for (int i = 0; i < sLength; i++) {
      for (int j = 0; j < pLength; j++) {
        if (j != pLength - 1 && p[j + 1] == '*') {
          // 轉移 1
          dp[i + 1][j + 1] = dp[i + 1][j];
        } else if ((p[j] == s[i] || p[j] == '.')) {
          // 轉移 2
          dp[i + 1][j + 1] = dp[i][j];
        } else if (p[j] == '*') {
          // 轉移 3
          dp[i + 1][j + 1] = (dp[i + 1][j] || (dp[i][j + 1] && (p[j - 1] == s[i] || p[j - 1] == '.')));
        }
      }
    }

    return dp[sLength][pLength];
  }
};

```

# 感想
這題雖然沒有很複雜，但是要把 DP 的想法表達的清楚真的不簡單呢！

希望大家會喜歡，喜歡的話可以留下 Comments 或是點個讚，謝謝支持～
