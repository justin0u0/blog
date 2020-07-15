---
title: LeetCode 57 - Insert Interval
tags:
  - LeetCode
categories: LeetCode
date: 2020-07-15 12:24:31
---

# 題目
題目連結：[https://leetcode.com/problems/insert-interval/](https://leetcode.com/problems/insert-interval/)

給定一個集合的區間，插入一個新的區間並輸出結果。已知給定的區間都不重疊且已經由左到右排好。

# 範例說明
## Example 1:
```
Input: intervals = [[1,3],[6,9]], newInterval = [2,5]
Output: [[1,5],[6,9]]
```

## Example 2:
```
Input: intervals = [[1,2],[3,5],[6,7],[8,10],[12,16]], newInterval = [4,8]
Output: [[1,2],[3,10],[12,16]]
Explanation: Because the new interval [4,8] overlaps with [3,5],[6,7],[8,10].
```

<!-- More -->

# 想法

假設原區間為 `interval`，新區間為 `newInterval`。且區間的左邊界為 `interval.left`、右邊界為 `interval.right`。

首先：
1. 若新區間的左邊界在一個某一原區間中，即 `interval.left <= newInterval.left <= interval.right`：
  則將 `newInterval.left` 延伸至 `interval.left` 並不會使答案改變。
2. 若新區間的右邊界在一個某一原區間中，即 `interval.left <= newInterval.right <= interval.right`：
  則將 `newInterval.left` 延伸至 `interval.right` 並不會使答案改變。

做到上述兩點後，可以發現若原區間若與新區間重疊，則必定被包覆在新區間之中。

所以原區間與新區間的關係只剩下三種：
1. 與新區間不重疊且在新區間的左側，即 `interval.right > newInterval.left`：
   則直接將原區間保留在新區間的左側。
2. 與新區間不重疊且在新區間的右側，即 `interval.left < newInterval.right`：
   則直接將原區間保留在新區間的右側。
3. 與新區間重疊，則原區間被包覆在新區間之中，即 `newInterval.left <= interval.left <= interval.right <= newInterval.right`：
   則原區間消失。
   
# 實作細節

首先，
1. `interval.left <= newInterval.left <= interval.right`，則延伸 `newInterval.left`，即 `newInterval.left = interval.left`。
2. `interval.left <= newInterval.right <= interval.right`，則延伸 `newInterval.right`，即 `newInterval.right = interval.right`。

再來，依序將區間加入一個空的集合 `newIntervals` 之中，所有不被新區間的原區間都能加入。要注意加入的區間在新區間的左側還是右側。

筆者的作法為先將新區間加入 `newIntervals` 之中，若原區間在新區間左側，則將 `newInterals` 的最後一個元素（即 `newInterval`）取代成原區間，並再放入一次 `newInterval`。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/insert-interval/
 * Runtime: 52ms
 */

class Solution {
public:
  vector<vector<int>> insert(vector<vector<int>>& intervals, vector<int>& newInterval) {
    // 延伸新區間
    for (auto interval: intervals) {
      if (interval[0] <= newInterval[0] && newInterval[0] <= interval[1]) newInterval[0] = interval[0];
      if (interval[0] <= newInterval[1] && newInterval[1] <= interval[1]) newInterval[1] = interval[1];
    }
    // 先將新的區間加入
    vector<vector<int>> newIntervals{newInterval};
    for (auto interval: intervals) {
      // 若原區間不被新區間包含，則可以加入
      if (!(newInterval[0] <= interval[0] && interval[1] <= newInterval[1])) {
        if (interval[1] < newInterval[0]) {
          // 在新區間的左側，則交換原區間，新區間的位置
          newIntervals.back() = interval;
          newIntervals.emplace_back(newInterval);
        } else {
          // 在新區間的右側，直接加入
          newIntervals.emplace_back(interval);
        }
      }
    }
    return newIntervals;
  }
};

```
