---
title: LeetCode 300 - Longest Increasing Subsequence
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
  - 二分搜（Binary Search）
categories: LeetCode
date: 2021-03-22 15:49:53
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/longest-increasing-subsequence/](https://leetcode.com/problems/longest-increasing-subsequence/)

找到最長遞增子序列（LIS）的長度。

# 範例說明

## Example 1:

```
Input: nums = [10,9,2,5,3,7,101,18]
Output: 4
Explanation: The longest increasing subsequence is [2,3,7,101], therefore the length is 4.
```

<!-- More -->

## Example 2:

```
Input: nums = [0,1,0,3,2,3]
Output: 4
```

## Example 3:

```
Input: nums = [7,7,7,7,7,7,7]
Output: 1
```

# 想法

## `O(N^2)`

有一種常見的 `O(N^2)` 動態規劃。考慮動態規劃的狀態與轉移，定義狀態 `dp(i)` 等於以第 `i` 個數字為結尾的序列的 LIS 長度，轉移即為：

$$dp(i)=max(1,dp(j) + 1)\quad\forall\ j\lt i\And nums[j]\lt nums[i]$$

如此的狀態轉移十分直觀，以第 `i` 個數字為結尾的序列，代表我們要選擇 `nums[i]`，那麼 `nums[i]` 可以放在 `nums[j]` 後面，如果 `j < i && nums[j] < nums[i]`，因此以 `nums[i]` 為結尾的最長遞增子序列即為所有符合條件的 `j` 中，`dp[j]` 最大的值再加一。若沒有符合的 `j`，則以 `nums[i]` 結尾的最長遞增子序列至少也為 1。

由於狀態有 `N` 種，每次轉移都要花 `O(N)` 的時間，因此總時間複雜度為 `O(N^2)`。

## `O(NlogN)`

要達到 `O(NlogN)` 的想法，首先考慮另一種 `O(N^2)` 的動態規劃。一樣考慮狀態與轉移：

定義狀態 `dp(j)` 代表長度為 `j` 的最長遞增子序列結束在 `dp(j)` 這個數字，若有多個滿足，則選數字最小的。

接著對 `nums[0]`, `nums[1]` ... 進行 N 次的轉移：

假設 `dp(1) = 1, dp(2) = 3, dp(3) = 5, dp(4) = 7`，則當要對 `nums[i] = 4` 進行轉移時，數字 `4` 能產生的最長遞增子序列為 3，因為我們知道 `dp(2) = 3`，所以數字 `4` 可以插入在數字 `3` 之後形成長度 3 的遞增子序列。但是 `dp(3)` 已經有一個數字 `5` 了，因此要選數字較小的來當 `dp(3)` 的值，所以要使 `dp(3)=nums[i]`，還需要有一個條件 `nums[i] < dp(3)`。

因此轉移如下：

$$dp(j)=
  \begin{cases}
    nums[i] &\text{if } dp(j-1)\lt nums[i]\lt dp(j) \\
    dp(j) &\text{else }
  \end{cases}
$$

為了方便實作，可以另 `dp(0)=-INF` 且當 `i > 0`，初始化 `dp(i)=INF`。

```cpp
const INF = 1e9 + 10;
vector<int> dp(n + 1, INF);
dp[0] = -INF;

for (int i = 0; i < n; i++) {
  for (int j = 1; j <= n; j++) {
    if (dp[j - 1] < nums[i] && nums[i] < dp[j])
      dp[j] = nums[i];
  }
}
```

最後，對於所有的 `dp(i)` 且 `dp(i) != INF` 的 `i` 即為最長遞增子序列的長。

因此總時間複雜度為 `O(N^2)`。

觀察上述的轉移與程式碼，可以得到兩個性質：
1. `dp(i-1) < dp(i)`。
2. `nums[i]` 每次恰好更新一個數字。

由於這兩個性質，可以發現只要在 `dp` 陣列上，利用二分搜找到**大於等於 nums[i] 的第一個數字**並取代之，即可將時間複雜度減低到 `O(NlogN)`。

# 實作細節

實作上，可以不用先開好長度為 `N + 1` 的 `dp` 陣列，只在需要的時候增加 `dp` 陣列的長度（也就是不多紀錄值為 `INF` 的部分）：

對於上述的程式碼，當 `nums[i]` 更新的數字是 `INF`，代表多了一個數字需要紀錄，這時才需要增加 `dp` 陣列的長度，而此種情況代表 `nums[i]` 比最後一個非 `INF` 的數字還要大。

如此一來，最後陣列的長度即為最長遞增子序列的長度減一（需要扣除第零個數字 `-INF`）。

另外，找**大於等於 nums[i] 的第一個數字**，可以利用 C++ 的 `lower_bound` 來實作。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/longest-increasing-subsequence/
 * Runtime: 8ms
 */

class Solution {
public:
  int lengthOfLIS(vector<int>& nums) {
    vector<int> lis{-10001};
    for (int num: nums) {
      if (num > lis.back())
        lis.emplace_back(num);
      else
        *lower_bound(lis.begin(), lis.end(), num) = num;
    }
    return (int)lis.size() - 1;
  }
};

```
