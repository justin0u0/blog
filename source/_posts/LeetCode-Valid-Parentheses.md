---
title: LeetCode 20 - Valid Parentheses
tags:
  - LeetCode
  - 堆疊（Stack）
categories: LeetCode
date: 2021-03-09 20:10:53
---

# 題目
題目連結：[https://leetcode.com/problems/valid-parentheses/](https://leetcode.com/problems/valid-parentheses/)

給定一個包含只包含 `'('`、`')'`、`'{'`、`'}'`、`'['`、`']'` 的字串，問給定的字串是不是一個合法的括號字串。

# 範例說明

## Example 1:

```
Input: s = "()"
Output: true
```

## Example 2:

```
Input: s = "()[]{}"
Output: true
```

<!-- More -->

## Example 3:

```
Input: s = "(]"
Output: false
```

## Example 4:

```
Input: s = "([)]"
Output: false
```

## Example 5:

```
Input: s = "{[]}"
Output: true
```

# 想法＆實作細節

由左到右，任一個右括號只能與已經出現的左括號匹配，且他們之間不能有其他還未匹配的括號。

且一個右括號如果當下沒有辦法被匹配的話，代表字串是不合法的，因為接下來再也沒有可以匹配這個右括號的選擇了。

由左到右，將未使用的左括號依序推入 `stack` 內，當右括號出現時，其只能匹配 `stack` 的頂端元素。若有 `stack` 的頂端元素與其匹配，則將左括號從 `stack` 中移除。否則字串不合法，回傳 `false`。

最後不要忘記一個合法的括號字串，所有的左括號都應有匹配，因此最後 `stack` 內的元素應該為空。

# 程式碼

```cpp
class Solution {
public:
  bool isValid(string s) {
    stack<char> box;
    for (char ch: s) {
      if (ch == '(' || ch == '{' || ch == '[') {
        // 將未使用的左括號推入 stack 內
        box.push(ch);
      } else {
        // 堆疊為空/堆疊的頂端元素與當前的右括號不匹配，則括號字串不合法
        if (box.empty()
             || (ch == ')' && box.top() != '(')
             || (ch == '}' && box.top() != '{')
             || (ch == ']' && box.top() != '['))
          return false;
        // 左括號被匹配，離開 stack
        box.pop();
      }
    }

    // 合法的括號字串所有的左括號都應該被匹配
    return box.empty();
  }
};
```
