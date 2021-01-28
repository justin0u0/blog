---
title: LeetCode 87 - Scramble String
date: 2021-01-28 09:55:33
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
  - 遞迴（Recursion）
categories:
  - LeetCode
---

# 題目

題目連結：[https://leetcode.com/problems/scramble-string](https://leetcode.com/problems/scramble-string)

給定一個字串 `s1`，將 `s1` 分成 `x` 和 `y` 兩段子字串，你可以決定是否將交換兩段子字串的順序，也就是 `s1 = x + y`，或是 `s1 = y + x`。接著再對 `x`, `y` 分別進行一樣的操作，直到字串都變成長度 1 為止。

現在給你另一個字串 `s2`，問是否 `s1` 可以透過上述的操作變成 `s2`。

# 範例說明

## Example 1:

```
Input: s1 = "great", s2 = "rgeat"
Output: true

Explanation: One possible scenario applied on s1 is:
"great" --> "gr/eat" // divide at random index.
"gr/eat" --> "gr/eat" // random decision is not to swap the two substrings and keep them in order.
"gr/eat" --> "g/r / e/at" // apply the same algorithm recursively on both substrings. divide at ranom index each of them.
"g/r / e/at" --> "r/g / e/at" // random decision was to swap the first substring and to keep the second substring in the same order.
"r/g / e/at" --> "r/g / e/ a/t" // again apply the algorithm recursively, divide "at" to "a/t".
"r/g / e/ a/t" --> "r/g / e/ a/t" // random decision is to keep both substrings in the same order.
The algorithm stops now and the result string is "rgeat" which is s2.
As there is one possible scenario that led s1 to be scrambled to s2, we return true.
```

<!-- More -->

## Example 2:

```
Input: s1 = "abcde", s2 = "caebd"
Output: false
```

## Example 3:

```
Input: s1 = "a", s2 = "a"
Output: true
```

# 想法

我們可以枚舉字串的切點，對於每個切點我們也枚舉**交換兩個子字串**或是**不交換兩個子字串**的情形。

最好實現枚舉的方法就是利用遞迴。所以我們可以假設 `isScramble(s1, s2)` 代表 s1 字串有沒有可能透過 scramble 操作變成 s2。

那麼枚舉所有的 `s1 = x1 + y1` 並且：
1. 將 `s2` 字串分為 `s2 = x2 + y2` 且 `x1`, `x2` 等長（那麼 `y1`, `y2` 也會等長），則當 `isScramble(x1, x2) == true && isScramble(y1, y2) == true`，那麼 `isScramble(s1, s2) = true`。
2. 將 `s2` 字串分為 `s2 = x2 + y2` 且 `x1`, `y2` 等長（那麼 `y1`, `x2` 也會等長），則當 `isScramble(x1, y2) == true && isScramble(y1, x2) == true`，那麼 `isScramble(s1, s2) = true`。

若枚舉完上述所有情形，都無法使 `isScramble(s1, s2) = true`，則 `isScramble(s1, s2) = false`。

不過純枚舉所有情形的話，那時間複雜度可能會很慘（當然，因為 LeetCode 的測資都很小，所以不做優化還是會跑的很快），所以我們可以考慮以下兩點優化：
1. 記憶化搜索。也就已經判別過的，我們就不再判別一次。
2. 剪枝。
   1. 已經確認當前的字串不可能符合。那就是當 `s1` 的字母組成與 `s2` 不同時，那不管怎麼交換順序，`s1` 和 `s2` 是永遠都不可能會變成一樣的。
   2. 已經確認當前的字串符合。當 `s1 = s2`，則可以確認 `isScramble(s1, s2) = true`。

# 實作

首先，`l1`, `l2`, `len` 代表要驗證 `isScramble` 的兩個子字串是 `s1[l1, l1 + len - 1]` 以及 `s2[l2, l2 + len - 1]`。

所以 `dp[l1][l2][len]` 代表子字串 `s1[l1, l1 + len - 1]`, `s2[l2, l2 + len - 1]` 的 `isScramble`。

`dp` 陣列初始化為 `-1`，代表還不知道答案。

接著實作遞迴函數 `solver`，當 `dp[l1][l2][len] != -1`，則代表答案已經被求得，直接回傳 `dp[l1][l2][len]` 的答案。

否則可以先進行兩個剪枝，`isSame` 用來判別兩次字串是否相等。`cnt` 則用來判別兩字串的字母組成是否相同，`cnt[0]` 代表字母 `a` 的數量，`cnt[1]` 代表字母 `b` 的數量...，以此類推，在字串 `s1` 將字母用加的加入 `cnt`，字串 `s2` 則將字母用扣的加入 `cnt`，最後 `cnt` 內應該全部為 0 才代表字串的字母組成相同。

若 `isSame == true` 則回傳 `true`，並且要將答案紀錄在 `dp` 陣列中，因此可以簡單的寫成 `return (dp[l1][l2][len] = true)`。

若 `cnt` 中有任何一項不為 0，代表字母組成不同，則回傳 `false`。

最後，枚舉切點以及是否交換順序。`i` 代表字串 `s1 = x1 + y1` 或是 `s1 = y1 + x1` 的 `x1` 字串長度。

當 `s1 = x1 + y1`，則 `s2 = x2 + y2` 的 **`x2` 長度等於 `x1` 長度等於 `i`**，而 **`y1`, `y2` 長度等於** `s1` 長度 `len` 減去 `i`，也就是 **`len - i`**，因此若 `solver(l1, l2, i) == true && solver(l1 + i, l2 + i, len - i) == true`，則回傳 `true`。

當 `s1 = y1 + x1`，則 `s2 = x2 + y2` 的 **`x2` 長度等於 `y1` 長度等於 `len - i`**，而 **`y2`, `x1` 長度等於 `i`**，因此若 `solver(l1 + i, l2, len - i) == true && solver(l1, l2 + len - i, i) == true`，則回傳 `true`。

最後，若都沒有符合的，則回傳 `false`。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/scramble-string/
 * Runtime: 4ms
 */

class Solution {
public:
  int dp[31][31][31];

  bool solver(string& s1, int l1, string& s2, int l2, int len) {
    if (dp[l1][l2][len] != -1)
      return dp[l1][l2][len];

    bool isSame = true;
    int cnt[26] = {0};
    for (int i = 0; i < len; i++) {
      if (s1[l1 + i] != s2[l2 + i])
        isSame = false;
      ++cnt[s1[l1 + i] - 'a'];
      --cnt[s2[l2 + i] - 'a'];
    }
    if (isSame)
      return (dp[l1][l2][len] = true);
    for (int i = 0; i < 26; i++) {
      if (cnt[i])
        return (dp[l1][l2][len] = false);
    }

    for (int i = 1; i < len; i++) {
      if (solver(s1, l1, s2, l2, i) && solver(s1, l1 + i, s2, l2 + i, len - i))
        return (dp[l1][l2][len] = true);
      if (solver(s1, l1 + i, s2, l2, len - i) && solver(s1, l1, s2, l2 + len - i, i))
        return (dp[l1][l2][len] = true);
    }
    return (dp[l1][l2][len] = false);
  }

  bool isScramble(string s1, string s2) {
    memset(dp, -1, sizeof(dp));
    return solver(s1, 0, s2, 0, s1.length());
  }
};

```
