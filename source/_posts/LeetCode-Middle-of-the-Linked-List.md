---
title: LeetCode 876 - Middle of the Linked List
tags:
  - LeetCode
  - 鏈結串列（Linked List）
categories: LeetCode
date: 2021-03-02 00:06:57
---

# 題目
題目連結：[https://leetcode.com/problems/middle-of-the-linked-list/](https://leetcode.com/problems/middle-of-the-linked-list/)

給一個 Linked list，回傳其中間的點。如果有兩個中間的點，則回傳後面的那個。

# 範例說明

## Example 1:

```
Input: [1,2,3,4,5]
Output: Node 3 from this list (Serialization: [3,4,5])
The returned node has value 3.  (The judge's serialization of this node is [3,4,5]).
Note that we returned a ListNode object ans, such that:
ans.val = 3, ans.next.val = 4, ans.next.next.val = 5, and ans.next.next.next = NULL.
```

<!-- More -->

## Example 2:

```
Input: [1,2,3,4,5,6]
Output: Node 4 from this list (Serialization: [4,5,6])
Since the list has two middle nodes with values 3 and 4, we return the second one.
```

# 想法

## 簡單的想法

當然可以先遍歷一遍找出 linked list 的長度，再從頭遍歷長度的一半，回傳找到的點。

## 更優的做法

可以利用兩個指標，兩個指標都從頭開始。

一個一次走一步，稱它為 `slow`；另一個一次走兩步，稱它為 `fast`。這樣 `fast` 到達終點時，`slow` 恰好走了一半的長度，所以回傳 `slow` 即可。

# 實作細節

注意迴圈的條件，因為 `fast` 會一次走兩步，所以有兩個判斷條件： `fast != nullptr && fast->next != nullptr`。

至於 `slow` 因為走的比 `fast` 還要慢，因此不需要判斷。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/middle-of-the-linked-list/
 * Runtime: 0ms
 */

/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     ListNode *next;
 *     ListNode() : val(0), next(nullptr) {}
 *     ListNode(int x) : val(x), next(nullptr) {}
 *     ListNode(int x, ListNode *next) : val(x), next(next) {}
 * };
 */
class Solution {
public:
  ListNode* middleNode(ListNode* head) {
    ListNode* slow = head;
    ListNode* fast = head;

    while (fast != nullptr && fast->next != nullptr) {
      slow = slow->next;
      fast = fast->next->next;
    }
    return (fast == nullptr) ? slow : slow->next;
  }
};

```
