---
title: LeetCode 76 - Minumum Window Substring
tags:
  - LeetCode
  - 滑動窗口（Sliding Window）
categories: LeetCode
date: 2020-07-19 16:56:18
---

# 題目
題目連結：[https://leetcode.com/problems/minimum-window-substring/](https://leetcode.com/problems/minimum-window-substring/)

給一字串 `S` 以及 `T`，求 `S` 中最短的子字串包含所有 `T` 出現過的字元。

# 範例說明
```
Example:

Input: S = "ADOBECODEBANC", T = "ABC"
Output: "BANC"
```

<!-- More -->

# 想法

利用 **Sliding Window** 找出所有包含 `T` 內所有字元的子字串。

**Sliding Window** 的詳細介紹可以參考 [LeetCode - Substring with Concatenation of All Words](https://blog.justin0u0.com/LeetCode-Substring-with-Concatenation-of-All-Words/)

當窗口內沒有包含 `T` 內的所有字元，可以知道要將窗口變大，也就是將窗口的右側增加。當窗口內包含 `T` 內的所有字元，則不斷將窗口變小，也就是將窗口的左側增加，直到窗口內不包含 `T` 內的所有字元。

如此一來，就可以找到所有可能為的子字串，且若能在 `O(1)` 時間內計算出當前的窗口是否為答案，因為每個字元只會被加入、刪除窗口一次，所以可以知道總時間複雜度為 `O(N)`，`N` 為字串 `S` 之長度。

要在 `O(1)` 的時間內算出窗口內的子字串是否包含 `T` 內的所有字元，可以利用一個計數器來幫助。

利用 `dict[i]` 代表字元 `i` 應該要出現的次數，也就是一開始遍歷 `T` 內的每一個字元 `ch`，並將 `dict[ch]` 加一。接著，開始執行 **Sliding Window**，當一個字元 `S[i]` 加入窗口，將 `dict[S[i]]` 減一；反之，當字元 `S[i]` 離開窗口，將 `dict[S[i]]` 加一。

如此一來，若 `dict` 內的每一個數字皆小於等於 0，代表窗口內已經包含了所有 `T` 內的字元，所以當前的窗口即可以成為答案。

而要快速的計算 `dict` 內的每一個數字是否都小於 0，可以利用一變數 `total` 紀錄當前 `dict` 內大於 0 的數字數量。當 **Sliding Window** 執行時，當一字元 `S[i]` 加入窗口，將 `dict[S[i]]` 減一，若 `dict[S[i]]` 變為 0，則 `total` 減一；反之，當字元 `S[i]` 離開窗口，將 `dict[S[i]]` 加一，若 `dict[S[i]]` 變為 1，則 `total` 加一。

所以當 `total` 等於零，可以知道當前的窗口包含所有 `T` 內的字元，也就是當前的窗口為一組答案。

# 實作細節

為了讓程式碼看起來更為簡潔，筆者利用了較多的 `++`，`--` 運算子。

若讀者還不了解 `x++`、`++x` 之間的差異：
- `x++` 代表將 `x = x + 1`，且回傳還沒加一前的 `x`。
- `++x` 代表將 `x = x + 1`，且回傳加一過後的 `x`。

所以
```cpp
int x = 1, y = 1;
cout << ++x << endl; // Get 2
cout << y++ << endl; // Get 1
```

回歸正題，利用變數 `l` 代表窗口的左邊界，迴圈的變數 `i` 代表窗口的右邊界。當 `s[i]` 加入，則應該要執行：

```cpp
dict[s[i]]--;
if (dict[s[i]] == 0) total--;
```

可以簡化為：

```cpp
if (--dict[s[i]] == 0) total--;
```

而當 `s[i]` 從窗口移出，則應該要執行：

```cpp
dict[s[l]]++;
if (dict[s[l]] == 1) total++;
l++;
```

可以簡化為：

```cpp
if (++dict[s[l++]] == 1) total++;
```

而當 `total` 等於零時，可以知道 `l ~ i` 為一組合法答案。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/minimum-window-substring/
 * Runtime: 16ms
 */

class Solution {
public:
  string minWindow(string s, string t) {
    // dict[i] 代表字元 i 應該要出現幾次
    vector<int> dict(128);
    for (auto ch: t) dict[ch]++;

    // total 代表 dict 內有幾個 > 0 的數字
    int total = 0;
    for (auto value: dict) {
      if (value > 0) total++;
    }

    // l 為窗口左邊界
    int l = 0;
    // answerL 代表答案的左邊界，answerLen 代表答案的長度
    int answerL, answerLen = 0x3f3f3f3f;
    // i 為窗口右邊界
    for (int i = 0; i < (int)s.length(); i++) {
      // 將 s[i] 加入窗口
      if (--dict[s[i]] == 0) total--;
      // 當 total 等於 0，不斷增加窗口左側使窗口變小
      while (!total) {
        // l ~ i 為一組答案，若比當前紀錄的 answerLen 小，則更新答案
        if (i - l + 1 < answerLen) {
          answerL = l;
          answerLen = i - l + 1;
        }
        // 將 s[l] 移出窗口
        if (++dict[s[l++]] == 1) total++;
      }
    }
    // answerLen = 0x3f3f3f3f 代表沒有合法答案
    if (answerLen == 0x3f3f3f3f)
      return "";
    else
      return s.substr(answerL, answerLen);
  }
};

```
