---
title: LeetCode 402 - Remove K Digits
tags:
  - LeetCode
  - 堆疊（Stack）
  - 單調棧（Monotone Stack）
categories: LeetCode
date: 2021-03-06 03:46:31
---

# 題目
題目連結：[https://leetcode.com/problems/remove-k-digits/](https://leetcode.com/problems/remove-k-digits/)

給定一個整數，要求移除恰好 k 個數字（字元）使得移除後的整數最小。

# 範例說明

## Example 1:

```
Input: num = "1432219", k = 3
Output: "1219"
Explanation: Remove the three digits 4, 3, and 2 to form the new number 1219 which is the smallest.
```

<!-- More -->

## Example 2:

```
Input: num = "10200", k = 1
Output: "200"
Explanation: Remove the leading 1 and the number is 200. Note that the output must not contain leading zeroes.
```

## Example 3:

```
Input: num = "10", k = 2
Output: "0"
Explanation: Remove all the digits from the number and it is left with nothing which is 0.
```

# 想法

首先，因為要移除恰好 k 個數字，所以不管移除哪一些數字，最後得到的整數長度都是一樣的。

因為題目要求要得到最小的整數，且**不管移除哪一些數字，最後得到的整數長度都是一樣的**，所以最後得到的數字中，越左邊的位（也就是高位數）應該要盡量小。

因此，由左而右的將數字加入到答案整數 `ans`，若**當前要加入的 `digit` 比目前 `ans` 的最低位還要小且還有額度可以刪除數字，則可以不斷刪除 `ans` 中最低位，讓 `digit` 前進到更高的位數使得 `ans` 變得更小**。

其實這題也可以想成做 k 次刪除的動作，若只看一次的刪除，而使得數字要最小，會發現要刪除的數字是由高位數到低位數中，第一次出現遞減的位置來刪除。因為上面提到，高位數的部分應該要盡量小，且出現遞減代表可以把大的數字刪除使得小的數字往高位數前進，因此以同樣的方式進行 k 次的刪除動作也會得到相同的答案。有了這個想法之後，可以確定實作方法是使用一個 `stack` 來維護單調遞增的序列（由高位數到低位數）。

# 實作細節

實作上，可以使用一個 `stack` 來完成，將 `stack` 的底部當成是最高位數，由左而右的遍歷每一個 `digit`，若還有刪除的額度（`k > 0`）且 `stack` 中的最低位（`stack.top()`）比 `digit` 還要小，則不斷的將數字從 `stack` 中移除（`stack.pop()`）。

最後要注意兩件事情：
1. 要確保刪除恰好 k 個數字，因此把 `stack` 中的最後 k 位都刪除。
2. 要確保沒有前導 0，這點可以在把 `stack` 中的數字轉為 `string` 後，再用迴圈刪除前導 0。

不過，比較簡單的方法是使用一個 `string` 來取代上述的 `stack`。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/remove-k-digits/
 * Runtime: 0ms
 */

class Solution {
public:
  string removeKdigits(string num, int k) {
    // 最後的整數，ans[0] 為最高位數，ans[1] 為第二高位數... 以此類推
    string ans = "";
    for (char digit: num) {
      // 若還有刪除的額度且當前的數字比 ans 的最低位數還要小，刪除 ans 中的最低位數
      while (k && !ans.empty() && digit < ans.back()) {
        ans.pop_back();
        k--;
      }
      // 將 digit 加入 ans 中，這裡可以利用判斷使得前導 0 不會被加入
      if (!ans.empty() || digit != '0') ans.push_back(digit);
    }

    // 確保有 k 個數字被刪除
    while (!ans.empty() && k--)
      ans.pop_back();

    // 特例：若數字都刪完了，則回傳 "0"
    return ans.empty() ? "0" : ans;
  }
};

```
