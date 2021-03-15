---
title: LeetCode 456 - 132 Pattern
tags:
  - LeetCode
  - 堆疊（Stack）
  - 單調棧（Monotone Stack）
categories: LeetCode
date: 2021-03-06 04:41:05
---

# 題目
題目連結：[https://leetcode.com/problems/132-pattern/](https://leetcode.com/problems/132-pattern/)

給定一個序列 `nums`，問是否能找到三個數字 `nums[i]`、`nums[j]` 與 `nums[k]`，使得 `nums[i] < nums[k] < nums[j]` 且 `i < j < k`。

# 範例說明

## Example 1:

```
Input: nums = [1,2,3,4]
Output: false
Explanation: There is no 132 pattern in the sequence.
```

<!-- More -->

## Example 2:

```
Input: nums = [3,1,4,2]
Output: true
Explanation: There is a 132 pattern in the sequence: [1, 4, 2].
```

## Example 3:

```
Input: nums = [-1,3,2,0]
Output: true
Explanation: There are three 132 patterns in the sequence: [-1, 3, 2], [-1, 3, 0] and [-1, 2, 0].
```

# 想法

## 簡單的 O(N^2) 想法

首先，只考慮找到 `nums[i] < nums[j]` 且 `i < j`，最單純的想法當然是使用兩個迴圈遍歷所有的 `i` 與 `j`，並檢查有沒有 `nums[i] < nums[j]` 的情況，這樣的時間複雜度是 `O(N^2)`。
```cpp
for (int j = 0; j < n; j++)
  for (int i = 0; i < j; i++)
    if (nums[i] < nums[j])
      return true;
```

可以發現，這裡筆者特別把 `i`、`j` 迴圈的順序對調了。如此一來，觀察中間的 `i` 迴圈，可以發現每一次 `i` 迴圈都只比上一次多檢查了一個數字。並且，對於 `nums[j]` 來說，要檢查有沒有 `nums[i] < nums[j]` 且 `i < j` 等價於檢查 `min(nums[0] ~ nums[i])` 有沒有小於 `nums[j]`。有了這兩個性質，就可以利用一個變數 `minValue`，紀錄 `nums[0] ~ nums[j - 1]` 的最小值，對於每一個 `nums[j]` 檢查 `minValue` 有沒有小於 `nums[j]` 即可。
```cpp
int minValue = INT_MAX;
for (int j = 0; j < n; j++) {
  if (minValue < nums[j])
    return true;
  minValue = min(minValue, nums[j]);
}
```

到了這裡，回到原先的題目，利用額外的一個迴圈檢查是否數字 `nums[k]` 滿足條件即可。
```cpp
int minValue = INT_MAX;
for (int j = 0; j < n; j++) {
  if (minValue < nums[j]) { // 可省略，裡面的 if 已包含 minValue < nums[j] 的判斷
    for (int k = j + 1; k < n; k++)
      if (minValue < nums[k] && nums[k] < nums[j])
        return true;
  }
  minValue = min(minValue, nums[j]);
}
```

## 由 O(N^2) 到 O(N) 的想法一

一樣使用上述的想法，要將兩個迴圈變成一個迴圈的首要條件就是先讓裡面的迴圈變為一次增加一個數字，我們改變外層迴圈的順序。

```cpp
int minValue = INT_MAX;
for (int j = n - 1; j >= 0; j--) {
  for (int k = j + 1; k < n; k++)
    if (minValue < nums[k] && nums[k] < nums[j])
      return true;
  minValue = min(minValue, nums[j]); // minValue cannot be maintained
}
```

這時會發現原本的 `minValue` 紀錄著 `nums[0] ~ nums[j - 1]` 的最小值，因為現在的迴圈順序不是一次增加一個 `nums[j]`，而是一次減少一個 `nums[j]`，而無法紀錄了。

因此，可以將 `minValue` 的計算與之分離。

```cpp
vector<int> minValues(n);
int minValue = INT_MAX;
for (int j = 0; j < n; j++) {
  minValues[j] = minValue;
  minValue = min(minValue, nums[j]);
}
for (int j = n - 1; j >= 0; j--) {
  for (int k = j + 1; k < n; k++)
    if (minValues[j] < nums[k] && nums[k] < nums[j])
      return true;
```

現在內層的 `k` 迴圈每次都增加一個檢查一個數字 `nums[j]`，可以觀察到：
1. 比 `minValues[j]` 還小的數字都沒有用，再下一輪之後也不會有用，因為 `minValues[j]` 只會越來越大，所以 `nums[k]` 在這輪比 `minValues[j]` 小的話，那再下一輪也會比 `minValues[j]` 小。
2. 排除所有 `nums[k]` 小於 `minValues[j]` 的數字後，若最小的 `nums[k]` 比 `nums[j]` 小，則找到答案。

利用一個堆疊，維護一個遞增序列。每次先將比 `minValues[j]` 小的數字都移除，因為序列是遞增的，所以只要不斷的移除堆疊頂部元素即可。完成後堆疊內的元素都比 `minValues[j]` 小了，且堆疊為遞增的，因此只要比較堆疊頂部元素若比 `nums[j]` 小，則找到答案。若沒有，則直接將 `nums[j]` 加入到堆疊中，這裡不需多做檢查，因為能加入到堆疊中代表堆疊為空或是 `nums[j]` 小於堆疊頂部元素，因此直接加入後堆疊還是遞減的。

因為每一個元素只會被加入、離開堆疊一次，因此總時間複雜度是 `O(N)`。

程式碼見下方。

## 由 O(N^2) 到 One Pass O(N) 的想法二

**待補**

# 實作細節

# 程式碼

## 想法一 Time O(N), Space O(N)
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/132-pattern/
 * Runtime: 12ms
 */

class Solution {
public:
  bool find132pattern(vector<int>& nums) {
    int n = (int)nums.size();
    vector<int> minValues(n);

    int minValue = nums[0];
    for (int i = 0; i < n; i++) {
      minValues[i] = minValue;
      minValue = min(minValue, nums[i]);
    }
    stack<int> stk;
    for (int i = n - 1; i >= 0; i--) {
      while (!stk.empty() && stk.top() <= minValues[i])
        stk.pop();
      if (!stk.empty() && stk.top() < nums[i])
        return true;
      stk.push(nums[i]);
    }
    return false;
  }
};

```

## 想法二 Time O(N), Space O(N)

**待補**