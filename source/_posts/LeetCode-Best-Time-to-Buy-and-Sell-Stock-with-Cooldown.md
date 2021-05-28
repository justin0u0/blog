---
title: LeetCode 309 - Best Time to Buy and Sell Stock with Cooldown
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2021-05-28 16:30:42
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/](https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/)

給定每一天的股價，第 `i` 天的股價為 `prices[i]`，求出最大的獲利為何。

可以進行多次的買賣，但手上一次只能握有一張股票。並且在股票賣出後，有一天的冷卻時間不能進行買賣。

# 範例說明

## Example 1:

```
Input: prices = [1,2,3,0,2]
Output: 3
Explanation: transactions = [buy, sell, cooldown, buy, sell]
```

<!-- More -->

## Example 2:

```
Input: prices = [1]
Output: 0
```

# 想法

這個題目有很多種定義 DP 狀態的方式，以下提供三種想法：

## 想法一

定義 `dp(i)` 代表對於 `prices[0:i]`，並且第 $i$ 天時進行了賣的動作，所能獲得的最大獲利。

因此可以知道：
$$dp(i)=prices[i]+\red{max\{dp(j)-prices[k]\}}\quad\forall\ j\lt k-1 \lt k\lt i$$

也就是，在第 $i$ 天賣出股票的最大獲利為在第 $j$ 天賣出股票後，在第 $k$ 天買股票，其中因為有冷卻時間的關係，因此 $j\lt k-1$；而買股票至少要在賣股票前一天，因此 $k\lt i$。

有了上述的轉移式，應該可以用一個 $O(N^3)$ 的三層迴圈來解決，然而這個題目最優可以做到 $O(N)$。因此觀察轉關式，可以發現兩件事情：
1. 當 $i$ 增加一時，會獲得一個新的 `prices[k]`（$k'=i-1$），而由 `prices[k']` 產生的 $\red{max\{dp(j)-prices[k]\}}=max\{dp(j)\}-prices[k']$。
2. 當 $i$ 增加一時，也會獲得一個新的 `dp(j)`（$j'=i-3$)。

有了上述的兩個觀察，利用變數 `maxDp` 來紀錄 $max\{dp(j)\}$，並且在每次 $i$ 增加一時，利用 $dp(j')$ 更新 `maxDp`；利用變數 `best` 紀錄 $\red{max\{dp(j)-prices[k]\}}$，並且在每次 $i$ 增加一時，利用 $prices[k']$ 更新 `best`。

最終改變一下轉移式：
$$dp(i)=prices[i]+\red{max\{dp(j)-prices[k]\}}=prices[i]+best$$

實作部分請閱讀 [想法一之實作細節](#想法一之實作細節) 以及 [想法一之程式碼](#想法一之程式碼)。

## 想法二

待補

# 實作細節

## 想法一之實作細節

實作時，可以開一個長度為 `N` 的 DP 陣列，並且依照上面的想法，每當 `i` 增加一時（也就是剛進入迴圈時），更新兩個變數 `maxDp` 以及 `best`。

如下：
```cpp
for (int i = 0; i < n; i++) {
  maxDp = max(maxDp, dp[i - 3]);
  best = max(best, maxDp, prices[i - 3]);

  dp[i] = ...
}
```

不過要注意 `maxDp` 要在 $i\le 3$ 時才能更新；`best` 要在 $i\le 1$ 時才能更新。並且對於兩數的初始值，`maxDp` 初始值等於 0，因為在什麼股票都還沒有賣出的情況下，最大獲利為 0；而 `best` 的初時值為 $-\infin$，對於還沒進行第一次購買股票情況，我們不應該從這個 `best` 來轉移，因此將值設為 $-\infin$ 來避免將從這個點轉移的狀態成為答案。

因此迴圈內部之狀態更新應該如下：

```cpp
for (int i = 0; i < n; i++) {
  // i increase by 1, update `maxDp` and `best`
  if (i >= 3) maxDp = max(maxDp, dp[i - 3]);
  if (i >= 1) best = max(best, maxDp - prices[i - 1]);

  // transition
  dp[i] = prices[i] + best;
}
```

我們可以把 `maxDp` 以及 `best` 的更新移至 DP 轉移的下方：

```cpp
for (int i = 0; i < n; i++) {
  // transition
  dp[i] = prices[i] + best;

  // i is ready to increase by 1, update `maxDp` and `best`
  if (i >= 2) maxDp = max(maxDp, dp[i - 2]);
  best = max(best, maxDp - prices[i]);
}
```

觀察發現，並不需要紀錄整個長度為 N 的陣列，因為迴圈中只使用到了 $dp(i-2)$ 這個位置而已。利用三個變數 `dp0`, `dp1`, `dp2` 分別紀錄 $dp(i),\ dp(i-1),\ dp(i-2)$，即可將程式碼優化成 $O(1)$ 空間使用。

# 程式碼

## 想法一之程式碼

### O(N) Space

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/
 * Runtime: 4ms
 * Time Complexity: O(N)
 * Space Complexity: O(N)
 */

class Solution {
public:
  int maxProfit(vector<int>& prices) {
    int n = prices.size();
    vector<int> dp(n);

    const int inf = 0x3f3f3f3f;
    int maxDp = 0, best = -inf;
    for (int i = 0; i < n; i++) {
      // i increase by 1, update `maxDp` and `best`
      if (i >= 3) maxDp = max(maxDp, dp[i - 3]);
      if (i >= 1) best = max(best, maxDp - prices[i - 1]);

      // transition
      dp[i] = prices[i] + best;
    }
    for (int i = max(0, n - 3); i < n; i++)
      maxDp = max(maxDp, dp[i]);
    return maxDp;
  }
};
```

### O(1) Space

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/
 * Runtime: 0ms
 * Time Complexity: O(N)
 * Space Complexity: O(1)
 */

class Solution {
public:
  int maxProfit(vector<int>& prices) {
    // dp0 = dp(i), dp1 = dp(i - 1), dp2 = dp(i - 2)
    int dp0, dp1 = 0, dp2 = 0;
    int maxDp = 0, best = -0x3f3f3f3f;
    for (int& price : prices) {
      dp0 = price + best;
      maxDp = max(maxDp, dp2);
      best = max(best, maxDp - price);
      dp2 = dp1;
      dp1 = dp0;
    }
    return max(max(maxDp, dp2), max(dp1, dp0));
  }
};
```
