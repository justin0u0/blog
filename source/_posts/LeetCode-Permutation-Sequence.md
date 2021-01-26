---
title: LeetCode 60 - Permutation Sequence
date: 2021-01-26 16:35:04
tags:
  - LeetCode
categories: LeetCode
---

# 題目
題目連結：[https://leetcode.com/problems/permutation-sequence/](https://leetcode.com/problems/permutation-sequence/)

給定 `n`, `k` 兩數字，求 n! 排列中的第 k 項。

# 範例說明

## Example 1:

```
Input: n = 3, k = 3
Output: "213"
```

## Example 2:

```
Input: n = 4, k = 9
Output: "2314"
```

## Example 3:

```
Input: n = 3, k = 1
Output: "123"
```

<!-- More -->

# 想法

把 4! 的排列列出來，如下：
```
1 2 3 4
1 2 4 3
1 3 2 4
1 3 4 2
1 4 2 3
1 4 3 2
2 1 3 4
2 1 4 3
2 3 1 4
2 3 4 1
2 4 1 3
2 4 3 1
3 1 2 4
3 1 4 2
3 2 1 4
3 2 4 1
3 4 1 2
3 4 2 1
4 1 2 3
4 1 3 2
4 2 1 3
4 2 3 1
4 3 1 2
4 3 2 1
```

我們可以輕易的發現，第一個數字是很好求得的，即第 1 ~ 6 個即為 1，第 7 ~ 12 個即為 2，第 13 ~ 18 個即為 3，第 19 ~ 24 個即為 4。

可以發現，在第一個數字決定後，後面三個數字的排列其實跟一般的 3! 排列是一樣的，可以觀察到第一個數字是 4 個六種排列，後三個數字剛好就是 1, 2, 3 的 3! 排列：
```
4 1 2 3
4 1 3 2
4 2 1 3
4 2 3 1
4 3 1 2
4 3 2 1
```

那第一個數字不是 4 的六種排列呢？其實也是一樣的，只是要將數字替換而已，例如第一個數字是 2 的排列：
```
2 1 3 4
2 1 4 3
2 3 1 4
2 3 4 1
2 4 1 3
2 4 3 1
```
其實可以發現後面的數字即是 1, 3, 4 的 3! 排列。

所以要決定第二個數字，我們只需要算出第 k 個排列在第二個數字時變成第幾個排列即可。
可以發現 `k = 1 ~ 6` 的在第二個數字時也是對應到 `k = 1 ~ 6`，
`k = 7 ~ 12` 在第二個數字也是對應到 `k = 1 ~ 6`，
`k = 13 ~ 18` 在第二個數字也是對應到 `k = 1 ~ 6`，
`k = 19 ~ 24` 在第二個數字也是對應到 `k = 1 ~ 6`。
**因此 k 在第二層時即變成 `(k - 1) % 6 + 1`**。

知道方法決定第一個數字以及第二個數字之後，第三、四個數字的決定方法即可以用一樣的想法求出。

# 實作細節

求第一個數字時，第一個數字是 1 個應該有 `(n - 1)!` 個，是 2 的也有 `(n - 1)!` 個...，
因此，第一個數字應該是 `(k - 1) / (n - 1)!` 小的還沒使用過的數字。

求第二個數字時，此時 k 變成了 `(k - 1) % (n - 1) + 1`，
因此，第二個數字應該是 `(k - 1) / (n - 2)!` 小的還沒使用過的數字。

以此類推直到 n 個數字都求完即可。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/permutation-sequence/
 * Runtime: 0ms
 */

class Solution {
public:
  string getPermutation(int n, int k) {
    // arr[i] = 0 代表數字已經使用
    //        ≠ 0 代表數字還沒使用
    // 一開始 arr[i] = i, i ∈ [1, n]
    int* arr = new int[n + 1];
    // fact[i] = i 階乘
    int* fact = new int[n + 1];
    fact[0] = 1;
    for (int i = 1; i <= n; i++) {
      arr[i] = i;
      fact[i] = fact[i - 1] * i;
    }

    string ans = "";
    for (int i = n; i >= 1; i--) {
      // 求出還沒使用過的數字中，第 cnt 小的（cnt 由 1 開始數）
      int cnt = (k - 1) / fact[i - 1];
      for (int j = 1; j <= n; j++) {
        if (arr[j] > 0) {
          --cnt;
        }

        if (cnt < 0) {
          // 找到還沒使用過的數字中第 cnt 小的，即可加入到答案中
          ans += (arr[j] + '0');
          // 更新 k 的值，算出在下一個數字時 k 變成多少
          k = (k - 1) % fact[i - 1] + 1;
          // arr[j] 已經使用
          arr[j] = 0;
          break;
        }
      }
    }
    delete[] arr;
    return ans;
  }
};

```
