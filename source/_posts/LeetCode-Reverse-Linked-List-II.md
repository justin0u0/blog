---
title: LeetCode 92 - Reverse Linked List II
tags:
  - LeetCode
  - 鏈結串列（Linked List）
categories: LeetCode
date: 2021-03-02 01:55:08
---

# 題目
題目連結：[https://leetcode.com/problems/reverse-linked-list-ii/](https://leetcode.com/problems/reverse-linked-list-ii/)

給一個 Linked list 以及兩個數字 `left`、`right`，將索引值在 `left~right` 的部分翻轉。

索引值從 1 開始。

# 範例說明

## Example 1:

```
Input: head = [1,2,3,4,5], left = 2, right = 4
Output: [1,4,3,2,5]
```

![](/assets/leetcode-92/rev2ex.jpg)

<!-- More -->

## Example 2:

```
Input: head = [5], left = 1, right = 1
Output: [5]
```

# 想法

假設索引 `left` 上的數字為 `cur`，且索引 `left - 1` 上的數字為 `pre`。

若想要遍歷一次，並且使用 `O(1)` space 完成翻轉，可以想成是做 `right - left` 次的「**將 `cur` 的下一個數字移除並插入到 `pre` 之後**」。

例如 Example 1：
| Step |     Linked list     | `cur` index | `pre` index |
| ---- | ------------------- | ----------- | ----------- |
| 0    | `1->2->3->4->5`     | 2           | 1           |
| 1    | `1->3->2->4->5`     | 3           | 1           |
| 2    | `1->4->3->2->5`     | 4           | 1           |

注意 `cur` 會一直指著同一個數字，在 Example 1 中也就是數字 `2`；`pre` 也會一直指著同一個數字，在 Example 1 中也就是數字 1。

# 實作細節

首先，可以將上述想法分為兩個步驟實作：
1. 找到 `pre` 以及 `cur` 的位置
   從上表可以看出，`cur` 的在 `head` 向後移動 `left - 1` 次的位置；`pre` 在 `cur` 的前一個，也就是 `head` 向後移動 `left - 2` 次的位置。
2. 執行 `right - left` 次「**將 `cur` 的下一個數字移除並插入到 `pre` 之後**」
   **<font color="red">在實作 Linked list 的操作的時候，筆者建議可以把圖畫出來，憑空想像是很容易出錯的！</font>**
   
   一樣以 Example 1 為例子：
   ![](/assets/leetcode-92/00.png)
   1. 首先筆者會先把 `pre`、`cur` 的位置標出來，並且將 `pre->next`、`cur->next` 等指標的位置也標出來。
   2. 再來，執行「**將 `cur` 的下一個數字移除並插入到 `pre` 之後**」這個操作，將要改變的指標畫成曲線。
   3. 最後，將曲線標出如何賦値，例如：
      - <font color="green">數字 1 的下一個數字應該應該要接數字 3，數字 1 是 `pre`，`pre` 的下一個數字也就是 `pre->next` 要接到數字 3，也就是 `cur->next`，因此 `pre->next = cur->next`。</font>
      - <font color="blue">數字 2 的下一個數字要接到數字 4，數字 2 是 `cur`，`cur` 的下一個數字也就是 `cur->next` 要接到數字 4，也就是 `cur->next->next`，因此 `cur->next = cur->next->next`。</font>
      - <font color="red">數字 3 的下一個數字要接到數字 2，數字 3 是 `cur->next`，`cur->next` 的下一個數字也就是 `cur->next->next` 要接到數字 2，也就是 `pre->next`，因此 `cur->next->next = pre->next`。</font>
  
    如果不放心，可以再做一次 Step 1 到 Step 2 的過程，會得到相同的三個步驟。
    ![](/assets/leetcode-92/01.png)

最後，眼尖的讀者可能已經發現了兩個問題：
1. 在第一點中，`pre` 的位置是 `head` 向後移動 `left - 2` 次的位置，可是 `left` 的最小值是 `1`，也就是 `left - 2` 是 `-1`，那 `head` 向後移動 `-1` 步是哪裡？
  為了解決這個問題，可以在整個 Linked list 的前面多加一個點（Dummy Node），也就是在 `head` 的前面再放一個新的點，Dummy Node 雖然實際上不存在，但是可以幫助你的實作更佳簡潔。
  有了 Dummy node 的幫助，那麼 `pre` 的位置即改為 dummy node 往後移動 `left - 1` 不的位置，就一定存在了！當然 `cur` 也要改為 dummy node 往後移動 `left` 步的位置。
2. 在第二點中，三個修改 `1. pre->next = cur->next`、`2. cur->next = cur->next->next` 以及 `3. cur->next->next = pre->next` 是有順序性的。
  例如： `1.` 應該要在 `3.` 之後，因為 `3.` 會需要原本 `pre->next` 的值，可是在 `1.` 的時候會修改到 `pre->next` 的值。
  遇到這種情況，比較簡單的辦法就是**先把需要的值都備份一遍，最後更改時從等號左側值比較右邊的開始修改，等號右側都使用備份的指標**。因為等號右側所用到的值都是備份的，右側一定不會出錯，而等號左側的值從最右邊開始照順序更改，因此也不會有依附關係，如此一來就不會出錯了～
    ```cpp
    ListNode* tempCurNext = cur->next;
    ListNode* tempCurNextNext = cur->next->next;
    ListNode* tempPreNext = pre->next;
    cur->next->next = tempPreNext;
    cur->next = tempCurNextNext;
    pre->next = tempCurNext;
    ```

    當然，也可以稍微思考一下順序，再用盡量少的變數來幫助即可（可以把先後關係畫成一張圖再決定先後順序，如果有環出現的話就至少需要一個暫存變數）。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/reverse-linked-list-ii/submissions/
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
  ListNode* reverseBetween(ListNode* head, int left, int right) {
    ListNode* preHead = new ListNode(0, head); // Dummy node
    ListNode* pre = preHead;
    for (int i = 0; i < left - 1; i++) {
      pre = pre->next;
    }

    ListNode* cur = pre->next;
    for (int i = left; i < right; i++) {
      ListNode* temp = cur->next->next;
      cur->next->next = pre->next;
      pre->next = cur->next;
      cur->next = temp;
    }
    return preHead->next;
  }
};

```
