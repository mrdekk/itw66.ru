---
title: |
    Маленькие хитрости в C#
date: 2012-03-27
authors: [FiloXSee]
tags: []
categories: [C#]
permalink: /blog/c_sharp/613.html
blogcat: C#
excerpt_separator: <!--cut-->
---

1. Допустим вам необходимо создать строку из нескольких одинаковых символов, число которых определяется во время выполнения. Для этого есть очень простая возможность. Не нужно циклов, достаточно просто вызвать конструктор строки

```
Int32 tabCount = 5;
String res = new String( '\t', tabCount ); // Это строка: "\t\t\t\t\t"
```

