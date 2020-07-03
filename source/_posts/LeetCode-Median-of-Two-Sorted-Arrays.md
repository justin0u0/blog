---
title: LeetCode 4 - Median of Two Sorted Arrays
date: 2020-07-02 14:05:38
tags:
  - LeetCode
categories: LeetCode
---

# 題目
給定兩個排序好的序列 `nums1` 和 `nums2`，長度分別為 `m` 和 `n`。

找到兩個序列的中位數。

# 範例說明

**Example 1**
```
nums1 = [1, 3]
nums2 = [2]

The median is 2.0
```

**Example 2**
```
nums1 = [1, 2]
nums2 = [3, 4]

The median is (2 + 3)/2 = 2.5
```

<!-- more -->

# 想法
我們先將題目想成從兩個序列中求出第 k 大的數字。

題目要求時間複雜度為 `O(log(m + n))`，所以我們首先想到如果能每一次都捨去總長度一半的序列，那我們的最終時間複雜度就會是 `O(log(m + n))`。

那我們要如何知道哪段序列是可以捨去的呢？
假設 `nums1` 以及 `nums2` 都是從索引值 0 開始編號。

**我們比較任意 `nums1[i]` 以及 `nums2[j]`，如果 `nums1[i] < nums2[j]`，那 `nums1[i]` 最大的可能性為第 `i + j + 1` 大（如果 `nums1[0] ~ nums1[i - 1], nums2[0] ~ nums2[j - 1]` 都小於 `nums1[i]`）。反之亦然，如果 `nums1[i] > nums2[j]`，那 `nums2[j]` 最大的可能性也是第 `i + j + 1` 大**。

也就是：
1. `nums1[i] < nums2[j]`，`nums1[i]` 最大為第 `i + j + 1` 大。
2. `nums1[i] >= nums2[j]`, `nums2[j]` 最大為第 `i + j + 1` 大。

知道了這個性質後，如果我們取 `i = k / 2 - 1` 且 `j = k / 2 - 1`，那上述兩點會變為：
1. `nums1[i] < nums2[j]`，`nums1[i]` 最大為第 `k - 1` 大。
2. `nums1[i] >= nums2[j]`, `nums2[j]` 最大為第 `k - 1` 大。

也就是說，如果 `nums1[i] < nums2[j]`，我們可以捨去 `nums1[0] ~ nums1[i]`，因為 `nums1[i]` 至多才第 `k - 1` 大而已。捨去後部分序列後，我們要找的變成剩下的序列中第 `k - 捨去的數字數量` 大的數字。

最後，如果一序列已被完全捨棄，那答案必定是另一個序列的第 `k` 大數字。或是當 `k` 剩下 1 時，我們知道答案為兩個序列的第一個數字的最小值。

因為我們每次都捨去至少 `k / 2` 個數字，所以 `k` 每次都會變小一半，直到 `k = 1` 為止，所以時間複雜度為 `O(log(k))`。而 `k = m + n / 2`，所以總時間複雜度為 `O(log(m + n / 2)) = O(log(m + n))`。

# 實作細節
`arr1` 為 `nums1` 之序列指標；`arr2` 為 `nums2` 之序列指標。

`m` 為 `arr1` 當前之長度，`n` 為 `arr2` 當前之長度。

[可以利用 `vector.data()` 來拿到序列的指標。](http://www.cplusplus.com/reference/vector/vector/data/)

若要刪除 `arr1[0] ~ arr1[i - 1]`，則將指標向後移動 `i` 格，將序列長度 `m` 減少 `i`，將 `k` 減去 `i`。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/median-of-two-sorted-arrays/
 */

class Solution {
  // 在 arr1[0 ~ m - 1], arr2[0 ~ n - 1] 中，找到第 k 大數字。
  int findKthNumber(int *arr1, int *arr2, int m, int n, int k) {
    // 當 arr1 為空，答案在 arr2 中
    if (m == 0) {
      return arr2[k - 1];
    }
    // 當 arr2 為空，答案在 arr1 中
    if (n == 0) {
      return arr1[k - 1];
    }
    // 當 k = 1，答案為兩序列中第一個數字的最小值
    if (k == 1) {
      return arr1[0] < arr2[0] ? arr1[0] : arr2[0];
    }

    // 當 m < k / 2 或是 n < k / 2 時，取 i = m 或是 j = n，一樣滿足上述式子
    int i = min(k / 2, m);
    int j = min(k / 2, n);
    // 捨棄較小一端的部分序列
    if (arr1[i - 1] < arr2[j - 1]) {
      // 捨棄 arr1[0] ~ arr1[i - 1]
      return findKthNumber(arr1 + i, arr2, m - i, n, k - i);
    } else {
      // 捨棄 arr2[0] ~ arr2[j - 1]
      return findKthNumber(arr1, arr2 + j, m, n - j, k - j);
    }
  }
public:
  double findMedianSortedArrays(vector<int>& nums1, vector<int>& nums2) {
    int m = (int)nums1.size();
    int n = (int)nums2.size();
    int k = (n + m) / 2 + 1;
    // 如果總長度為奇數，中位數 = 第 (n + m) / 2 + 1 大的數字
    if ((n + m) & 1) {
      return findKthNumber(nums1.data(), nums2.data(), m, n, k);
    }
    // 如果總長度為偶數，中位數 = 第 (n + m) / 2 + 1, (n + m) / 2 大的數字之平均
    return (findKthNumber(nums1.data(), nums2.data(), m, n, k) + findKthNumber(nums1.data(), nums2.data(), m, n, k - 1)) / 2.0;
};

```
