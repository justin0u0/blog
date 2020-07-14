---
title: LeetCode 52 - N-Queens II
tags:
  - LeetCode
  - 回朔法（Backtracking）
categories: LeetCode
date: 2020-07-14 09:51:23
---

# 題目
題目連結：[https://leetcode.com/problems/n-queens-ii/](https://leetcode.com/problems/n-queens-ii/)

求 **N-皇后** 的解的數量。

# 範例說明

```
Input: 4
Output: 2
Explanation: There are two distinct solutions to the 4-queens puzzle as shown below.
[
 [".Q..",  // Solution 1
  "...Q",
  "Q...",
  "..Q."],

 ["..Q.",  // Solution 2
  "Q...",
  "...Q",
  ".Q.."]
]
```

<!-- More -->

# 想法

與上一題：[LeetCode N-Queens](https://blog.justin0u0.com/LeetCode-N-Queens) 相同，但是不用紀錄解的數量。

# 實作細節

實作細節可以參考 [LeetCode N-Queens](https://blog.justin0u0.com/LeetCode-N-Queens)，本題在 `row` 等於 `n` 時不需要紀錄解的樣子，只需要將一個計數器 `solutions` 加一即可。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/n-queens-ii/
 * Runtime: 8ms
 */

class Solution {
private:
  int solutions = 0;
  void solver(vector<int>& col, int n) {
    // row 為當前要放入的列
    int row = (int)col.size();
    // 已經放滿，將 solutions 加一
    if (row == n) {
      solutions++;
      // 遞迴終止並返回
      return;
    }

    // 嘗試放入每一行，嘗試將皇后放在 (row, i)
    for (int i = 0; i < n; i++) {
      bool ok = true;
      // 檢查前面放入的皇后有沒有衝突，前面的皇后在 (j, col[j])
      for (int j = 0; j < row; j++) {
        // 有衝突，將 ok 設成 false
        if (col[j] == i || j + col[j] == row + i || j - col[j] == row - i) {
          ok = false;
          break;
        }
      }
      // 沒有衝突
      if (ok) {
        // 將皇后放在 (row, i)
        col.emplace_back(i);
        solver(col, n);
        // 遞迴結束後將放在第 row 列的皇后拿出來
        col.pop_back();
      }
    }
  }
public:
  int totalNQueens(int n) {
    vector<int> col;
    solver(col, n);
    return solutions;
  }
};

```
