---
title: LeetCode 907 - Sum of Subarray Minimums
tags:
  - LeetCode
  - 堆疊（Stack）
  - 單調棧（Monotone Stack）
categories: LeetCode
date: 2021-03-09 20:38:05
---

# 題目
題目連結：[https://leetcode.com/problems/sum-of-subarray-minimums/](https://leetcode.com/problems/sum-of-subarray-minimums/)

給定一個序列，求出所有子區間的最小值的和。

# 範例說明

## Example 1:

```
Input: arr = [3,1,2,4]
Output: 17
Explanation: 
Subarrays are [3], [1], [2], [4], [3,1], [1,2], [2,4], [3,1,2], [1,2,4], [3,1,2,4]. 
Minimums are 3, 1, 2, 4, 1, 1, 2, 1, 1, 1.
Sum is 17.
```

<!-- More -->

## Example 2:

```
Input: arr = [11,81,94,43,3]
Output: 444
```

# 想法

## 由 O(N^3) 到 O(N^2) 的想法

首先，最簡單的方法為枚舉每個區間，再求出區間最小值並總和。

以 `i` 為左界，以 `j` 為右界：
```cpp
int sum = 0;
for (int i = 0; i < n; i++) {
  for (int j = i; j < n; j++) {
    int minValue = arr[i];
    for (int k = i; k <= j; k++) {
      minValue = min(minValue, arr[i]);
    }
    sum += minValue;
  }
}
return sum;
```

可以容易地發現，對於相同的左界 `i` 來說，每次右界 `j` 都只增加一個數字。因此只要將新增的數字與上一輪計算的 `minValue` 進行更新，就可以不用內層的 `k` 迴圈了。
```cpp
int sum = 0;
for (int i = 0; i < n; i++) {
  int minValue = arr[i]; // minValue 紀錄 i ~ j 的最小值
  for (int j = i; j < n; j++) {
    minValue = min(minValue, arr[j]); // 新增了 arr[j] 這個數字，更新 minValue
    sum += minValue;
  }
}
return sum;
```

如此一來可以得到一個 `O(N^2)` 的算法。

## 由 O(N^2) 到 O(N) 的想法

我們改變迴圈的順序，改為先枚舉右邊界再枚舉左邊界，注意迴圈 `i` 的順序以保證對於同一個右邊界 `j`，`i` 的改變是使區間變大的：
```cpp
int sum = 0;
for (int j = 0; j < n; j++) {
  int minValue = arr[j]; // minValue 紀錄 i ~ j 的最小值
  for (int i = j; i >= 0; i--) {
    minValue = min(minValue, arr[i]); // 新增了 arr[i] 這個數字，更新 minValue
    sum += minValue;
  }
}
return sum;
```

對於每一個右邊界 `j` 所形成的區間，可以觀察出只有由右而左遞減的數字才是有用的，舉例來說，以 `[3, 1, 7, 5]` 的 `5` 為右邊界，所形成的區間如下：

|     Subarray     | Decreasing (<-) | Minimum |  Sum  |
| ---------------- | --------------- | ------- | ----- |
|  `[         5]`  | `[         5]`  |    5    |   5   |
|  `[      7, 5]`  | `[      x, 5]`  |    5    |  10   |
|  `[   1, 7, 5]`  | `[   1, x, 5]`  |    1    |  11   |
|  `[3, 1, 7, 5]`  | `[x, 1, x, 5]`  |    1    |  12   |

可以發現數字 `7` 對於以 `5` 為右邊界的區間來說並沒有貢獻，因為所有以 `5` 為右邊界的區間都會有數字 `5`；
而對於以 `5` 為右邊界，左邊界比數字 `1` 還要小的數字來說，所有的區間都會包含數字 `1`，因此比數字 `1` 大的數字也沒有用。
因而產生了一個由右而左的遞減序列。

有了這個性質，我們可以維護一個由右而左遞減的序列，以知道哪些數字是有用的。知道了哪些數字是有用的外，還需要知道這些數字的用處有多大，以很快的計算出以 `j` 為右界的區間的最小值的和。

可以發現上表中，最後計算出來的 `Sum` 是 `12 = 1 * 2 + 5 * 2`，假設：
- 右區間變大，增加一個數字 `4`：`Decreasing -> [x, 1, x, x, 4]`，`Sum = 1 * 2 + 4 * 3 = 14`
- 右區間變大，增加一個數字 `6`：`Decreasing -> [x, 1, x, x, 4, 6]`，`Sum = 1 * 2 + 4 * 3 + 6 * 1 = 20`。
- 右區間變大，增加一個數字 `0`：`Decreasing -> [x, x, x, x, x, x, 0]`，`Sum = 0 * 7 = 0`。
- 右區間變大，增加一個數字 `8`：`Decreasing -> [x, x, x, x, x, x, 0, 8]`，`Sum = 0 * 7 + 8 * 1`。

可以發現，一個數字的貢獻（下面稱作 `weight`）即是他左邊的 `x` 的數量加一。也等於看成是他左邊所有數的 `weight` 加一。

最後，由左而右，每次將右區間變大（增加一個數字），並且維護由右而左遞減的序列以及一個值 `Sum`。因為每個數字最多只會進入、離開棧一次，所以總時間複雜度為 `O(N)`。

# 實作細節

要實作一個單調遞增/遞減的序列，並且只有**在同一邊增加數字**的操作時，要使用的資料結構是 `stack`，或是可以稱為 **單調棧（Monotone Stack）**。

要利用棧維護一個由右而左遞減的序列，每當右區間變大時，不斷將棧頂部比此元素大的數字都移除即可。

本題除了要紀錄加入棧的元素的值外，還額外需要紀錄每個數字的貢獻 `weight`，以快速的計算區間最小值的和。

最後，在 **由 O(N^2) 到 O(N) 的想法** 的最開始，筆者並沒有特別提到為何要將迴圈的順序改變。改變迴圈的順序主要是想要將區間變成由小到大，也就是當 `j` 變大時，右區間變大，因此區間的大小是增加的。<font color="red">區間大小變大的好處是代表我們已經看過了較小區間的資訊，才有可能可以依照那些資訊來快速的找出答案</font>。

也就是現在的想法 **將右邊界由左而右，維護一個由右而左遞減的序列**，其實也可以改為 **將左邊界由右而左，維護一個由左而右的遞增序列**。兩個方法都是可行的！

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/sum-of-subarray-minimums/
 * Runtime: 76ms
 */

class Solution {
private:
  const int mod = 1e9 + 7;
public:
  int sumSubarrayMins(vector<int>& arr) {
    stack<pair<int, int>> stk; // {值，貢獻}

    int answer = 0; // 答案
    long long sum = 0; // 維護當前 stk 內的總和
    for (int value: arr) {
      int weight = 1;
      while (!stk.empty() && value < stk.top().first) { // 刪除棧頂所有比當前數字大的數字，以維護單調性
        sum -= stk.top().first * stk.top().second; // 維護棧內 sum 的值
        weight += stk.top().second; // 每刪除一個數字，就吸收了他的貢獻
        stk.pop();
      }
      stk.push({value, weight});
      sum += value * weight; // 維護棧內 sum 的值
      answer = (answer + sum % mod) % mod; // sum 為以 value 為右邊界的所有區間的最小值的和
    }
    return answer;
  }
};

```
