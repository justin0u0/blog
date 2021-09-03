---
title: LeetCode 42 - Trapping Rain Water
tags:
  - LeetCode
categories: LeetCode
date: 2020-07-10 10:48:56
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/trapping-rain-water/](https://leetcode.com/problems/trapping-rain-water/)

給定一個長度為 `N` 個序列，代表海拔高度，每個條的寬度都是 1，求下雨時會有多少格水。

# 範例說明

```
Example:

Input: [0,1,0,2,1,0,1,3,2,1,2,1]
Output: 6
```

![](/assets/LeetCode-Trapping-Rain-Water/trapping-rain-water-sample.png)

上圖顯示輸入為 `[0,1,0,2,1,0,1,3,2,1,2,1]` 後 6 格水（藍色）所在的位置。

<!-- More -->

# 想法

把每一個位置的最高水面高度分開計算，在某個位置 `i` 的水面高度為以此條往左的最大高度和往右的最大高度之最小值，也就是：
$$min(max(height[x]), max(height[y])),\quad\ \forall x\lt i,\ y\gt i$$

每個位置的最高水面高度再減去此位置原本的高度就是能累積的水量。

# 實作細節

先紀錄 `left[i]` 代表位置 `i` 的左邊出現過的最大高度。以及 `right[i]` 代表位置 `i` 的右邊出現過的最大高度。先將 `height` 陣列複製到 `left`, `right`。

所以 `left` 應該要由左到右計算 `left[i] = max(left[i], left[i - 1])`。

而 `right` 應該要由右到左計算 `right[i] = max(right[i], right[i + 1])`。

計算後，位置 `i` 的水面最大高度為 `min(left[i], right[i])`。水量為 `min(left[i], right[i]) - height[i]`。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/trapping-rain-water/
 * Runtime: 12ms
 */

class Solution {
public:
  int trap(vector<int>& height) {
    int n = (int)height.size();
    vector<int> left(height);
    vector<int> right(height);

    for (int i = 1; i < n; i++) {
      int j = n - i - 1;
      left[i] = max(left[i], left[i - 1]);
      right[j] = max(right[j], right[j + 1]);
    }

    int sum = 0;
    for (int i = 0; i < n; i++) sum += min(left[i], right[i]) - height[i];
    return sum;
  }
};

```