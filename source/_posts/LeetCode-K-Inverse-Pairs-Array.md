---
title: LeetCode 629 - K Inverse Pairs Array
tags:
  - LeetCode
  - 動態規劃（Dynamic Programming, DP）
categories: LeetCode
date: 2022-07-17 20:10:12
---

# 題目
題目連結：[https://leetcode.com/problems/k-inverse-pairs-array/](https://leetcode.com/problems/k-inverse-pairs-array/)

給定 $N$ 以及 $K$，求出包含 $1\sim N$ 的序列中，有多少種恰好有 $K$ 個逆序數對。

答案要對 $10^9 + 7$ 取餘。

# 範例說明

## Example 1:

```
Input: n = 3, k = 0
Output: 1
Explanation: Only the array [1,2,3] which consists of numbers from 1 to 3 has exactly 0 inverse pairs.
```

## Example 2:

```
Input: n = 3, k = 1
Output: 2
Explanation: The array [1,3,2] and [2,1,3] have exactly 1 inverse pair.
```

<!-- More -->

# 想法

假設我們要產生 $1\sim N$ 的任意序列，我們可以從第一個位置開始擺起，假設 $N=3$ 且 $K=2$，則：

1. 若第一個數字是 1，則我們可以知道不管剩下的數字怎麼擺，1 與剩下數字皆不會產生逆序數對。因此若剩下的兩個數字中能產生 $k-0=2-0=2$ 組逆序數對，就滿足我們 $N=3$ 且 $K=2$ 的要求。
2. 若第一個數字是 2，則我們可以知道不管剩下的數字怎麼擺，2 與剩下的數字一定會產生一組逆序數對 $(2,1)$，因此若剩下的兩個數字中能產生 $k-1=2-1=1$ 組逆序數對，就能滿足我們 $N=3$ 且 $K=2$ 的需求。
3. 若第一個數字是 3，則我們可以知道不管剩下的數字怎麼擺，3 與剩下的數字一定會產生兩組逆序數對 $(3,1)$ 與 $(3,2)$，因此若剩下的兩個數字中能產生 $k-2=2-2=0$ 組逆序數對，就能滿足我們 $N=3$ 且 $K=2$ 的需求。

因此我們可以定義 $dp(i,j)$ 為長度為 $i$ 的序列中恰好有 $j$ 個逆序數對的序列數量。則我們知道長度為 $i$ 的序列中，第一個數字有 $i$ 種選擇：

- 若第一個數字選擇第 1 小的數字，第一個數字不會與後面的任何數字產生逆序數對，因此 $dp(i,j)=dp(i-1,j)$。
- 若第一個數字選擇第 2 小的數字，第一個數字恰好與後面的所有數字產生 1 組逆序數對，因此 $dp(i,j)=dp(i-1,j-1)$。
- ...
- 若第一個數字選擇第 $i$ 小的數字（也就是最大的），第一個數字恰好與後面的 $i-1$ 個數字都產生逆序數對，因此 $dp(i,j)=dp(i-1,j-i+1)$。

因此總結來說轉移即為：

$$\red{dp(i,j)=\sum_{k=1}^{i}dp(i-1,j-k+1)}$$

舉例來說：

- $dp(3,0)=dp(2,0)+dp(2,-1)+dp(2,-2)$
- $dp(3,1)=dp(2,1)+dp(2,0)+dp(2,-1)$
- $dp(3,2)=dp(2,2)+dp(2,1)+dp(2,0)$
- $dp(3,3)=dp(2,3)+dp(2,2)+dp(2,1)$
- $dp(3,4)=dp(2,4)+dp(2,3)+dp(2,2)$
- ...

因此我們即可開始實作。

# 實作細節

## 時間複雜度優化

根據上面的轉移式，我們可以很簡單的做出 $O(N\cdot K^2)$ 的 DP，pseudo code 如下（這裡先不考慮邊界問題）：

```cpp
for (int i = 1; i <= N; ++i) {
  for (int j = 1; j <= K; ++j) {
    for (int k = 1; k <= i; ++k) {
      dp[i][j] += dp[i - 1][j - k + 1];
    }
  }
}
```

但很顯然觀察上面列出的轉移，我們可以觀察到每次計算 $dp(i,j)$ 時，並不需要都獨立的用一個 $k=1\sim i$ 的迴圈計算，而可以從 $dp(i,j-1)$ 來轉移：

例如計算 $dp(3,3)=dp(2,3)+dp(2,2)+dp(2,1)$ 時，我們可以透過 $dp(3,2)=dp(2,2)+dp(2,1)+dp(2,0)$，得到 $dp(3,3)=dp(3,2)+dp(2,3)-dp(2,0)$。

也就是說我們可以將轉移式簡化為：

$$\red{dp(i,j)=dp(i,j-1)+dp(i-1,j)-dp(i-1,j-i)}$$

因此中間的 $k$ 迴圈即可被省去，時間複雜度可以降到 $O(N \cdot K)$。

實作時，要注意：

- 邊界 $j-i$ 可能會小於 0，由於我們知道不可能會有負數個逆序數對的情況，因此對於所有 $j \lt 0$，$dp(i,j)=0$。
- 所有的 $dp(i,0)=1$（長度為 $i$ 且沒有逆序數對的序列只有一種）。

最後的答案即為 $dp(N,K)$。

## 空間複雜度優化

我們可以開一個 $(N + 1)\times (K+1)$ 大小的陣列來儲存所有的 DP 狀態，但是透過上述的轉移式可以發現，在計算 $dp(i,j)$ 時，只會用到 $dp(i-1,j)$、$dp(i,j-1)$ 以及 $dp(i-1,j-i)$ 這三個值，因此我們只需要保留兩個 rows 的 DP 狀態就足夠了。

因此筆者在實作時使用 `pre` 陣列代表 $dp(i-1)$；`cur` 陣列代表 $dp(i)$，每次 $i$ 迴圈後交換兩個陣列的指標即可。

如此一來可以把空間複雜度從 $O(N \cdot K)$ 降到 $O(K)$。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/k-inverse-pairs-array/
 * Runtime: 33ms
 * Time Complexity: O(NK)
 * Space Complexity: O(K)
 */

class Solution {
private:
  const int mod = 1e9 + 7;
public:
  int kInversePairs(int n, int k) {
    vector<int>* pre = new vector<int>(k + 1, 0);
    vector<int>* cur = new vector<int>(k + 1, 0);
    (*pre)[0] = 1;
    (*cur)[0] = 1;

    for (int i = 1; i <= n; ++i) {
      swap(pre, cur); // cur->dp[i], pre->dp[i-1]
      for (int j = 1; j <= k; ++j) {
        if (j < i) {
          // j - i < 0, so dp(i-1,j-i) = 0
          (*cur)[j] = ((*cur)[j - 1] + (*pre)[j]) % mod;
        } else {
          (*cur)[j] = (((*cur)[j - 1] + (*pre)[j]) % mod - (*pre)[j - i] + mod) % mod;
        }
      }
    }

    int answer = (*cur)[k];
    delete pre;
    delete cur;

    return answer;
  }
};
```
