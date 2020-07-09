---
title: LeetCode 41 - First Missing Positive
tags:
  - LeetCode
categories: LeetCode
date: 2020-07-09 10:36:04
---

# 題目
題目連結：[https://leetcode.com/problems/first-missing-positive/](https://leetcode.com/problems/first-missing-positive/)

給一數字序列，找出序列中最小沒有出現的正整數。

要求時間複雜度 `O(N)`，空間複雜度 `O(1)`。

# 範例說明

## Example 1
```
Input: [1,2,0]
Output: 3
```

## Example 2:
```
Input: [3,4,-1,1]
Output: 2
```

## Example 3:
```
Input: [7,8,9,11,12]
Output: 1
```

<!-- More -->

# 想法

假設序列名為 `a`，長為 `N`，索引從開始，則答案一定在 `1 ~ N + 1` 之間。

若序列有出現 `x`，且 `x` 在 `1 ~ N` 之間，且將 `a[x - 1]` 設置為 `x` 來代表數字 `x` 有出現過。則由左至右第一個 `a[i - 1] != i` 的 `i` 就是我們要找的答案。

在將 `a[x - 1]` 設置為 `x` 時，`a[x - 1]` 可能還存放著其他數字，但這時候存放 `x` 的位置就空下來了，所以可以想成是將兩個數字交換。

數字交換後，`a[x - 1]` 被放置到當前的位置，所以 `a[x - 1]` 所存之數字要立即被處理，否則將繼續向下遍歷就不會再經過這個數字了。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/first-missing-positive/
 * Runtime: 4ms
 */

class Solution {
public:
  int firstMissingPositive(vector<int>& nums) {
    int n = (int)nums.size();
    for (int i = 0; i < n; i++) {
      while (nums[i] > 0 && nums[i] <= n && nums[nums[i] - 1] != nums[i])
        swap(nums[nums[i] - 1], nums[i]);
    }
    for (int i = 0; i < n; i++)
      if (nums[i] != i + 1)
        return i + 1;
    return n + 1;
  }
};

```
