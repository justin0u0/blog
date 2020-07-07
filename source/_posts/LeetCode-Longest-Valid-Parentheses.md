---
title: LeetCode 32 - Longest Valid Parentheses
tags:
  - LeetCode
  - 堆疊（Stack）
categories: LeetCode
date: 2020-07-07 09:37:10
---

# 題目
題目連結：[https://leetcode.com/problems/longest-valid-parentheses/](https://leetcode.com/problems/longest-valid-parentheses/)

給定一個只包含 `'('` 和 `')'` 的字串 `s`，找到最長的合法括號子字串。

# 範例說明

## Example 1:

```
Input: "(()"
Output: 2
Explanation: The longest valid parentheses substring is "()"
```

## Example 2:

```
Input: ")()())"
Output: 4
Explanation: The longest valid parentheses substring is "()()"
```

<!-- More -->

# 想法

首先，要判斷一個字串是否為合法的括號字串。一個合法的括號，若且唯若，字串左括號的數量一定要等於右括號的數量，且由左至右數任一個時刻，左括號的數量都應該大於等於右括號出現的數量。

要判斷字串是否有上述的性質，可以使用一個 `stack`，`stack` 為先進後出（First-in-last-out, FILO）之資料結構。給定之字串由左至右，每次遇到左括號，就將左括號放入 `stack` 之中；反之，遇到右括號時，將 `stack` 之頂端元素拿出。`stack` 之頂端左括號即為當前右括號之匹配。若 `stack` 為空，代表右括號出現的數量比左括號還多，此字串為不合法的字串。若遍歷完字串後 `stack` 內還有剩餘元素，代表左括號數量大於右括號，所以此字串也非合法字串。

有了上述概念，此題目要求最長合法括號子字串。額外紀錄當前合法區間的左邊界 `left`，一開始為 `left = -1` 代表目前整個字串都是合法的。字串左至右，如果遇到左括號，則加入 `stack` 之中。當遇到右括號時：
1. `stack` 為空，代表此右括號沒有任何任何左括號可以匹配，更新 `left` 等於此右括號的索引。
2. `stack` 不為空：將右括號所匹配的左括號從 `stack` 移除。
   1. 如果 `stack` 內還有元素，則右括號到 `stack` 的頂端左括號之間都是合法括號子字串。
   2. 如果 `stack` 為空，則右括號到上述紀錄的合法區間左邊界都是合法括號子字串。

每一個字元都只遍歷一次，若字串長度為 `N`，總時間複雜度為 `O(N)`。
# 實作細節

實作上為了方便，筆者將 `left` 推入 `stack` 之中，如此一來，當遇到右括號時：
1. `stack` 頂端元素**等於** `left`，代表此右括號沒有任何任何左括號可以匹配，更新 `left` 等於右括號的索引，**並將此合法邊界推入 `stack` 之中**。
2. `stack` 頂端元素**不等於** `left`：將右括號所匹配的左括號從 `stack` 移除，右括號到 `stack` 的頂端元素之間都是合法括號子字串。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/longest-valid-parentheses/
 * Runtime: 8ms
 */

class Solution {
public:
  int longestValidParentheses(string s) {
    stack<int> box;
    // 將 left 推入 stack 之中
    box.push(-1);
    int left = -1;
    // 紀錄答案用
    int ans = 0;
    for (int i = 0; i < (int)s.length(); i++) {
      if (s[i] == '(') {
        // 左括號，推入 stack 之中
        box.push(i);
      } else {
        if (box.top() != left) {
          box.pop();
          // 右括號到 stack 之頂端元素都為合法括號子字串
          ans = max(ans, i - box.top());
        } else {
          // 右括號沒有任何左括號能匹配，更新 left 並推入 stack 之中
          box.push(i);
          left = i;
        }
      }
    }
    return ans;
  }
};

```
