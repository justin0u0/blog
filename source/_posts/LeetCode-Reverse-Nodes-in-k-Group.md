---
title: LeetCode 25 - Reverse Nodes in k Group
date: 2020-07-05 15:45:23
tags:
  - LeetCode
  - 鏈結串列（Linked List）
categories: LeetCode
---

# 題目
題目連結：[https://leetcode.com/problems/reverse-nodes-in-k-group/](https://leetcode.com/problems/reverse-nodes-in-k-group/)

給定一個 Linked List（以下簡稱串列），以每 `k` 個節點為一段做反轉。

保證 `k > 0` 且 `k <= 串列長度`，如果剩下的一段長度不足 `k` 則不需要反轉。

# 範例說明
Given this linked list: `1->2->3->4->5`

For `k = 2`, you should return: `2->1->4->3->5`

For `k = 3`, you should return: `3->2->1->4->5`

<!-- More -->

# 想法

把題目拆成兩個遞迴式來想。

首先，如果只要將串列 `head` 的前 `k` 個節點做反轉，

例如：`k = 3`： `1->2->3->...` -> `3->2->1->...`

可以發現除了第一個節點外，每一個節點都要連向上一個節點。所以遞迴函數中，紀錄 `當前節點 head`, `上一個節點 lastNode`，`剩餘數量 k`，如下：

`reverseSingleGroup(head, lastNode, k)`

每次都將 `head->next` 連向 `lastNode`，並且遞迴向下 `reverseSingleGroup(head->next, head, k - 1)`，要注意在修改 `head->next` 之前要先把 `head->next` 記錄下來。

當做到 `k = 1` 時，代表當前 `head` 等於反轉串列後的新的 `head`，所以我們一路將 `head` 返回。

再來，每 `k` 個節點為一段做反轉，我們定義遞迴函數 `reverseKGroup(head, k)`，

可以發現 `reverseKGroup(head, k) = reverseSingleGroup(head, reverseKGroup({ the k + 1 Node }, k), k)`，

也就是 `reverseKGroup(head, k)` 等於將前 `k` 個節點反轉（`reverseSingleGroup(head, ..., k)`），且從第 `k + 1` 個節點繼續做每 `k` 個節點為一點反轉，（`reverseKGroup({ the k + 1 Node}, k)`）。

還有一點要注意，在 `reverseSingleGroup(head, lastNode, k)` 中有提到，每次都應該要將 `head->next = lastNode`，但第一次呼叫的 `lastNode` 上面並沒有特別說明。因為第一次呼叫的 `lastNode` 應該要等於 `reverseKGroup({ the k + 1 Node }, k)` 所返回的新的 `head`。例如：

`1->2->3->4->5->6`, `k = 3`，呼叫 `reverseSingleGroup(1, reverseKGroup(4, 3), 3)`，且 `reverseKGroup(4, 3) = reverseSingleGroup(4, nullptr, 3) = 6->5->4`，所以：`reverseSingleGroup(1, 6->5->4, 3)`，所以節點 `1` 應該要連向節點 `6`。即：`3->2->1->6->5->4`。

最後，若 `reverseKGroup` 時長度已經不足 `k`，則直接返回串列。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/reverse-nodes-in-k-group/
 * Runtime: 16ms
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
private:
  ListNode* reverseSingleGroup(ListNode* head, ListNode* lastNode, int k) {
    // 先將下一個節點紀錄
    ListNode* nextNode = head->next;
    // 將當前節點連向上一個節點
    head->next = lastNode;
    // 遞迴終點：返回新的 head
    if (k == 1) return head;
    // 向下遞迴
    return reverseSingleGroup(nextNode, head, k - 1);
  }
public:
  ListNode* reverseKGroup(ListNode* head, int k) {
    // 找尋第 k 個節點
    ListNode* node = head;
    for (int i = 1; i < k && node != nullptr; i++)
      node = node->next;
    // 若第 k 個節點為 nullptr，則代表長度不足，直接返回串列
    if (node == nullptr)
      return head;
    // 向下遞迴
    return reverseSingleGroup(head, reverseKGroup(node->next, k), k);
  }
};

```
