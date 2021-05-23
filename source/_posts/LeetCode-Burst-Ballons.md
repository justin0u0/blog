---
title: LeetCode 312 - Burst Ballons
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2021-05-23 21:28:54
mathjax: true
---

# 題目
題目連結：[https://leetcode.com/problems/burst-balloons/](https://leetcode.com/problems/burst-balloons/)

給一長度為 `n` 的序列 `nums`，依照任意順序刪除一個數字，直到所有數字消失。

每次刪除一個數字 `x` 時，假設 `x` 的左邊為 `y`，右邊為 `z`，則花費 `x*y*z` 元；當左邊沒有數字，`y` 視為 1，當右邊沒有數字時，`z` 視為 1。

求出最大花費。

# 範例說明

## Example 1:

```
Input: nums = [3,1,5,8]
Output: 167
Explanation:
nums = [3,1,5,8] --> [3,5,8] --> [3,8] --> [8] --> []
coins =  3*1*5    +   3*5*8   +  1*3*8  + 1*8*1 = 167
```

<!-- More -->

## Example 2:

```
Input: nums = [1,5]
Output: 10
```

# 想法

首先，若想要利用 DP 來紀錄重複的狀態，期望上的狀態應該為 `dp(i,j)` 代表將 `nums[i:j]` 依照任意順序刪除直到所有數字消失的最大花費，並且希望 `dp(i,j)` 的答案可以由一個在 $i\sim j$ 的子區間的 DP 值求得。

可以試圖枚舉在 $i\sim j$ 之間要刪除的數字，但是會導致狀態無法表述當前剩下的數字。例如，初始狀態的 `dp(0,n-1)` 若刪除數字 1 則剩下的數字為 `[3,5,8]`，然而如此一來就沒有一個狀態能夠表述了。因此想辦法改變轉移的方式。觀察範例測資：
```
nums = [3,1,5,8] --> [3,5,8] --> [3,8] --> [8] --> []
coins =  3*1*5    +   3*5*8   +  1*3*8  + 1*8*1 = 167
```
為了避免刪除數字時，可能沒有左邊或右邊的數字的問題，先在整個序列的兩側加上兩個 1，並把題目改為將序列內所有除了兩側的數字刪除的最大花費。
```
nums = [1,3,1,5,8,1] --> [1,3,5,8,1] --> [1,3,8,1] --> [1,8,1] --> [1,1]
coins =    3*1*5      +     3*5*8     +    1*3*8    +   1*8*1   =   167
```
再度觀察，可以發現枚舉一個區間內要刪除的數字會使得狀態無法表述，那麼反過來改為枚舉一個區間內最後一個被刪除的數字，就有點像將上述的順序倒過來。可以發現轉移式即為：
$$dp(i,j)=max\big(dp(i,k), dp(k,j)\big)+nums[i]\times nums[k]\times nums[j]\quad\forall\ k\in[i+1,j-1]$$

也就是，要求出 $i\sim j$ 的最大花費，且不包含 $i,\ j$，若最後一個被刪除的數字為 $k$，則一定會有 $nums[i]\times nums[k] \times nums[j]$ 之花費，並且再加上 $i\sim k$ 與 $k\sim j$ 之花費，分別是 $dp(i,k)$ 與 $dp(k,j)$。

如此一來，狀態有 $O(N^2)$ 中，每一個狀態需要花 $O(N)$ 的時間轉移，因此得到一個總時間複雜度為 $O(N^3)$ 的 DP。

# 實作細節

首先依照上述想法在最左以及最右個加入一個 1。

再來注意 DP 的轉移，區間是由小區間之答案求得，因此要特別注意迴圈順序。一般情況下，都可以使用以下的迴圈順序：

```cpp
for (int i = n - 1; i >= 0; i--) {
  for (int j = i + 1; j < n; j++) {
    // ...
  }
}
```

再來注意邊界條件，由於狀態 $dp(i,j)$ 定為刪除 $i\sim j$ 之間的所有數字，不包含 $i,\ j$，因此 $dp(i,i+1)=0$。因此第二層的 $j$ 迴圈由 $i+2$ 開始。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/burst-balloons/
 * Runtime: 372ms
 * Time Complexity: O(N^3)
 */

class Solution {
public:
  int maxCoins(vector<int>& nums) {
    nums.insert(nums.begin(), 1);
    nums.emplace_back(1);
    int n = nums.size();
    
    int **dp = new int*[n];
    for (int i = n - 1; i >= 0; i--) {
      dp[i] = new int[n + 1];
      dp[i][i + 1] = 0;

      for (int j = i + 2; j < n; j++) {
        for (int k = i + 1; k < j; k++)
          dp[i][j] = max(dp[i][j], dp[i][k] + dp[k][j] + nums[i] * nums[k] * nums[j]);
      }
    }
    return dp[0][n - 1];
  }
};
```
