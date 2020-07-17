---
title: LeetCode 68 - Text Justification
tags:
  - LeetCode
categories: LeetCode
date: 2020-07-17 09:48:39
---

# 題目
題目連結：[https://leetcode.com/problems/text-justification/](https://leetcode.com/problems/text-justification/)

給很多個字串和一個寬度 `maxWidth`，將字串逐一放入並讓每一行都是 `maxWidth` 寬。

若是最後一行、或是一行內只有一個字串，則靠左排列。其餘則置中排列，平均的分配空白到字串之間。

置中排列時若空白的數量不能平均的被分配，則左邊的空格會比右邊的空格多一個。

# 範例說明

## Example 1:
```
Input:
words = ["This", "is", "an", "example", "of", "text", "justification."]
maxWidth = 16
Output:
[
   "This    is    an",
   "example  of text",
   "justification.  "
]
```

## Example 2:
```
Input:
words = ["What","must","be","acknowledgment","shall","be"]
maxWidth = 16
Output:
[
  "What   must   be",
  "acknowledgment  ",
  "shall be        "
]
Explanation: Note that the last line is "shall be    " instead of "shall     be",
             because the last line must be left-justified instead of fully-justified.
             Note that the second line is also left-justified becase it contains only one word.
```

## Example 3:
```
Input:
words = ["Science","is","what","we","understand","well","enough","to","explain",
         "to","a","computer.","Art","is","everything","else","we","do"]
maxWidth = 20
Output:
[
  "Science  is  what we",
  "understand      well",
  "enough to explain to",
  "a  computer.  Art is",
  "everything  else  we",
  "do                  "
]
```

<!-- More -->

# 想法

實作類型的題目，通常就照著做即可。

首先找出當前這行最多可以放多少字串，並計算出這些字串的長度，不要忘了加上字串中間至少要一個空白。

算出長度後，假設長度和為 `width`，利用 `maxWidth` 減去 `width` 即為還要分配的空白。

去除當前為最後一行、或是這行只放的下一個字串的情況，必須把 `maxWidth - width` 個空白平均分配到字串們的中間。若當前這行有 `M` 個字串，則每一個字串間的間隔可以多分配到 `(maxWidth - width) / (M - 1)` 個空白。另外，當 `(maxWidth - width) / (M - 1)` 不整除，剩下的 `(maxWidth - width) % (M - 1)` 個空白會分配到前 `(maxWidth - width) % (M - 1)` 個字串間隔之中。

而當前為最後一行、或是這行只放的下一個字串的情況，則是靠左排列。只要將字串依序放入，並加入字串間的一個空白。最後再字串後補上空白直到字串長等於 `maxWidth` 即可。

# 實作細節

首先，`i` 為這一行的第一個字串，讓 `width` 等於字串 `i` 的長度，`width` 代表本行的長度和。

接著，`j = i + 1` 開始，若加入一個空白以及字串 `j` 後 `width` 仍小於等於 `maxWidth`，則代表字串 `j` 可以加入。不斷將 `j` 加一，同時計算放入字串 `i ~ j` 的長度和 `width`，最後迴圈結束後 `i ~ j - 1` 即為這行要加入的字串。

若 `j ≠ i + 1` 且 `j ≠ n`，代表這行不只有一個字串且不是最後一行，並且知道這行有 `M = (j - i)` 個字串。所以計算 `spaces = (maxWidth - width) / (j - i - 1)` 和 `extraSpaces = (maxWidth - width) % (j - i - 1)`。接著，首先先將字串 `i` 加入，再遍歷 `k = i + 1 ~ j - 1`，依序加入**相應的空白數量**以及**字串 `k`**，其中空白的數量為 `spaces + ((k - i + 1) < extraSpaces)`，因為如果 `(k - i + 1) < extraSpaces`，代表當前是前 `(maxWidth - width) % M - 1` 個間隔，需要多一個空白。

若 `j = i + 1` 或 `j = n`。首先先加入字串 `i`，再遍歷 `k = i + 1 ~ j - 1`，依序**一個空白**以及**字串 `k`**。最後，補上空白直到長度為 `maxWidth`。

語法部分，可以利用 `string(Char, Number)` 來初始化長度為 `Number` 個 `Char`。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/text-justification/
 * Runtime: 0ms
 */

class Solution {
public:
  vector<string> fullJustify(vector<string>& words, int maxWidth) {
    int n = (int)words.size();
    vector<string> answer;

    for (int i = 0; i < n; ) {
      // 字串 i 為此行的第一個字串，當前長度為字串 i 的長度
      int width = (int)words[i].length();
      // 找最多可以幾個字串加入
      int j = i + 1;
      while (j < n && width + 1 + (int)words[j].length() <= maxWidth) {
        // 加入字串 j 需要一個空白的長度加上字串 j 長度
        width += 1 + (int)words[j].length();
        j++;
      }
      // 字串 i ~ j - 1 都可以加入本行

      // 首先加入字串 i
      string s = words[i];
      if (j != i + 1 && j != n) {
        // 置中排列
        int spaces = (maxWidth - width) / (j - i - 1);
        int extraSpaces = (maxWidth - width) % (j - i - 1);
        for (int k = i + 1; k < j; k++)
          s += string(spaces+ 1 + (k - (i + 1) < extraSpaces), ' ') + words[k];
      } else {
        // 靠左排列，依序加入『一個空白』以及『字串k』
        for (int k = i + 1; k < j; k++) s += " " + words[k];
        s += string(maxWidth - (int)s.length(), ' ');
      }
      // 加入本行答案
      answer.emplace_back(s);
      // i = j 等於下一行的字串開頭
      i = j;
    }
    return answer;
  }
};

```