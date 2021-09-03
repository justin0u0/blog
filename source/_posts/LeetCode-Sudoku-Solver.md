---
title: LeetCode 37 - Sudoku Solver
tags:
  - LeetCode
  - 回朔法（Backtracking）
categories: LeetCode
date: 2020-07-08 10:25:07
---

# 題目
題目連結：[https://leetcode.com/problems/sudoku-solver/](https://leetcode.com/problems/sudoku-solver/)

給一個數獨，保證存在唯一一組解，求出數獨。

# 範例說明

**A sudoku puzzle:**
![](/assets/LeetCode-Sudoku-Solver/sudoku-solver-start.png)
**The sudoku puzzle solution:**
![](/assets/LeetCode-Sudoku-Solver/sudoku-solver-end.png)

<!-- More -->

# 想法

解數獨最簡單的方法為回朔法。所謂回朔法其實就是利用遞迴暴力嘗試，對於每一個數獨的空格，都暴力嘗試填入 `1 ~ 9`。若發現填不下去了，則返回到上一步嘗試填入下一種數字。

當然，若要解的數獨比九乘九大小更大，可以將數獨轉換為**精準覆蓋問題**，再利用**舞蹈鏈**求解。（待補）

# 實作細節

實作上，遞迴函數 `solver` 攜帶 `x`, `y` 代表當前位置。如果當前位置為數字則跳過，否則嘗試填入 `1 ~ 9`。

填入數字 `i` 時檢查此位置是否能夠填入，所以只要檢查：
1. 第 `x` 列（row）是否有 `i`。
2. 第 `y` 行（column）是否有 `i`。
3. `(x, y)` 所在的方格（block）內是否有填入 `i`。
   若我們將方格編號，由左到右、由上到下為 `0 ~ 9` 號，則 `(x, y)` 所在的方格編號為 `x / 3 * 3 + y / 3`。

檢查數字可以使用迴圈檢查，或是額外紀錄布林值陣列 `row[i][j]`, `col[i][j]`, `block[i][j]` 分別代表第 `i` 個列、行、方格有沒有數字 `j`。
當然，要額外紀錄陣列就必須在初始化時先遍歷整個數獨，但是在檢查時可以 `O(1)` 知道數字能否填入。
不額外紀錄陣列雖然程式碼較簡潔，但速度稍慢一些。

在 `(x, y)` 填入數字 `i` 後，向下一格遞迴。**不要忘記在遞迴返回後恢復原本的盤面**（在呼叫函數後的下一行）。
若有額外紀錄 `row`, `col`, `block` 陣列，填入數字時要將 `row[x][i]`, `col[y][i]`, `block[x / 3 * 3 + y / 3][i]` 改為 `true`，遞迴返回後，這些值也要恢復成 `false`。

最後，遞迴的終止條件為 `x = 9`，代表所有格子已經填完。

另外要注意 `board` 內存的為 `char`，轉為對應數字時應該要剪去字元的 ASCII 編碼。

# 程式碼

## 不額外紀錄 row, col, block
```cpp
/**
 * Author: justin0u0<mail@justin0u0>
 * Problem: https://leetcode.com/problems/sudoku-solver/
 * Runtime: 28ms
 */

class Solution {
private:
  bool solver(int x, int y, vector<vector<char>>& board) {
    // 遞迴邊界，找到解
    if (x == 9) return true;

    int nextX = y == 8 ? x + 1 : x;
    int nextY = y == 8 ? 0 : y + 1;
    if (board[x][y] == '.') {
      // 嘗試填入 1 ~ 9
      for (int i = 1; i <= 9; i++) {
        bool valid = true;
        char cell = i + '0';
        // 檢查是否可以在 (x, y) 填入數字 i
        for (int j = 0; j < 9; j++) {
          int blockX = (x / 3) * 3 + (j / 3);
          int blockY = (y / 3) * 3 + (j % 3);
          if (board[x][j] == cell || board[j][y] == cell || board[blockX][blockY] == cell) {
            valid = false;
            break;
          }
        }
        if (!valid) continue;
        // 可以填入
        board[x][y] = cell;
        if (solver(nextX, nextY, board)) return true;
        // 恢復盤面
        board[x][y] = '.';
      }
    } else {
      // 原本就有數字，跳過 (x, y)
      return solver(nextX, nextY, board);
    }
    return false;
  }
public:
  void solveSudoku(vector<vector<char>>& board) {
    solver(0, 0, board);
  }
};

```

## 額外紀錄 row, col, block 三個布林值陣列
```cpp
/**
 * Author: justin0u0<mail@justin0u0>
 * Problem: https://leetcode.com/problems/sudoku-solver/
 * Runtime: 8ms
 */

class Solution {
private:
  // 額外紀錄布林陣列 col, row, block
  bool row[9][9], col[9][9], block[9][9];
  // 將額外紀錄的布林陣列值反轉
  inline void toggleState(int x, int y, int i) {
    row[x][i] ^= true;
    col[y][i] ^= true;
    block[x / 3 * 3 + y / 3][i] ^= true;
  }
  bool solver(int x, int y, vector<vector<char>>& board) {
    // 遞迴邊界，找到解
    if (x == 9) return true;

    int nextX = y == 8 ? x + 1 : x;
    int nextY = y == 8 ? 0 : y + 1;
    if (board[x][y] == '.') {
      // 嘗試填入 1 ~ 9
      for (int i = 0; i < 9; i++) {
        if (!row[x][i] && !col[y][i] && !block[x / 3 * 3 + y / 3][i]) {
          // 可以在 (x, y) 填入數字 i
          board[x][y] = i + '1';
          // 將 row, col, block 設成 1
          toggleState(x, y, i);
          if (solver(nextX, nextY, board)) return true;
          // 將 row, col, block 設成 0
          toggleState(x, y, i);
          // 恢復盤面
          board[x][y] = '.';
        }
      }
    } else {
      // 原本就有數字，跳過 (x, y)
      return solver(nextX, nextY, board);
    }
    return false;
  }
public:
  void solveSudoku(vector<vector<char>>& board) {
    // 初始化 row, col, block
    memset(row, false, sizeof row);
    memset(col, false, sizeof col);
    memset(block, false, sizeof block);
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] != '.') {
          int cell = board[i][j] - '1';
          row[i][cell] = true;
          col[j][cell] = true;
          block[i / 3 * 3 + j / 3][cell] = true;
        }
      }
    }
    solver(0, 0, board);
  }
};

```
