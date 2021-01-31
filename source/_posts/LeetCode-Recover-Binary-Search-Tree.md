---
title: LeetCode 99 - Recover Binary Search Tree
date: 2021-01-30 14:23:08
tags:
  - LeetCode
  - 二元搜尋樹（Binary Search Tree）
categories:
  - LeetCode
---

# 題目
題目連結：[https://leetcode.com/problems/recover-binary-search-tree/](https://leetcode.com/problems/recover-binary-search-tree/)

給定一個二元搜尋樹，恰好有兩個點被交換了。

復原出原本的二元搜尋樹。

# 範例說明

## Example 1:

![](https://assets.leetcode.com/uploads/2020/10/28/recover1.jpg)

```
Input: root = [1,3,null,null,2]
Output: [3,1,null,null,2]
Explanation: 3 cannot be a left child of 1 because 3 > 1. Swapping 1 and 3 makes the BST valid.
```

<!-- More -->

## Example 2:

![](https://assets.leetcode.com/uploads/2020/10/28/recover2.jpg)

```
Input: root = [3,1,4,null,null,2]
Output: [2,1,4,null,null,3]
Explanation: 2 cannot be in the right subtree of 3 because 2 < 3. Swapping 2 and 3 makes the BST valid.
```

# 想法

二元搜尋樹的其中一個重要的性質就是其中序走訪（Inorder Traversal）恰好就是排序好的序列。

知道這個性質後，對這個錯誤的搜尋樹使用中序走訪，可以得到一個序列，因為兩個點恰好被交換，因此得到的序列中應該是排序好的，但是恰好有兩個數字被交換了。

題目因此可以變成『給一個排序好的序列，裡面恰好有兩個數字被交換，找出原本的序列』。

考慮一個 1 ~ 9 排序好的序列，有兩種交換數字的可能性：
1. 交換的數字是相鄰的
    Example：交換 3, 4。

    ```
      1 2 3 4 5 6 7 8 9
      1 2 4 3 5 6 7 8 9
    ```
    可以發現，相鄰兩數交換後會產生一個相鄰的[逆序數對](https://zh.wikipedia.org/zh-tw/%E9%80%86%E5%BA%8F%E5%AF%B9){(<font color="red">4</font>, <font color="red">3</font>)}，復原這個逆序數對即可。

2. 交換的數字是不相鄰的
    Example: 交換 3, 7。

    ```
      1 2 3 4 5 6 7 8 9
      1 2 7 4 5 6 3 8 9
    ```

    可以發現，不相鄰兩數交換後會產生兩個相鄰的逆序數對 {(<font color="red">7</font>, 4), (6, <font color="red">3</font>)}，則交換第一個逆序數對中的前面的數，以及第二組逆序數對中後面的數即可。

統整來說，我們可以在中序走訪中尋找相鄰的逆序數對，如果有一組的話，則交換逆序數對的兩數；如果有兩組的話，則交換第一組逆序數對前面的數以及第二組逆序數對後面的數。

# 實作細節

利用 `lastNode` 紀錄上一個點，若 `lastNode == nullptr` 代表當前是根節點，否則當 `lastNode->val > root->val` 時，則逆序數對產生。

利用 `target` 紀錄第一組逆序數對中的第一個數字，利用 `candidate` 紀錄要與 `target` 交換的另一個數。

因此，在遇到第一組逆序數對時，先假設只有一組，也就是 `candidate` 應該等於第一組逆序數對的第二個數字，也就是當前的節點 `root` 的數字，並繼續走訪。當遇到第二組逆序數對時，可以知道 `candidate` 應該要換成第二組逆序數對後面的數，也就是當前的節點 `root`。

最後遍歷完成後交換 `target`, `candidate` 上的值即可。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/recover-binary-search-tree/
 * Runtime: 32ms
 */

/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *     int val;
 *     TreeNode *left;
 *     TreeNode *right;
 *     TreeNode() : val(0), left(nullptr), right(nullptr) {}
 *     TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
 *     TreeNode(int x, TreeNode *left, TreeNode *right) : val(x), left(left), right(right) {}
 * };
 */
class Solution {
public:
  TreeNode* lastNode = nullptr;
  TreeNode* target = nullptr;
  TreeNode* candidate = nullptr;

  void solver(TreeNode* root) {
    if (root == nullptr)
      return;

    solver(root->left);

    if (target == nullptr && (lastNode != nullptr && lastNode->val > root->val)) {
      // target == nullptr，第一組相鄰逆序數對
      target = lastNode;
      candidate = root;
    } else if (target != nullptr && (lastNode != nullptr && lastNode->val > root->val)) {
      // target != nullptr，第二組相鄰逆序數對
      candidate = root;
    }
    lastNode = root;

    solver(root->right);
  }

  void recoverTree(TreeNode* root) {
    solver(root);
    // 遍歷完成，交換 `target`, `candidate` 上的數值
    swap(target->val, candidate->val);
  }
};

```
