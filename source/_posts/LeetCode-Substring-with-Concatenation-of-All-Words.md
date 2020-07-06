---
title: LeetCode 30 - Substring with Concatenation of All Words
date: 2020-07-06 09:08:20
tags:
  - LeetCode
  - 雜湊（Hash table）
  - 滑動窗口（Sliding Window）
categories: LeetCode
---

# 題目
給定一個字串 `s` 和一個 `words` 陣列，`words` 內包含長度一樣的單詞。
找到所有的子字串的開頭索引值，子字串必須是 `words` 中的每一個單詞各出現一次的連接字串。

# 範例說明
## Example 1
```
Input:
  s = "barfoothefoobarman",
  words = ["foo","bar"]
Output: [0,9]
Explanation: Substrings starting at index 0 and 9 are "barfoo" and "foobar" respectively.
The output order does not matter, returning [9,0] is fine too.
```

## Example 2
```
Input:
  s = "wordgoodgoodgoodbestword",
  words = ["word","good","best","word"]
Output: []
```

# 想法
假設 `wl` 為每一個單詞的長度。

要找的子字串必須相連，所以將字串 `s` 分為 `wl` 個集合，分別為：

- `0`, `0 + wl`, `0 + 2 * wl`, `0 + 3 * wl` ...
- `1`, `1 + wl`, `1 + 2 * wl`, `1 + 3 * wl` ...
- ...
- `(wl - 1)`, `(wl - 1) + wl`, `(wl - 1) + 2 * wl`, `(wl - 1) + 3 * wl` ...

例如 `Example 1` 中的 `s = "barfoothefoobarman"`, `words = ["foo", "bar"]`， 則可以分為 `{ "bar", "foo", "the", "foo", "bar", "man" }`, `{ "arf", "oot", "hef", "oob", "arm" }`, `{ "rfo", "oth", "efo", "oba", "rma" }` 三個集合。

答案必定為同一個集合內的連續一段子字串。

在一個集合之中，利用 **Sliding Window** 找尋答案。所謂 **Sliding Window** 是指利用兩個指標標示目前的範圍，或是稱作「窗口」。原本窗口內為空集合，從第一個字串開始，將字串加入窗口（窗口的右側增加，窗口變大），如果當前的字串加入後，窗口內的字串們無法形成答案，就逐次將窗口左側向右（窗口變小），直到窗口內的字串們可以形成答案，或是窗口為空。

要判斷窗口內的答案可否形成答案，也就是要判斷窗口內的子字串們是不是 `words` 的子集合。再者，若窗口內的子字串們恰好等於 `words` 的單詞集合，那窗口最左側的字串之索引值就是一個合法答案。

一樣以 `Example 1` 為例子，一開始窗口為 `[]`。
1. `"bar"` -> 將 `"bar"` 加入窗口，窗口為 `["bar"]`，是 `words` 的子集合。
2. `"foo"` -> 將 `"foo"` 加入窗口，窗口為 `["bar", "foo"]`，恰好等於 `words`，所以窗口左側 `"bar"` 的索引為一組答案。
3. `"the"` -> 將 `"the"` 加入窗口，窗口為 `["bar", "foo", "the"]`，不為 `words` 的子集合，依次將左側窗口向右直到窗口為 `words` 之子集合或是窗口為空，`["bar", "foo", "the"] -> ["foo", "the"]-> ["the"] -> []`。
4. `"foo"` -> 將 `"foo"` 加入窗口，窗口為 `["foo"]`，是 `words` 的子集合。
5. `"bar"` -> 將 `"bar"` 加入窗口，窗口為 `["foo", "bar"]`，恰好等於 `words`，所以窗口左側 `"foo"` 的索引為一組答案。
3. `"man"` -> 將 `"man"` 加入窗口，窗口為 `["foo", "bar", "man"]`，不為 `words` 的子集合，依次將左側窗口向右直到窗口為 `words` 之子集合或是窗口為空，`["foo", "bar", "man"] -> ["bar", "man"]-> ["man"] -> []`。

# 實作細節

為了維護窗口內的子集合，可以使用 **`C++ STL unordered_multiset`**，`unordered_multiset` 為使用 `Hashmap` 實作的集合，可以 `O(1)` 加入、刪除、查找一個值。與 `unordered_set` 不同的是，`unordered_set` 視相同的值為集合內的同一個元素，但 `unordered_multiset` 視同一個值為集合內的不同元素。恰好符合 `words` 內可能有相同單詞的性質。

假設 `dict` 為一 `unordered_multiset`，初始為空。

實作上，先將 `words` 內的單詞都先加入 `dict` 之中，當新的子字串要加入窗口，就必須在 `dict` 中找到此子字串才代表此子字串加入後窗口會是 `words` 的子集合。子字串加入後，從 `dict` 中刪除此子字串，若 `dict` 為空，說明當前窗口恰好等於 `words`，左側窗口索引值紀錄。當左側窗口向右移動時，則把離開窗口的子字串加回 `dict` 之中。

完成後不忘把窗口內的元素都加回 `dict` 之中，讓 `dict` 恢復成原本的樣子，以方便下一組的集合使用。

假設 `N = 字串 s 長度`，每一個子字串只會被加入 Sliding Window 一次，只會從 Sliding Window 中被移除一次，加入、刪除的時間複雜度均是 `O(1)`。所以總時間複雜度為 `O(2N) = O(N)`。

不過 C++ 的 `String.substr` 時間複雜度為 `O(String Length)`，所以總時間複雜度應該為 `O(wl * N)`。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/substring-with-concatenation-of-all-words/
 * Runtime: 52ms
 */

class Solution {
public:
  vector<int> findSubstring(string s, vector<string>& words) {
    // 紀錄答案的索引值用
    vector<int> indices;
    // 排除一定無解的狀況
    int sl = (int)s.length();
    if (!sl || words.empty()) return indices;
    int wl = (int)words[0].length();
    if (sl < wl * (int)words.size() || !wl) return indices;

    // 先將 words 中的單詞加入 dict
    unordered_multiset<string> dict;
    for (auto word: words) dict.insert(word);

    // 共 wl 個集合，分別檢驗
    for (int i = 0; i < wl; i++) {
      // 窗口左側索引值
      int left = i;
      // 逐次將窗口右側向右
      for (int j = i; j + wl <= sl; j += wl) {
        string substring = s.substr(j, wl);
        // 若當前子字串加入後窗口不為 words 之子集合，則逐次將窗口左側向右，直到可以加入或窗口為空
        while (left < j && dict.find(substring) == dict.end()) {
          dict.insert(s.substr(left, wl));
          left += wl;
        }
        auto it = dict.find(substring);
        if (it != dict.end()) {
          // 將當前子字串加入窗口
          dict.erase(it);
          // 若 dict 為空，窗口左側索引為一組合法答案
          if (dict.empty()) indices.emplace_back(left);
        } else {
          // 當前子字串無法加入窗口
          left = j + wl;
        }
      }
      // 將窗口內元素加回 dict 之中，復原 dict 讓下一個集合使用
      while (left + wl <= sl) {
        dict.insert(s.substr(left, wl));
        left += wl;
      }
    }
    return indices;
  }
};

```
