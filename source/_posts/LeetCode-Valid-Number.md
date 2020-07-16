---
title: LeetCode 65 - Valid Number
tags:
  - LeetCode
categories: LeetCode
date: 2020-07-16 13:32:18
---

# 題目
題目連結：[https://leetcode.com/problems/valid-number/submissions/](https://leetcode.com/problems/valid-number/submissions/)
判斷一個字串是不是一個合法的數字。

# 範例說明

```
"0" => true
" 0.1 " => true
"abc" => false
"1 a" => false
"2e10" => true
" -90e3   " => true
" 1e" => false
"e3" => false
" 6e-1" => true
" 99e2.5 " => false
"53.5e93" => true
" --6 " => false
"-+3" => false
"95a54e53" => false
```

<!-- More -->

# 想法

根據熱心的網友在討論區的提供：
[https://leetcode.com/problems/valid-number/discuss/23741/The-worst-problem-i-have-ever-met-in-this-oj](https://leetcode.com/problems/valid-number/discuss/23741/The-worst-problem-i-have-ever-met-in-this-oj)

```
  test(1, "123", true);
  test(2, " 123 ", true);
  test(3, "0", true);
  test(4, "0123", true);  //Cannot agree
  test(5, "00", true);  //Cannot agree
  test(6, "-10", true);
  test(7, "-0", true);
  test(8, "123.5", true);
  test(9, "123.000000", true);
  test(10, "-500.777", true);
  test(11, "0.0000001", true);
  test(12, "0.00000", true);
  test(13, "0.", true);  //Cannot be more disagree!!!
  test(14, "00.5", true);  //Strongly cannot agree
  test(15, "123e1", true);
  test(16, "1.23e10", true);
  test(17, "0.5e-10", true);
  test(18, "1.0e4.5", false);
  test(19, "0.5e04", true);
  test(20, "12 3", false);
  test(21, "1a3", false);
  test(22, "", false);
  test(23, "     ", false);
  test(24, null, false);
  test(25, ".1", true); //Ok, if you say so
  test(26, ".", false);
  test(27, "2e0", true);  //Really?!
  test(28, "+.8", true);  
  test(29, " 005047e+6", true);  //Damn = =|||
```

我們可以歸納出以下重點：
1. 合法的數字的前後可以有空白，但是中間不可以有空白。
2. `'.'` 只能出現一次，且要在 `'e'` 前面出現。注意：`'.'` 的前面不一定要有數字，例如：`".1" -> true`。
3. `'e'` 只能出現一次，且要在數字之後出現。注意 `'e'` 的後面一定還要有數字。
4. `'+'`、`'-'` 一定要在開頭，或是 `'e'` 的正後面出現。

# 實作細節

一開始先去除頭尾的空白，接著再檢查剩下的字串，可以知道剩下的字串內只能出現 `0 ~ 9`, `'.'`, `'e'`, `'+'`, `'-'`，只要有其他字元出現一律不合法。

接著紀錄 `numberVis` 代表數字有沒有出現過；`eVis` 代表 `'e'` 有沒有出現過；`pointVis` 代表 `.` 有沒有出現過。最後合法的條件是 `numberVis = true`。

注意 `'e'` 出現過後應該要將 `numberVis` 設為 `false`，因為 `'e'` 後面一定要有數字。

# 程式碼

```cpp
/**
 * Author: justin0u0<mail@justin0u0.com>
 * Problem: https://leetcode.com/problems/valid-number/
 * Runtime; 0ms
 */

class Solution {
public:
  bool isNumber(string s) {
    int n = (int)s.length();

    int l = 0, r = n - 1;
    while (l < n && s[l] == ' ') l++;
    while (r >= l && s[r] == ' ') r--;

    bool numberVis = false;
    bool eVis = false;
    bool pointVis = false;
    for (int i = l; i <= r; i++) {
      if (s[i] >= '0' && s[i] <= '9') {
        numberVis = true;
      } else if (s[i] == '.') {
        // '.' 要在 'e' 之前，且 '.' 只能出現一次
        if (eVis || pointVis) return false;
        pointVis = true;
      } else if (s[i] == 'e') {
        // 'e' 要在數字之後，且 'e' 只能出現一次
        if (eVis || !numberVis) return false;
        numberVis = false;
        eVis = true;
      } else if (s[i] == '+' || s[i] == '-') {
        // '+', '-' 只能出現在開頭或是 'e' 的正後面
        if (i != l && s[i - 1] != 'e') return false;
      } else {
        return false;
      }
    }
    return numberVis;
  }
};

```
