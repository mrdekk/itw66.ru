---
title: |
    Определение размера массива
date: 2011-05-23
authors: [mrdekk]
tags: [с++, размер массива]
categories: [C++]
permalink: /blog/c_plus_plus/479.html
blogcat: C++
excerpt_separator: <!--cut-->
---

Как обычно в С++ определяют размер массива, а очень просто, используют следующую конструкцию:


```cpp
#define count_of( arg ) ( sizeof( arg ) / sizeof( arg[ 0 ] ) )
```

<!--cut-->

Однако она может стать причиной ошибки, если подсунуть туда указатель, не являющийся массивом, например, указатель на функцию. Проблему можно решить следующим образом (взято из исходных кодов проекта Chromium - основы браузера Google Chrome):


```cpp
template <typename T, size_t N>
char (&ArraySizeHelper(T (&array)[N]))[N];
#define arraysize(array) (sizeof(ArraySizeHelper(array)))
```


Проблема решается потому, что массив передается по ссылке, а не по указателю.
