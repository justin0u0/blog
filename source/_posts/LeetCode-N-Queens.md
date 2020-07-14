---
title: LeetCode 51 - N-Queens
tags:
  - LeetCode
  - 回朔法（Backtracking）
categories: LeetCode
date: 2020-07-14 09:03:14
---

# 題目
題目連結：[https://leetcode.com/problems/n-queens/](https://leetcode.com/problems/n-queens/)

求 **N-皇后** 的所有可行解。

# 範例說明

```
Input: 4
Output: [
 [".Q..",  // Solution 1
  "...Q",
  "Q...",
  "..Q."],

 ["..Q.",  // Solution 2
  "Q...",
  "...Q",
  ".Q.."]
]
Explanation: There exist two distinct solutions to the 4-queens puzzle as shown above.
```

<!-- More -->

# 想法
八皇后的解可以利用回朔法來求出。

根據皇后的攻擊規則，可以知道一行最多只會放入一個皇后。所以回朔法過程為利用遞迴，嘗試在每一個列（Row）中挑一個行（Column）放入皇后，並記錄下來以利下一個 Row 要挑選位置時能檢查此位置是否能放入皇后。

# 實作細節

利用遞迴函數 `solver(col, n)` 來求解。`col` 為一陣列，`col[i]` 紀錄第 `i` 列（Row）的皇后放在哪一個行（Column）。

首先，`col` 陣列的大小，紀錄為 `row`，即為當前要放入的是哪個 Row。只要當 `row` 不等於 `n` 時，可以知道盤面還沒有被放滿。

則利用迴圈遍歷 `i = 0 ~ n - 1`，`i` 代表當前的想要放入的行（Column）。要能在第 `row` 列的第 `i` 行放下皇后，必須檢查這個皇后會不會攻擊到其他前面已經放下的皇后。

遍歷 `j = 0 ~ row - 1`，`(j, col[j])` 代表前面已經放下的皇后的 `(列、行)`。且已知當前嘗試要放入的皇后在 `(row, i)`。所以當：

1. 兩皇后在同一列上：`j == row`
2. **兩皇后在同一對角線上：`j + col[j] == row + i` 或是 `j - col[j] == row - i`**

代表不能將皇后放在第 `row` 列的第 `i` 行上。

最後，當 `row` 等於 `n` 時，代表皇后已經放滿，所以紀錄當前盤面的解。

# 程式碼
```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/n-queens/
 * Runtime: 16ms
 */

class Solution {
private:
  // 紀錄所有可行解用
  vector<vector<string>> solutions;

  // 遞迴函數 solver
  void solver(vector<int>& col, int n) {
    // row 為當前要放入的列
    int row = (int)col.size();

    // 已經放滿，則紀錄答案到 solutions
    if (row == n) {
      vector<string> solution;
      // i 為列
      for (int i = 0; i < n; i++) {
        string s = "";
        // j 為行
        for (int j = 0; j < n; j++)
          s += (col[i] == j) ? 'Q' : '.';
        solution.emplace_back(s);
      }
      solutions.emplace_back(solution);
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
  vector<vector<string>> solveNQueens(int n) {
    vector<int> col;
    solver(col, n);
    return solutions;
  }
};

```