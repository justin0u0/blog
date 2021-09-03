---
title: LeetCode 160 - Intersection of Two Linked Lists
tags:
  - LeetCode
  - 鏈結串列（Linked List）
categories: LeetCode
date: 2021-03-02 00:54:18
---

# 題目
題目連結：[https://leetcode.com/problems/intersection-of-two-linked-lists/](https://leetcode.com/problems/intersection-of-two-linked-lists/)

給定兩個 Linked list，找出其交點。若沒有交點則回傳 `null`。

# 範例說明

## Example 1:

```
Input: intersectVal = 8, listA = [4,1,8,4,5], listB = [5,6,1,8,4,5], skipA = 2, skipB = 3
Output: Reference of the node with value = 8
Input Explanation: The intersected node's value is 8 (note that this must not be 0 if the two lists intersect). From the head of A, it reads as [4,1,8,4,5]. From the head of B, it reads as [5,6,1,8,4,5]. There are 2 nodes before the intersected node in A; There are 3 nodes before the intersected node in B.
``` 
![](/assets/LeetCode-Intersection-of-Two-Linked-Lists/160_example_1_1.png)

<!-- More -->

## Example 2:

```
Input: intersectVal = 2, listA = [1,9,1,2,4], listB = [3,2,4], skipA = 3, skipB = 1
Output: Reference of the node with value = 2
Input Explanation: The intersected node's value is 2 (note that this must not be 0 if the two lists intersect). From the head of A, it reads as [1,9,1,2,4]. From the head of B, it reads as [3,2,4]. There are 3 nodes before the intersected node in A; There are 1 node before the intersected node in B.
``` 
![](/assets/LeetCode-Intersection-of-Two-Linked-Lists/160_example_2.png)

## Example 3:

```
Input: intersectVal = 0, listA = [2,6,4], listB = [1,5], skipA = 3, skipB = 2
Output: null
Input Explanation: From the head of A, it reads as [2,6,4]. From the head of B, it reads as [1,5]. Since the two lists do not intersect, intersectVal must be 0, while skipA and skipB can be arbitrary values.
Explanation: The two lists do not intersect, so return null.
```
![](/assets/LeetCode-Intersection-of-Two-Linked-Lists/160_example_3.png)

# 想法

## 想法一

首先，使用兩個指標，`curA` 從頭開始遍歷第一條 Linked list，`curB` 遍歷第二條。

找出第一條 Linked list 的長 `lenA` 以及第二條 Linked list 的長 `lenB`。

因為兩條 Linked list 若有交點，則交點後的長度皆一樣。所以只要將長度較長的 Linked list 從開頭去掉 `|lenA - lenB|` 個點，使得兩個 Linked list 長度相等，使用兩個指標從兩個 Linked list 的開頭開始，同時一次一步的前進，若有交點則一定會同時走到交點；若沒有交點則同時走到 `null`。

## 想法二

使用第一條 Linked list 串到第二條 Linked list 之後；將第二條 Linked list 串到第一條 Linked list 之後。則兩條 Linked list 會變成等長，根據**想法一**，因為交點後的長度皆相同，所以只要使用兩個指標從兩個 Linked list 的開頭開始，同時一次一步的前進，若有交點則一定會同時走到交點（下圖黑框）：若沒有交點的話則同時走到 `null`。

![](/assets/LeetCode-Intersection-of-Two-Linked-Lists/00.png)

# 實作細節

下面實作為**想法二**。

實作時，可以判斷當 `curA->next != nullptr` 時，`curA = headB`，否則 `curA = curA->next`；`curB` 類似道理。

但是這樣實作會發現當沒有交點時，`curA` 與 `curB` 會無法同時走到 `null` 上（因為 `curA` 在走到 `null` 之前就會因為 `curA->next != nullptr` 而執行 `curA = headB` 走到 `headB` 上了。

可以將判斷條件改為 `curA->next != nullptr` 改為 `curA != nullptr`，`curB` 也類似道理。這樣一來不但符合**想法二**，並且解決了上述的問題。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/intersection-of-two-linked-lists
 * Runtime: 40ms
 */

/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     ListNode *next;
 *     ListNode(int x) : val(x), next(NULL) {}
 * };
 */

class Solution {
public:
  ListNode *getIntersectionNode(ListNode *headA, ListNode *headB) {
    if (headA == nullptr || headB == nullptr)
      return nullptr;

    ListNode* curA = headA;
    ListNode* curB = headB;
    while (curA != curB) {
      curA = (curA != nullptr) ? curA->next : headB;
      curB = (curB != nullptr) ? curB->next : headA;
    }
    return curA;
  }
};

```
