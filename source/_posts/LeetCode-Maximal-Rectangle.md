---
title: LeetCode 85 - Maximal Rectangle
tags:
  - LeetCode
  - 堆疊（Stack）
categories: LeetCode
date: 2020-07-21 09:20:29
---

# 題目
題目連結：[https://leetcode.com/problems/maximal-rectangle/](https://leetcode.com/problems/maximal-rectangle/)

給一個二維的 01 陣列，找到全部都是 1 的最大矩形。

# 範例說明

```
Input:
[
  ["1","0","1","0","0"],
  ["1","0","1","1","1"],
  ["1","1","1","1","1"],
  ["1","0","0","1","0"]
]
Output: 6
```

<!-- More -->

# 想法

假設矩形大小為 `N * M`。

首先，最大的矩形一定會為某一橫列（Row）為底而形成。

而要找出以第 `i` 列為底邊形成的最大矩形，可以先將 01 矩陣的轉換成高度值，也就是將 `matrix[i][j]` 轉換成由 `(i, j)` 開始向上有幾個連續的 1。

以範例當參考，轉換後的結果如下：

```
[
  [1, 0, 1, 0, 0],
  [2, 0, 2, 1, 1],
  [3, 1, 3, 2, 2],
  [4, 0, 0, 3, 0]
]
```

接著，以第 `i` 列為底能形成的最大正方形一定是以某一個 `(i, j)` 的高度為高，向左右延伸直到不能再延伸為止。

要證明這個特性並不難，以第 `i` 列為底的最大正方形，若當前的矩形不以任何一個 `(i, j)` 的高度為高，則矩形可以增高、變得更大。若當前矩形還可以向左右延伸，則矩形可以增加寬度，也會變得更大。所以最大的矩形之高度一定是以某一個 `(i, j)` 的高度為高，並向左右延伸直到不能再延伸為止。

此部分的證明在筆者的上一篇 Blog [LeetCode - Largest Rectangle in Histogram](https://blog.justin0u0.com/LeetCode-Largest-Rectangle-in-Histogram/) 中也有提到。

將所有以第 `i` 列為底邊能形成的最大矩形取最大值，就是此題的答案。而如何計算以第 `i` 列為底邊能形成的最大矩形，可以參考 [LeetCode - Largest Rectangle in Histogram](https://blog.justin0u0.com/LeetCode-Largest-Rectangle-in-Histogram/)，裡面有詳細的說明，這裡只簡單帶過。

利用一堆疊（Stack）維護由左至右的遞增序列，要加入一新的高度時，將堆疊內比此高度大的值移除，此時堆疊的頂端元素即為此位置能延伸到的最左處。

反之，利用 Stack 維護由右至左的遞增序列，要加入一新的高度時，將堆疊內比此高度大的值移除，此時堆疊的頂端元素即為此位置能延伸到的最右處。

計算第 `i` 列所需的時間為 `O(M)`，總共有 `N` 列，總時間複雜度為 `O(NM)`。

# 實作細節

對於每一個列，有四件事情要照順序執行：
1. 計算以 `(i, j)` 向上最多有幾個連續的 1，即計算高度 `heights[i][j]`。
2. 由左到右計算 `left[j]` 代表以 `(i, j)` 為高，最多能向左延伸多少。
3. 由右到左計算 `right[j]` 代表以 `(i, j)` 為高，最多能向右延伸多少。
4. 計算所有矩形面積的最大值，位置 `(i, j)` 之矩形面積為 `(left[j] + right[j] - 1) * heights[i][j]`。

更詳細的實作細節可以參考 [LeetCode - Largest Rectangle in Histogram](https://blog.justin0u0.com/LeetCode-Largest-Rectangle-in-Histogram/)，這裡只說明高度如何計算。

若 `matrix[i][j]` 為 0，則高度為 0。否則其高度為 `matrix[i - 1][j]` 之高度加一。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/maximal-rectangle/
 * Runtime: 60ms
 */

class Solution {
public:
  int maximalRectangle(vector<vector<char>>& matrix) {
    if (matrix.empty() || matrix[0].empty()) return 0;
    int n = (int)matrix.size();
    int m = (int)matrix[0].size();

    // heights[j] 代表位置 (i, j) 的高度
    vector<int> heights(m);
    // left[j] 代表以位置 (i, j) 之高度為高的矩形能向左延伸的長度
    vector<int> left(m);
    // 陣列模擬 stack，idx 為陣列頂端元素，idx = 0 代表 stack 為空。因 stack 從 1 開始編號，其長度需多 1
    vector<int> stk(m + 1);
    // 紀錄最大矩形用
    int maximal = 0;
    for (int i = 0; i < n; i++) {
      // 將 stack 
      int idx = 0;
      for (int j = 0; j < m; j++) {
        // 計算高度
        if (i && matrix[i][j] == '1') {
          // 不是第 0 排且 matrix[i][j] 為 1，高度為上一列之高度加一
          ++heights[j];
        } else {
          heights[j] = matrix[i][j] - '0';
        }

        // 維護遞增序列
        while (idx && heights[stk[idx]] >= heights[j]) --idx;
        // 計算向左延伸之長
        if (!idx) left[j] = j + 1;
        else left[j] = j - stk[idx];
        // 將當前索引加入 stack 之中
        stk[++idx] = j;
      }

      // 清空 stack 給下一個步驟使用
      idx = 0;
      // 由右至左
      for (int j = m - 1; j >= 0; j--) {
        // 維護遞增序列
        while (idx && heights[stk[idx]] >= heights[j]) --idx;
        // right 即 right[j]，代表以位置 (i, j) 之高度為高的矩形可以向右延伸的長度，但不開陣列紀錄
        int right;
        // 計算向右延伸之長
        if (!idx) right = m - j;
        else right = stk[idx] - j;
        // 將當前索引加入 stack 之中
        stk[++idx] = j;

        // 計算面積、更新最大面積
        maximal = max(maximal, (left[j] + right - 1) * heights[j]);
      }
    }
    return maximal;
  }
};

```
