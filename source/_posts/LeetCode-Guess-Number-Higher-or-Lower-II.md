---
title: LeetCode 375 - Guess Number Higher or Lower II
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2021-05-23 11:28:34
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/guess-number-higher-or-lower-ii/](https://leetcode.com/problems/guess-number-higher-or-lower-ii/)

猜數字遊戲，答案在 $1 \sim n$ 之內。

每次猜測一個數字 $x$，如果猜對了則遊戲結束，若猜錯了則需要付 $x$ 元，並且會被告之正確答案大於 $x$ 或是小於 $x$。

找出一種猜數字的方式，使得不管答案是多少，花費都是最少的（也就是不管答案是多少，花費最大的那種答案要盡量小）。

# 範例說明

## Example 1

![](https://assets.leetcode.com/uploads/2020/09/10/graph.png)

<!-- More -->

```
Input: n = 10
Output: 16
Explanation: The winning strategy is as follows:
- The range is [1,10]. Guess 7.
    - If this is my number, your total is $0. Otherwise, you pay $7.
    - If my number is higher, the range is [8,10]. Guess 9.
        - If this is my number, your total is $7. Otherwise, you pay $9.
        - If my number is higher, it must be 10. Guess 10. Your total is $7 + $9 = $16.
        - If my number is lower, it must be 8. Guess 8. Your total is $7 + $9 = $16.
    - If my number is lower, the range is [1,6]. Guess 3.
        - If this is my number, your total is $7. Otherwise, you pay $3.
        - If my number is higher, the range is [4,6]. Guess 5.
            - If this is my number, your total is $7 + $3 = $10. Otherwise, you pay $5.
            - If my number is higher, it must be 6. Guess 6. Your total is $7 + $3 + $5 = $15.
            - If my number is lower, it must be 4. Guess 4. Your total is $7 + $3 + $5 = $15.
        - If my number is lower, the range is [1,2]. Guess 1.
            - If this is my number, your total is $7 + $3 = $10. Otherwise, you pay $1.
            - If my number is higher, it must be 2. Guess 2. Your total is $7 + $3 + $1 = $11.
The worst case in all these scenarios is that you pay $16. Hence, you only need $16 to guarantee a win.
```

## Example 2:

```
Input: n = 1
Output: 0
Explanation: There is only one possible number, so you can guess 1 and not have to pay anything.
```

## Example 3:

```
Input: n = 2
Output: 1
Explanation: There are two possible numbers, 1 and 2.
- Guess 1.
    - If this is my number, your total is $0. Otherwise, you pay $1.
    - If my number is higher, it must be 2. Guess 2. Your total is $1.
The worst case is that you pay $1.
```

# 想法

首先，以遞迴的想法來說。一開始要求的是猜測 $1 \sim n$ 的數字的最小花費，定為 `minCost(1, n)`。

假設猜測的數字為 $x$，且 $1\le x \le n$，則有三種情形：
1. 猜中了，則花費為 0，遊戲結束。
2. 沒猜中，且正確答案大於 $x$，則花費 $x$ 元且繼續猜測 $x+1 \sim n$。
3. 沒猜中，且正確答案小於 $x$，則花費 $x$ 元且繼續猜測 $1 \sim x-1$。

由於三種情況都是有可能發生的，因此：

$$
minCost(1,n)=\max 
  \begin{cases}
   0 &\text{case 1} \\
   x+minCost(x+1,n) &\text{case 2} \\
   x+minCost(1,x-1) &\text{case 3} \\
  \end{cases}
$$

有了上述的式子，我們可以總結並整理，對於猜測 $i \sim j$ 之間的數字的最小花費，定為 `minCost(i, j)`，我們可以猜測任何一個 $i\le k \le j$ 的數字 $k$，因此：

$$
minCost(i,j)=\min
\begin{Bmatrix}\max 
    \begin{Bmatrix}
      0 \\
      k+minCost(k+1,j) \\
      k+minCost(i,k-1) \\
    \end{Bmatrix}
  \quad\forall\ i\le k \le j
\end{Bmatrix}
$$

# 實作細節

實作上，當然可以直接的使用遞迴來求出答案，但是會發現很多情況下重複的 `minCost(i, j)` 被呼叫，但其實對於一樣的 `minCost(i, j)`，並不需要重複的求得。

因此，可以記憶化搜索的方式，也就是開一個二維的陣列 `dp[i][j]` 代表 `minCost(i, j)` 的答案。初始化時使全部的 `dp[i][j] = -1`，則呼叫 `minCost(i, j)` 時可以先檢查 `dp[i][j]`，若 `dp[i][j] != -1` 則直接回傳 `dp[i][j]`。

有了這樣的想法後，其實可以很輕易的將 top-down 的遞迴改為 botton-up 的迴圈形式 DP；改為迴圈形式之 DP 時，要**注意迴圈的順序**，由於大區間的答案是由小區間求得的，因此要**先求得小區間答案**，一般情況下，都可以使用以下的迴圈順序：

```cpp
for (int i = n - 1; i >= 0; i--) {
  for (int j = i + 1; j < n; j++) {
    cout << i << ' ' << j << endl;
    dp[i][j] = ...;
  }
}
```

此時的 DP 狀態為 `dp(i, j)` 代表猜測數字 $i \sim j$ 的最小花費，轉移為：
$$dp(i,j)=\min\bigg(\max\big(dp(i,k-1), dp(k+1,i)\big)+k\quad\forall\ k\in [i,j]\bigg)$$

注意邊界情況，當 $i=j$，一定會猜中，因此 **$dp(i,i)=1$**。

最後，DP 的狀態有 $N^2$ 種，對於每個狀態需要花至多 $O(N)$ 的時間轉移，因此總時間複雜度為 $O(N^3)$。

另外，由於筆者的陣列只有開恰好 $n$ 格，因此要注意 `dp(i,j)` 其實是對應到 $i+1\sim j+1$ 的最小花費。

# 程式碼

## Top-down DP

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/guess-number-higher-or-lower-ii/
 * Runtime: 164ms
 * Time Complexity: O(N^3)
 * Description: Top-down DP
 */

class Solution {
private:
  int** dp;
  int minCost(int i, int j) {
    if (i > j)
      return 0x3f3f3f3f;
    if (i == j)
      return 0;

    if (dp[i][j] != -1)
      return dp[i][j];

    dp[i][j] = min((i + 1) + minCost(i + 1, j), minCost(i, j - 1) + (j + 1));
    for (int k = i + 1; k < j; k++) {
      dp[i][j] = min(dp[i][j], max(minCost(i, k - 1), minCost(k + 1, j)) + k + 1);
    }
    return dp[i][j];
  }
public:
  int getMoneyAmount(int n) {
    dp = new int*[n];
    for (int i = 0; i < n; i++) {
      dp[i] = new int[n];
      memset(dp[i], -1, sizeof(int) * n);
    }
    return minCost(0, n - 1);
  }
};
```

## Bottom-up DP

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/guess-number-higher-or-lower-ii/
 * Runtime: 40ms
 * Time Complexity: O(N^3)
 * Description: Bottom-up DP
 */

class Solution {
public:
  int getMoneyAmount(int n) {
    int** dp = new int*[n];
    for (int i = 0; i < n; i++) {
      dp[i] = new int[n]();
    }

    for (int i = n - 1; i >= 0; i--) {
      for (int j = i + 1; j < n; j++) {
        dp[i][j] = min((i + 1) + dp[i + 1][j], dp[i][j - 1] + (j + 1));
        for (int k = i + 1; k < j; k++) {
          dp[i][j] = min(dp[i][j], max(dp[i][k - 1], dp[k + 1][j]) + (k + 1));
        }
      }
    }
    return dp[0][n - 1];
  }
};
```
