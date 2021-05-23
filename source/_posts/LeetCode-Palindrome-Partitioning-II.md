---
title: LeetCode 132 - Palindrome Partitioning II
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2021-05-23 13:11:55
mathjax: true
---

# 題目

題目連結：[https://leetcode.com/problems/palindrome-partitioning-ii/](https://leetcode.com/problems/palindrome-partitioning-ii/)

給定一個字串 `s`，找出最少需要將字串 `s` 切成幾段使得每一段都是迴文。

# 範例說明

## Example 1:

```
Input: s = "aab"
Output: 1
Explanation: The palindrome partitioning ["aa","b"] could be produced using 1 cut.
```

<!-- More -->

## Example 2:

```
Input: s = "a"
Output: 0
```

## Example 3:

```
Input: s = "ab"
Output: 1
```

# 想法

要將字串 `s` 切分，使得每一段都是迴文。可以發現要求 `s[0:n-1]` 的最小迴文切割段數，可以枚舉任何一段是迴文 `s[j:n-1]` 的，將 `s[j:n-1]` 當做是一段迴文，再接著求 `s[0:j-1]` 之最小迴文切割段數即可。

有了上述的想法，可以發現這是一個 DP 問題，因為答案可以由某一個子答案中求得。

因此，首先定義狀態 `dp(i)` 代表將 `s[0:i]` 切段使得每一段都是迴文所需的最小段數。 則轉移為：
$$dp(i)=\min\big(dp(j)+1\big)\quad\forall\ j\lt i,\ if\ s[j+1:i]\text{ is palindrome}$$

因此剩下的問題變成，如何很快的求得任何一段 `s[j+1:i]` 是否為迴文。利用預處理的方式，可以很簡單的在 $O(N^2)$ 的時間求出每一段子字串是否為迴文，並儲存進一個二維陣列 `isPalindrome[i][j]` 代表 `s[i:j]` 是迴文字串。主要有兩個做法：
1. 枚舉每一個位置做為迴文的中心點（注意偶數長度迴文的情況），往外擴展（左右各往外一格字元，如果相等的話）直到不能在擴展。如此一來只會有 $O(N)$ 個中心點且每個中心點最多往外擴展 $O(N)$ 次，因此總時間複雜度為 $O(N^2)$。
2. 利用 DP 的方式，可以發現：
  $$isPalindrome(i,j)=1\quad if\ s[i]=s[j]\And isPalindrome(i+1,j-1)=1$$
  因此只要從小區間到大區間依次算出答案即可。

# 實作細節

首先對於求 `isPalindrome` 的部分，筆者是採用第二種方式，也就是 DP。

要由小區間到大區間做 DP，務必注意迴圈的順序，通常都可以採用以下的順序：

```cpp
for (int i = n - 1; i >= 0; i--) {
  for (int j = i + 1; j < n; j++) {
    // ...
  }
}
```

另外注意邊界情況，依照轉移式可以知道 `isPalindrome[i][j]` 會由 `isPalindrome[i+1][j-1]` 得到答案，且 $i\lt j$；因此當 $j=i+1$ 時，`isPalindrome[i][i+1]` 由 `isPalindrome[i+1][i]`；當 $j=i+2$ 時，`isPalindrome[i][i+2]` 由 `isPalindrome[i+1][i+1]` 得到。

所以邊界為 $isPalindrome[i][i] = isPalindrome[i+1][i] = true\quad\forall\ i\in n$。

有了 `isPalindrome` 的陣列幫助。後半段的 DP 即可依照上述的轉移式：
$$dp(i)=\min\big(dp(j)+1\big)\quad\forall\ j\lt i,\ if\ isPalindrome[j+1][i]=1$$

一樣需注意邊界情況，由於 $j\ge 0$，因此沒有考慮到 `s[0:i]` 是迴文的情況，因此需另外加上條件當 `isPalindrome[0][i]=1`，則 `dp[i]=0`。

參考下方[程式碼](#two-steps-dp)。

另外，可以發現改變第二次 DP 狀態與轉移，改定義狀態 `dp(i)` 代表將 `s[i~n-1]` 切段使得每一段都是迴文的最小段數，轉移改為：
$$dp(i)=\min\big(dp(j)+1\big)\quad\forall\ j\gt i,\ if\ isPalindrome[i][j-1]=1$$

即可將原本的兩次 $O(N^2)$ 迴圈合併成一次完成。參考下方[程式碼](#one-way-dp)。

# 程式碼

## Two steps DP

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/palindrome-partitioning-ii/
 * Runtime: 74ms
 * Description:
 *  First calculate isPalindrome for all substring,
 *  then use dp(i) represent the min-cut for substring s[0:i],
 *  then dp(i) = min(dp(j) + 1), if isPalindrome(j + 1, i) = true
 */

class Solution {
public:
  int minCut(string s) {
    int n = s.length();
    vector<vector<bool>> isPalindrome(n + 1, vector<bool>(n));
    
    for (int i = n - 1; i >= 0; i--) {
      isPalindrome[i][i] = true;
      isPalindrome[i + 1][i] = true;
      for (int j = i + 1; j < n; j++) {
        isPalindrome[i][j] = (s[i] == s[j] && isPalindrome[i + 1][j - 1]);
      }
    }
    
    int *dp = new int[n];
    for (int i = 0; i < n; i++) {
      if (isPalindrome[0][i]) {
        dp[i] = 0;
      } else {
        dp[i] = 0x3f3f3f3f;
        for (int j = 0; j < i; j++) {
          if (isPalindrome[j + 1][i]) {
            dp[i] = min(dp[i], dp[j] + 1);
          }
        }
      }
    }
    return dp[n - 1];
  }
};
```

## One way DP

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/palindrome-partitioning-ii/
 * Runtime: 60ms
 * Description: One-way O(N) solution
 */

class Solution {
public:
  int minCut(string s) {
    int n = s.length();
    vector<vector<bool>> isPalindrome(n + 1, vector<bool>(n));
    int *dp = new int[n];
    for (int i = n - 1; i >= 0; i--) {
      isPalindrome[i][i] = true;
      isPalindrome[i + 1][i] = true;
      dp[i] = 0x3f3f3f3f;
      for (int j = i + 1; j < n; j++) {
        isPalindrome[i][j] = (s[i] == s[j] && isPalindrome[i + 1][j - 1]);
        if (isPalindrome[i][j - 1]) {
          dp[i] = min(dp[i], dp[j] + 1);
        }
      }
      if (isPalindrome[i][n - 1]) dp[i] = 0;
    }
    return dp[0];
  }
};
```
